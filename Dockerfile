ARG PHP_VERSION=8
ARG NGINX_VERSION=1.21
ARG MYSQL_VERSION=latest

FROM php:${PHP_VERSION}-fpm as php-fpm

CMD ["php-fpm"]

FROM nginx:${NGINX_VERSION} as nginx

COPY docker/nginx/default.template.conf /etc/nginx/conf.d/default.conf

WORKDIR /var/www/wtc/public
