FROM php:fpm-alpine
LABEL maintainer="mechleg <mechleg@mechleg.com>"

ARG TIMEZONE

RUN apk update \
 && apk add --no-cache $PHPIZE_DEPS icu-dev icu-libs openldap-dev sqlite \
 && docker-php-ext-install -j4 intl exif ldap \
 && echo "date.timezone = ${TIMEZONE}\;" > /usr/local/etc/php/conf.d/timezone.ini

COPY www.conf /usr/local/etc/php-fpm.d/www.conf

VOLUME /var/lib/roundcube
