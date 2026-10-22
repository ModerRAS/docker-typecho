# Patched PHP (PHP2Shell/CVE-2026-109618) + Apache + Typecho 1.3.x
# Typecho 1.3 requires PHP >= 7.4; upstream recommends PHP 8.2. We use 8.2.35 (patched).
ARG PHP_MINOR=8.2
ARG PHP_PATCH_VERSION=8.2.35
FROM php:${PHP_PATCH_VERSION}-apache-bookworm

ARG PHP_PATCH_VERSION
ARG TYPECHO_VERSION=1.3.0

ENV TYPECHO_VERSION=${TYPECHO_VERSION} \
    APACHE_DOCUMENT_ROOT=/srv/html

RUN set -eux; \
    php -r "if (version_compare(PHP_VERSION, '${PHP_PATCH_VERSION}', '<')) { fwrite(STDERR, 'PHP '.PHP_VERSION.' is older than required ${PHP_PATCH_VERSION}'.PHP_EOL); exit(1); }"; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        libcurl4-openssl-dev \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libonig-dev \
        libpng-dev \
        libsqlite3-dev \
        libzip-dev \
        unzip \
        wget; \
    docker-php-ext-configure gd --with-freetype --with-jpeg; \
    docker-php-ext-install -j"$(nproc)" \
        curl \
        gd \
        mbstring \
        mysqli \
        opcache \
        pdo_mysql \
        pdo_sqlite \
        zip; \
    a2enmod headers remoteip rewrite; \
    apt-get purge -y --auto-remove unzip; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt

RUN set -eux; \
    wget -q "https://github.com/typecho/typecho/archive/refs/tags/v${TYPECHO_VERSION}.tar.gz" -O typecho.tar.gz; \
    tar -xzf typecho.tar.gz; \
    mv "typecho-${TYPECHO_VERSION}" typecho; \
    rm typecho.tar.gz

COPY docker/apache-typecho.conf /etc/apache2/sites-available/000-default.conf
COPY docker/typecho-proxy-bootstrap.php /usr/local/bin/typecho-proxy-bootstrap.php
COPY docker/php-typecho.ini /usr/local/etc/php/conf.d/99-typecho.ini
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /srv/html

EXPOSE 80
VOLUME ["/srv"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["apache2-foreground"]
