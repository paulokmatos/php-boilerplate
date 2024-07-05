FROM php:8.3-fpm-alpine

WORKDIR /var/www/html/project

RUN apk update \
    && apk upgrade \
    && apk add nginx supervisor wget

RUN mkdir -p /usr/share/nginx/www
RUN mkdir -p /run/nginx \
    && mkdir -p /tmp/logDir/

COPY docker/nginx/nginx.conf /etc/nginx/nginx.conf
COPY docker/supervisord/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY docker/php-fpm/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY docker/php-fpm/www.conf /usr/local/etc/php-fpm.d/www.conf


RUN apk add --no-cache --update --virtual .phpize-deps $PHPIZE_DEPS \
    libxml2-dev curl-dev linux-headers oniguruma-dev imap-dev openssl-dev \
    libpng libpng-dev libjpeg libjpeg-turbo libjpeg-turbo-dev libwebp libwebp-dev libxpm libxpm-dev zlib icu-dev libzip-dev

RUN docker-php-ext-configure gd --with-jpeg; \
    docker-php-ext-configure pcntl --enable-pcntl; \
    docker-php-ext-install mysqli pdo pdo_mysql dom curl mbstring imap opcache gd pcntl intl zip


ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

RUN chmod +x /usr/local/bin/install-php-extensions && sync && \
    install-php-extensions http \
    && docker-php-ext-enable http

RUN \
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && HASH="$(wget -q -O - https://composer.github.io/installer.sig)" \
    && php -r "if (hash_file('SHA384', 'composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
    && php composer-setup.php --install-dir=/usr/local/bin --filename=composer

RUN pecl install xdebug && docker-php-ext-enable xdebug

ADD docker/php/20-xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN echo "include_path=/usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini" >> /usr/local/etc/php/php.ini
RUN echo culr.cainfo="/etc/cacert.pem" >> /usr/local/etc/php/conf.d/docker-php-curl-ca-cert.ini

RUN echo memory_limit = -1 >> /usr/local/etc/php/conf.d/docker-php-memlimit.ini;

COPY ./ ./

RUN \
    chown -R www-data:www-data /var/www/html/project && \
    chown -R www-data:www-data /tmp/logDir /var/lib/nginx && \
    find /var/www/html/project -type f -exec chmod 644 {} \; && \
    find /var/www/html/project -type d -exec chmod 755 {} \;


EXPOSE 80

RUN apk del -f $PHPIZE_DEPS libxml2-dev curl-dev linux-headers oniguruma-dev imap-dev openssl-dev libpng-dev libjpeg-turbo-dev libwebp-dev libxpm-dev wget

VOLUME /var/www/html/project

CMD sh -c "/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf"