FROM ubuntu:18.04

RUN apt update && \
    apt upgrade -y && \
    apt dist-upgrade -y && \
    apt install -ym apt-utils tzdata locales && \
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 && \
    localedef -i ru_RU -c -f UTF-8 -A /usr/share/locale/locale.alias ru_RU.UTF-8 && \
    apt clean && \
    apt autoclean -y && \
    apt autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV LANG en_US.utf8
#ENV LANG ru_RU.utf8

RUN apt update && \
    apt dist-upgrade -y && \
    apt full-upgrade -y && \
    apt install -ym --no-install-recommends \
        software-properties-common \
        wget \
        curl \
        cron \
        git && \
    add-apt-repository ppa:ondrej/php && \
    apt update && \
    apt install -ym --no-install-recommends \
        php7.2 \
        php7.2-bz2 \
        php7.2-cli \
        php7.2-common \
        php7.2-curl \
        php7.2-fpm \
        php7.2-gd \
        php7.2-intl \
        php7.2-json \
        php7.2-mbstring \
        php7.2-opcache \
        php7.2-sqlite3 \
        php7.2-pgsql \
        php7.2-mysql \
        php7.2-xml \
        php7.2-zip \
        php-imagick \
        php-ds && \
    mkdir -p /etc/php/7.2/fpm/php-fpm.d /run/php && \
    cp -a /etc/php/7.2/fpm/php-fpm.conf /etc/php/7.2/fpm/php-fpm.conf.bak && \
    echo "\ninclude=/etc/php/7.2/fpm/php-fpm.d/*.conf\n" >> /etc/php/7.2/fpm/php-fpm.conf && \
    touch /run/php/php7.2-fpm.sock && \
    chown www-data:www-data /run/php/php7.2-fpm.sock && \
    chmod 666 /run/php/php7.2-fpm.sock && \
    usermod -a -G www-data root && \
    curl -sS https://getcomposer.org/installer -o composer-setup.php && \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
    rm composer-setup.php && \
    mkdir -p /root/.composer /root/.config/composer && \
    apt clean && \
    apt autoclean -y && \
    apt autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

CMD ["/usr/sbin/php-fpm7.2"]

EXPOSE 9000
