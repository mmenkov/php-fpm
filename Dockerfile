# Build an image of latest stable PHP-FPM
FROM php:7.0-fpm
MAINTAINER Maxim Menkov <m.menkov94@gmail.com>

WORKDIR /srv/

RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl


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
        cron \
        openssh-server \
        curl \
        lsb-release \
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

RUN if ! getent passwd kitchen; then                 useradd -d /home/kitchen -m -s /bin/bash kitchen;               fi
RUN echo kitchen:kitchen | chpasswd
RUN echo 'kitchen ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN mkdir -p /etc/sudoers.d
RUN echo 'kitchen ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/kitchen
RUN chmod 0440 /etc/sudoers.d/kitchen
RUN mkdir -p /home/kitchen/.ssh
RUN chown -R kitchen /home/kitchen/.ssh
RUN chmod 0700 /home/kitchen/.ssh
RUN touch /home/kitchen/.ssh/authorized_keys
RUN chown kitchen /home/kitchen/.ssh/authorized_keys
RUN chmod 0600 /home/kitchen/.ssh/authorized_keys
RUN echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCyYq96lg/36J+aG6TL/mPg05XCO2zsp1JR9HRJ5oA/o3ohzsmdowiTMiSxaZH55WXol13zVPO+JRutKi0v/Xmb+OWx9R8BPcM7u4PeseQQ/WKJ6ZzZVHHergBdGwSTSBcB9lK92Yj/XqFTv+3saJjtSb36IHjq9Ew0c/8oWvAGCy8pibZ/KRt87UQzHtvYyZ0TJjWNVKlbhE33b9Tm48Ou7TW84fEIifW0VAKmdGNoNVBHPPeHd173GQEQVkocZkq+YYdXbeb4QWvtVaHnW7m8aOMRuEBoYM6I72+PteMN+C31k/Zej1dOC/W37kwCOIPdGKuQUd4VDYk7YHttPjKt kitchen_docker_key' >> /home/kitchen/.ssh/authorized_keys

RUN apt-get -y install ifupdown dbus pciutils kmod iw wireless-tools

RUN echo "SSHD_OPTS='-o UseDNS=no -o UsePAM=no -o PasswordAuthentication=yes -o UsePrivilegeSeparation=no -o PidFile=/tmp/sshd.pid'" > /etc/default/ssh

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
    

CMD /sbin/init && \
    cron && \
    crontab /etc/cron.d/crontab && \
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
