FROM php:7.1-fpm-jessie

RUN usermod -u 1000 www-data
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -
RUN apt-get update && \
    apt-get install -y \
    git \
    curl \
    zlib1g-dev \
    libpcre3-dev \
    nodejs \
    icu-devtools \
    build-essential \
    libicu-dev

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer
RUN echo "date.timezone = "Europe/London"" >> /usr/local/etc/php/conf.d/php.ini && \
    docker-php-ext-install \
    zip \
    pdo \
    pdo_mysql \
    pcntl \
    intl

ADD package.json composer.json composer.lock /srv/omeka/
ADD application/data/composer-addon-installer /srv/omeka/application/data/composer-addon-installer

RUN mkdir -p /var/www/.npm && chown -R www-data:www-data /var/www /srv/omeka

USER www-data
WORKDIR /srv/omeka
RUN npm install && composer install --no-interaction

USER root
WORKDIR /srv/omeka
ADD docker/config/php/*.ini /usr/local/etc/php/conf.d/
ADD application config modules logs themes *.php gulpfile.js files .htaccess.dist /srv/omeka/
RUN chown -R www-data:www-data application config themes *.php gulpfile.js

USER www-data
RUN ./node_modules/gulp/bin/gulp.js init
EXPOSE 9000
