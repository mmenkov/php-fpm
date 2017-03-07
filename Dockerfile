# Build an image of latest stable PHP-FPM
FROM php:7.0-fpm
MAINTAINER Maxim Menkov <m.menkov94@gmail.com>

WORKDIR /srv/

RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng12-dev \
        libbz2-dev \
        libcurl4-openssl-dev \
        libmagickwand-dev \
        optipng \
        pngquant \
        jpegoptim \
        libjpeg-progs \
        wget \
        dbus \
        cron \
    && docker-php-ext-install -j$(nproc) curl iconv mbstring mcrypt mysqli pdo pdo_mysql tokenizer \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && pecl install imagick \
    && docker-php-ext-enable imagick \
    && wget http://download.gna.org/wkhtmltopdf/0.12/0.12.3/wkhtmltox-0.12.3_linux-generic-amd64.tar.xz \
    && tar xf wkhtmltox-0.12.3_linux-generic-amd64.tar.xz \
    && mv wkhtmltox/bin/wkhtmltopdf /usr/local/bin/wkhtmltopdf \
    && chmod +x /usr/local/bin/wkhtmltopdf \
    && rm -rf wkhtmltox wkhtmltox-0.12.3_linux-generic-amd64.tar.xz \
    && apt-get remove -y wget \
    && apt-get autoremove -y

COPY php.ini /usr/local/etc/php/
COPY laravel-worker.target /lib/systemd/system/  

# Create crontab config
ADD crontab /etc/cron.d/crontab
RUN chmod 0644 /etc/cron.d/crontab
RUN touch /var/log/cron.log

RUN ln -s /lib/systemd/system/systemd-logind.service /etc/systemd/system/multi-user.target.wants/systemd-logind.service
RUN mkdir /etc/systemd/system/sockets.target.wants/
RUN ln -s /lib/systemd/system/dbus.socket /etc/systemd/system/sockets.target.wants/dbus.socket
RUN systemctl set-default multi-user.target

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

CMD cron && \
    crontab /etc/cron.d/crontab && \
    /sbin/init && \
    systemctl start laravel-worker.target && \
    php-fpm

#advancecomp \
#pngcrush \
#gifsicle \
#jpegoptim \
#libjpeg-progs \
#libjpeg8-dbg \
#libimage-exiftool-perl \
#imagemagick \
#pngnq \
#tar \
#unzip \
#libpng-dev \
#git \
