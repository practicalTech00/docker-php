ARG PHP_VERSION=8
ARG NGINX_VERSION=1.21
ARG MYSQL_VERSION=latest

FROM php:${PHP_VERSION}-fpm as php-fpm

RUN pecl install pcov && docker-php-ext-enable pcov
RUN pecl install xdebug-3.1.2
RUN docker-php-ext-enable xdebug

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        git \
        libzip-dev \
        libssl-dev \
        libxml2-dev \
        memcached \
        telnet \
        wkhtmltopdf \
        binutils \
        unzip \
        python \
        zip \
        procps \
        sudo \
        vim \
    ;

ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

RUN chmod +x /usr/local/bin/install-php-extensions && sync && \
    install-php-extensions bcmath calendar \
    gd http intl memcached \
    sockets ssh2 zip \
    ;

RUN docker-php-ext-install -j$(nproc) pdo pdo_mysql phar simplexml opcache \
    ;

RUN echo "date.timezone = "Europe/Bucharest"" >> /usr/local/etc/php/php.ini
RUN sudo echo "Europe/Bucharest" > /etc/timezone
RUN sudo rm -f /etc/localtime
RUN sudo ln -s /usr/share/zoneinfo/Europe/Bucharest /etc/localtime

RUN useradd -m -d /home/jenkins/ -s /bin/bash -r -u 1032 -g www-data jenkins
RUN usermod -aG sudo jenkins
RUN chown -R jenkins:www-data /var

COPY docker/php/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint

USER jenkins

WORKDIR /var/www/wtc

ENTRYPOINT ["docker-entrypoint"]

CMD ["php-fpm"]

FROM percona/percona-server:${MYSQL_VERSION} as mysql

CMD ["mysqld", "--character-set-server=utf8", "--collation-server=utf8_unicode_ci", "--default_authentication_plugin=mysql_native_password",  "--sql_mode=ALLOW_INVALID_DATES"]

FROM nginx:${NGINX_VERSION} as nginx

COPY docker/nginx/default.template.conf /etc/nginx/conf.d/default.conf

WORKDIR /var/www/wtc/public
