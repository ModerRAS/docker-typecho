# Based on https://github.com/typecho/Dockerfile (GPL-2.0); PHP base pinned for PHP2Shell (CVE-2026-109618).
ARG PHP_PATCH_VERSION=8.2.35
FROM php:${PHP_PATCH_VERSION}-apache-bookworm

ARG PHP_PATCH_VERSION
ARG URL=https://github.com/typecho/typecho/releases/download/v1.3.0/typecho.zip
ARG CONFIG=""
ARG PHP8_SOCKETS_WORKAROUND="-D_GNU_SOURCE"
ARG PHP_EXTENSION="gd bcmath exif zip mysqli pdo_mysql pdo_pgsql pdo_sqlite opcache"

ENV MEMORY_LIMIT=128m
ENV MAX_POST_BODY=10m
ENV MAX_EXECUTION_TIME=30
ENV TIMEZONE=""

COPY --chown=root:root ./scripts/init.sh /bin/init_typecho
COPY --chown=root:root ./scripts/download.sh /bin/download
COPY --chown=root:root ./scripts/before.sh /bin/before
COPY --chown=root:root ./scripts/after.sh /bin/after
COPY --chown=root:root ./scripts/use.sh /bin/use

RUN set -ex; \
    php -r "if (version_compare(PHP_VERSION, '${PHP_PATCH_VERSION}', '<')) { fwrite(STDERR, 'PHP '.PHP_VERSION.' is older than required ${PHP_PATCH_VERSION}'.PHP_EOL); exit(1); }"; \
    sed -i "s/<shell>/$(use bash sh)/g" /bin/init_typecho; \
    savedAptMark="$(before)"; \
    apt-get update; \
    apt-get install --no-install-recommends -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpq-dev \
        libpng-dev \
        libzip-dev \
        libwebp-dev \
        libsqlite3-dev \
        $PHPIZE_DEPS \
        unzip \
        curl; \
    docker-php-ext-configure gd \
        --with-freetype${CONFIG} \
        --with-jpeg${CONFIG} \
        --with-webp${CONFIG}; \
    docker-php-ext-install -j "$(nproc)" ${PHP_EXTENSION}; \
    CFLAGS="${CFLAGS:-} ${PHP8_SOCKETS_WORKAROUND}" docker-php-ext-install -j "$(nproc)" sockets; \
    download "${URL}"; \
    after "${savedAptMark}"

RUN { \
        echo 'error_reporting = E_ERROR | E_WARNING | E_PARSE | E_CORE_ERROR | E_CORE_WARNING | E_COMPILE_ERROR | E_COMPILE_WARNING | E_RECOVERABLE_ERROR'; \
        echo 'display_errors = Off'; \
        echo 'display_startup_errors = Off'; \
        echo 'log_errors = On'; \
        echo 'error_log = /dev/stderr'; \
        echo 'log_errors_max_len = 1024'; \
        echo 'ignore_repeated_errors = On'; \
        echo 'ignore_repeated_source = Off'; \
        echo 'html_errors = Off'; \
    } > /usr/local/etc/php/conf.d/error-logging.ini

RUN rm -rf /bin/use /bin/download /bin/before /bin/after

VOLUME /app
WORKDIR /app

# --- Dockerfile.apache (upstream) ---
RUN a2enmod rewrite expires remoteip
RUN { \
        echo 'RewriteEngine On'; \
        echo 'RewriteBase /'; \
        echo 'RewriteCond %{REQUEST_FILENAME} !-f'; \
        echo 'RewriteCond %{REQUEST_FILENAME} !-d'; \
        echo 'RewriteRule ^(.*)$ /index.php/$1 [L]'; \
    } > /app/.htaccess

RUN sed -ri -e 's!/var/www/html!/app!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!/app!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

EXPOSE 80

CMD ["init_typecho", "apache"]
