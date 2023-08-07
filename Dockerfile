# Multistage build args
ARG WP_CORE_VERSION
ARG FORMINATOR_VERSION
ARG FORMINATOR_ZIP_FILE="forminator-pro-${FORMINATOR_VERSION}.zip"
ARG REDIRECTION_VERSION
ARG REDIRECTION_ZIP_FILE="redirection-${REDIRECTION_VERSION}.zip"
ARG OPENID_CONNECT_GENERIC_VERSION
ARG OPENID_CONNECT_GENERIC_DIR="openid-connect-generic-${OPENID_CONNECT_GENERIC_VERSION}"
ARG OPENID_CONNECT_GENERIC_ZIP_FILE="${OPENID_CONNECT_GENERIC_DIR}.zip"
ARG WPMU_DEV_DASHBOARD_VERSION
ARG WPMU_DEV_DASHBOARD_ZIP_FILE="wpmu-dev-dashboard-${WPMU_DEV_DASHBOARD_VERSION}.zip"

# Download plugins from Google Cloud Storage
FROM google/cloud-sdk:alpine as gcloud
RUN mkdir -p /cache
WORKDIR /cache
ARG GC_BUCKET_PLUGINS
ARG FORMINATOR_ZIP_FILE
ARG REDIRECTION_ZIP_FILE
ARG OPENID_CONNECT_GENERIC_ZIP_FILE
ARG WPMU_DEV_DASHBOARD_ZIP_FILE

COPY deploy/reader-key.json reader-key.json
RUN gcloud auth activate-service-account --key-file=./reader-key.json \
&& gsutil cp gs://${GC_BUCKET_PLUGINS}/forminator-pro/${FORMINATOR_ZIP_FILE} . \
&& gsutil cp gs://${GC_BUCKET_PLUGINS}/openid-connect-generic/${OPENID_CONNECT_GENERIC_ZIP_FILE} . \
&& gsutil cp gs://${GC_BUCKET_PLUGINS}/redirection/${REDIRECTION_ZIP_FILE} . \
&& gsutil cp gs://${GC_BUCKET_PLUGINS}/wpmudev-updates/${WPMU_DEV_DASHBOARD_ZIP_FILE} .
RUN rm reader-key.json

# Main build
FROM wordpress:${WP_CORE_VERSION} as wordpress

# ARGS
ARG APP_VERSION
ENV APP_VERSION ${APP_VERSION}
ARG BUILD_NUM
ENV BUILD_NUM ${BUILD_NUM}
ARG BUILD_TIME
ENV BUILD_TIME ${BUILD_TIME}
ARG WP_SRC_ROOT
ENV WP_SRC_ROOT=${WP_SRC_ROOT}
ARG WP_LOG_ROOT=/var/log/wordpress
ENV WP_LOG_ROOT=${WP_LOG_ROOT}
ARG WP_THEME_DIR
ARG WP_PLUGIN_DIR
ARG THEME_TAG

# Plugins
ARG FORMINATOR_RT_ADDON_REPO_URL
ARG FORMINATOR_ZIP_FILE
ARG OPENID_CONNECT_GENERIC_DIR
ARG OPENID_CONNECT_GENERIC_ZIP_FILE
ARG REDIRECTION_ZIP_FILE
ARG WPMU_DEV_DASHBOARD_ZIP_FILE

WORKDIR $WP_SRC_ROOT

# Install Composer Package Manager (theme needs Timber and Twig)
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
ENV COMPOSER_ALLOW_SUPERUSER=1;
COPY composer.json .
RUN composer install

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

# WP CLI - a nice thing to have
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
&& chmod +x wp-cli.phar \
&& mv wp-cli.phar /usr/local/bin/wp

# get our prebuilt theme
WORKDIR $WP_THEME_DIR
ARG THEME_FILE="ucdlib-theme-wp-${THEME_TAG}.tar.gz"
RUN curl -OL https://github.com/UCDavisLibrary/ucdlib-theme-wp/releases/download/${THEME_TAG}/${THEME_FILE} \
&& tar -xzf ${THEME_FILE} \
&& rm ${THEME_FILE}

# remove default plugins and insert the plugins we downloaded from GCS
WORKDIR $WP_PLUGIN_DIR
RUN rm -rf */ && rm -f hello.php
COPY src/plugins .
COPY --from=gcloud /cache/${FORMINATOR_ZIP_FILE} .
COPY --from=gcloud /cache/${OPENID_CONNECT_GENERIC_ZIP_FILE} .
COPY --from=gcloud /cache/${REDIRECTION_ZIP_FILE} .
COPY --from=gcloud /cache/${WPMU_DEV_DASHBOARD_ZIP_FILE} .
RUN unzip ${FORMINATOR_ZIP_FILE} && rm ${FORMINATOR_ZIP_FILE} \
&& unzip ${OPENID_CONNECT_GENERIC_ZIP_FILE} && rm ${OPENID_CONNECT_GENERIC_ZIP_FILE} \
&& unzip ${REDIRECTION_ZIP_FILE} && rm ${REDIRECTION_ZIP_FILE} \
&& unzip ${WPMU_DEV_DASHBOARD_ZIP_FILE} && rm ${WPMU_DEV_DASHBOARD_ZIP_FILE}
RUN mv $OPENID_CONNECT_GENERIC_DIR openid-connect-generic

# Get our rt forminator addon plugin
RUN git clone ${FORMINATOR_RT_ADDON_REPO_URL}.git forminator-addon-rt \
&& cd forminator-addon-rt \
&& git checkout ${FORMINATOR_RT_ADDON_TAG}

# Back to site root so wordpress can do the rest of its thing
WORKDIR $WP_SRC_ROOT

# override docker entry point
COPY docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

# start apache
CMD ["apache2-foreground"]
