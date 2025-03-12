# Multistage build args
ARG WP_CORE_VERSION="6.6.1"
ARG THEME_TAG="v3.8.2"
ARG FORMINATOR_ZIP_FILE="forminator-pro-1.34.1.zip"
ARG REDIRECTION_ZIP_FILE="redirection-5.5.0.zip"
ARG SMTP_MAILER_ZIP_FILE="smtp-mailer-1.1.15.zip"
ARG OPENID_CONNECT_GENERIC_DIR="openid-connect-generic-3.10.0"
ARG OPENID_CONNECT_GENERIC_ZIP_FILE="${OPENID_CONNECT_GENERIC_DIR}.zip"
ARG WPMU_DEV_DASHBOARD_ZIP_FILE="wpmu-dev-dashboard-4.11.26.zip"

# Download plugins from Google Cloud Storage
FROM google/cloud-sdk:alpine as gcloud
RUN mkdir -p /cache
WORKDIR /cache
ARG GC_BUCKET_PLUGINS="wordpress-general/plugins"
ARG FORMINATOR_ZIP_FILE
ARG REDIRECTION_ZIP_FILE
ARG OPENID_CONNECT_GENERIC_ZIP_FILE
ARG WPMU_DEV_DASHBOARD_ZIP_FILE
ARG SMTP_MAILER_ZIP_FILE

RUN --mount=type=secret,id=google_key gcloud auth activate-service-account --key-file=/run/secrets/google_key
RUN gsutil cp gs://${GC_BUCKET_PLUGINS}/forminator-pro/${FORMINATOR_ZIP_FILE} . \
&& gsutil cp gs://${GC_BUCKET_PLUGINS}/openid-connect-generic/${OPENID_CONNECT_GENERIC_ZIP_FILE} . \
&& gsutil cp gs://${GC_BUCKET_PLUGINS}/redirection/${REDIRECTION_ZIP_FILE} . \
&& gsutil cp gs://${GC_BUCKET_PLUGINS}/smtp-mailer/${SMTP_MAILER_ZIP_FILE} . \
&& gsutil cp gs://${GC_BUCKET_PLUGINS}/wpmudev-updates/${WPMU_DEV_DASHBOARD_ZIP_FILE} .

# Main build
FROM wordpress:${WP_CORE_VERSION} as wordpress

# WP Filesystem paths
ARG WP_LOG_ROOT
ARG WP_SRC_ROOT=/usr/src/wordpress
ARG WP_CONTENT_DIR=$WP_SRC_ROOT/wp-content
ARG WP_THEME_DIR=$WP_CONTENT_DIR/themes
ARG WP_PLUGIN_DIR=$WP_CONTENT_DIR/plugins
ARG WP_UPLOADS_DIR=$WP_CONTENT_DIR/uploads

# WP Filesystem env vars
ENV WP_LOG_ROOT=${WP_LOG_ROOT}
ENV WP_SRC_ROOT=${WP_SRC_ROOT}
ENV WP_UPLOADS_DIR=${WP_UPLOADS_DIR}

WORKDIR $WP_SRC_ROOT

# Install Composer Package Manager (theme needs Timber and Twig)
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install debian packages
RUN apt-get update && apt-get install -y unzip git vim

# WP config
COPY wp-config-docker.php wp-config-docker.php

# Apache config
COPY .htaccess .htaccess

# Switch apache to use wp src
RUN set -eux; \
	find /etc/apache2 -name '*.conf' -type f -exec sed -ri -e "s!/var/www/html!$PWD!g" -e "s!Directory /var/www/!Directory $PWD!g" '{}' +; \
	cp -s wp-config-docker.php wp-config.php

# WP CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
&& chmod +x wp-cli.phar \
&& mv wp-cli.phar /usr/local/bin/wp

# Install composer dependencies for theme and plugins
ENV COMPOSER_ALLOW_SUPERUSER=1;
COPY composer.json .
RUN composer install

# get our prebuilt theme
WORKDIR $WP_THEME_DIR
RUN rm -rf */
ARG THEME_TAG
ARG THEME_FILE="ucdlib-theme-wp-${THEME_TAG}.tar.gz"
RUN curl -OL https://github.com/UCDavisLibrary/ucdlib-theme-wp/releases/download/${THEME_TAG}/${THEME_FILE} \
&& tar -xzf ${THEME_FILE} \
&& rm ${THEME_FILE}

# remove default plugins and insert the plugins we downloaded from GCS
ARG FORMINATOR_RT_ADDON_REPO_URL
ARG FORMINATOR_ZIP_FILE
ARG OPENID_CONNECT_GENERIC_DIR
ARG OPENID_CONNECT_GENERIC_ZIP_FILE
ARG REDIRECTION_ZIP_FILE
ARG SMTP_MAILER_ZIP_FILE
ARG WPMU_DEV_DASHBOARD_ZIP_FILE
WORKDIR $WP_PLUGIN_DIR
RUN rm -rf */ && rm -f hello.php
COPY src/plugins .
COPY --from=gcloud /cache/${FORMINATOR_ZIP_FILE} .
COPY --from=gcloud /cache/${OPENID_CONNECT_GENERIC_ZIP_FILE} .
COPY --from=gcloud /cache/${REDIRECTION_ZIP_FILE} .
COPY --from=gcloud /cache/${SMTP_MAILER_ZIP_FILE} .
COPY --from=gcloud /cache/${WPMU_DEV_DASHBOARD_ZIP_FILE} .
RUN unzip ${FORMINATOR_ZIP_FILE} && rm ${FORMINATOR_ZIP_FILE} \
&& unzip ${OPENID_CONNECT_GENERIC_ZIP_FILE} && rm ${OPENID_CONNECT_GENERIC_ZIP_FILE} \
&& unzip ${REDIRECTION_ZIP_FILE} && rm ${REDIRECTION_ZIP_FILE} \
&& unzip ${SMTP_MAILER_ZIP_FILE} && rm ${SMTP_MAILER_ZIP_FILE} \
&& unzip ${WPMU_DEV_DASHBOARD_ZIP_FILE} && rm ${WPMU_DEV_DASHBOARD_ZIP_FILE}
RUN mv $OPENID_CONNECT_GENERIC_DIR openid-connect-generic

# Get our rt forminator addon plugin
RUN git -c advice.detachedHead=false \
	clone https://github.com/UCDavisLibrary/forminator-addon-rt.git \
	--branch v2.0.0 --single-branch --depth 1

# Back to site root so wordpress can do the rest of its thing
WORKDIR $WP_SRC_ROOT

# override docker entry point
COPY docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

# start apache
CMD ["apache2-foreground"]
