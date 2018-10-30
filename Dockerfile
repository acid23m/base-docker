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

ARG LANG_VAR=en_US.utf8
#ARG LANG_VAR=ru_RU.utf8
ENV LANG $LANG_VAR

ARG PHP_VERSION=7.2
ENV PHP_V $PHP_VERSION

RUN apt update && \
    apt dist-upgrade -y && \
    apt full-upgrade -y && \
    apt install -ym --no-install-recommends --no-install-suggests \
        software-properties-common \
        wget \
        curl \
        cron \
        git && \
    add-apt-repository -y ppa:ondrej/php && \
    apt update && \
    apt install -ym --no-install-recommends --no-install-suggests \
        "php${PHP_V}" \
        "php${PHP_V}-bz2" \
        "php${PHP_V}-cli" \
        "php${PHP_V}-common" \
        "php${PHP_V}-curl" \
        "php${PHP_V}-fpm" \
        "php${PHP_V}-gd" \
        "php${PHP_V}-intl" \
        "php${PHP_V}-json" \
        "php${PHP_V}-mbstring" \
        "php${PHP_V}-opcache" \
        "php${PHP_V}-sqlite3" \
        "php${PHP_V}-pgsql" \
        "php${PHP_V}-mysql" \
        "php${PHP_V}-xml" \
        "php${PHP_V}-zip" \
        php-imagick \
        php-redis \
        php-ds && \
    mkdir -p "/etc/php/${PHP_V}/fpm/php-fpm.d" /run/php && \
    cp -a "/etc/php/${PHP_V}/fpm/php-fpm.conf" "/etc/php/${PHP_V}/fpm/php-fpm.conf.bak" && \
    echo "\ninclude=/etc/php/${PHP_V}/fpm/php-fpm.d/*.conf\n" >> "/etc/php/${PHP_V}/fpm/php-fpm.conf" && \
    touch "/run/php/php${PHP_V}-fpm.sock" && \
    ln -sf "/usr/sbin/php-fpm${PHP_V}" /usr/sbin/php-fpm && \
    chown www-data:www-data "/run/php/php${PHP_V}-fpm.sock" && \
    chmod 666 "/run/php/php${PHP_V}-fpm.sock" && \
    usermod -a -G www-data root && \
    curl -sS https://getcomposer.org/installer -o composer-setup.php && \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
    rm composer-setup.php && \
    mkdir -p /root/.composer /root/.config/composer && \
    apt clean && \
    apt autoclean -y && \
    apt autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /var/log/php /var/log/fpm && \
    touch /var/log/php/error.log /var/log/fpm/fpm.log && \
    ln -sf /dev/stderr /var/log/php/error.log

CMD "/usr/sbin/php-fpm${PHP_V}"

EXPOSE 9000
