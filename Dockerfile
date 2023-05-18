
# Multistage build args
ARG WP_CORE_VERSION

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

WORKDIR $WP_SRC_ROOT

# Install Composer Package Manager (theme needs Timber and Twig)
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
ENV COMPOSER_ALLOW_SUPERUSER=1;
COPY composer.json .
RUN composer install

# WP config
COPY wp-config-docker.php wp-config-docker.php

# Apache config
COPY .htaccess .htaccess

# Switch apache to use wp src
RUN set -eux; \
	find /etc/apache2 -name '*.conf' -type f -exec sed -ri -e "s!/var/www/html!$PWD!g" -e "s!Directory /var/www/!Directory $PWD!g" '{}' +; \
	cp -s wp-config-docker.php wp-config.php

# WP CLI for downloading third-party plugins, among other things
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
&& chmod +x wp-cli.phar \
&& mv wp-cli.phar /usr/local/bin/wp

# Back to site root so wordpress can do the rest of its thing
WORKDIR $WP_SRC_ROOT

# override docker entry point
COPY docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

# start apache
CMD ["apache2-foreground"]
