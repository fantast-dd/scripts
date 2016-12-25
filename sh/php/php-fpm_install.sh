#!/bin/bash
#2016/12/22 pdd
# PHP Version 5.6.9

clear

# linux shell color support.
RED="\\033[31m"    # Error
GREEN="\\033[32m"  # Success
YELLOW="\\033[33m" # Warning
BLACK="\\033[0m"

ps -C php-fpm >/dev/null && { echo -e "${RED}php-fpm is running${BLACK}\n"; exit 1; }

owner="www"
group="www"
basedir="/usr/local/php"
confdir="/usr/local/php/etc"
phplog="/storage/log/php"

function download () {
    if [ -f /usr/local/src/php-5.6.9.tar.bz2 ];then
        echo -e "${YELLOW}php file was already downloaded${BLACK}\n"
    else
        wget -c http://cn2.php.net/distributions/php-5.6.9.tar.bz2 -P /usr/local/src
        [ $? != 0 ] && { echo -e "${RED}php download fail !!!${BLACK}\n"; exit 1; }
    fi
}

function php_install () {
    # install dependent packages
    yum install -y libxml2 libxml2-devel \
    libcurl libcurl-devel \
    libjpeg-turbo libjpeg-turbo-devel \
    libpng libpng-devel \
    freetype freetype-devel \
    libmcrypt libmcrypt-devel

    cd /usr/local/src
    echo -e "${GREEN}uncompress php file${BLACK}\n"
    tar -jx -f php-5.6.9.tar.bz2
    cd php-5.6.9
    ./configure --prefix="$basedir" \
    --with-config-file-path="$confdir" \
    --with-mysql=mysqlnd \
    --with-mysqli=mysqlnd \
    --with-pdo-mysql=mysqlnd \
    --enable-fpm \
    --with-zlib \
    --enable-calendar \
    --with-curl \
    --with-libxml-dir \
    --enable-ftp \
    --with-gd \
    --with-jpeg-dir \
    --with-png-dir \
    --with-freetype-dir \
    --with-mhash \
    --enable-mbstring \
    --enable-pcntl \
    --enable-sockets \
    --enable-zip \
    --with-openssl \
    --with-mcrypt \
    --enable-soap \
    --with-iconv-dir \
    --enable-bcmath \
    --disable-ipv6
    [ $? != 0 ] && { echo -e "${RED}php configure fail !!${BLACK}\n"; exit 1; }
    local CPU_NUM=$(grep -c processor /proc/cpuinfo)
    [ $CPU_NUM -gt 1 ] && make ZEND_EXTRA_LIBS='-liconv' -j$CPU_NUM || make ZEND_EXTRA_LIBS='-liconv'
    make install
    cp php.ini-production ${confdir}/php.ini
    ln -sf ${basedir}/bin/php /usr/local/bin/php
    install -m755 sapi/fpm/init.d.php-fpm.in /etc/init.d/php-fpm
}

function configure () {
    # adjust php.ini
    sed -i -r 's/(post_max_size).*/\1 = 64M/g' ${confdir}/php.ini
    sed -i -r 's/(upload_max_filesize).*/\1 = 64M/g' ${confdir}/php.ini
    sed -i -r 's/;(date.timezone).*/\1 = Asia\/Shanghai/g' ${confdir}/php.ini
    sed -i -r 's/;(cgi.fix_pathinfo=1)/\1/g' ${confdir}/php.ini
    sed -i -r 's/(max_execution_time).*/\1 = 300/g' ${confdir}/php.ini
    # adjust php-fpm
    cp ${confdir}/php-fpm.conf.default ${confdir}/php-fpm.conf
    sed -i -r 's,;(pid = run/php-fpm.pid),\1,g'   ${confdir}/php-fpm.conf
    sed -i -r "s,;(error_log).*,\1 = ${phplog}/php-fpm.log,g"   ${confdir}/php-fpm.conf
    sed -i -r 's,^(listen).*,\1 = /dev/shm/php-cgi.sock,g'  ${confdir}/php-fpm.conf
    sed -i -r "s,;(listen.owner).*,\1 = $owner,g"  ${confdir}/php-fpm.conf
    sed -i -r "s,;(listen.group).*,\1 = $group,g"  ${confdir}/php-fpm.conf
    sed -i -r 's,;(listen.mode.*),\1,g'  ${confdir}/php-fpm.conf
    sed -i -r 's,^(pm.max_children).*,\1 = 100,g'   ${confdir}/php-fpm.conf
    sed -i -r 's,^(pm.start_servers).*,\1 = 10,g'   ${confdir}/php-fpm.conf
    sed -i -r 's,^(pm.min_spare_servers).*,\1 = 5,g'   ${confdir}/php-fpm.conf
    sed -i -r 's,^(pm.max_spare_servers).*,\1 = 35,g'   ${confdir}/php-fpm.conf
    sed -i -r 's,;(pm.status_path.*),\1,g'  ${confdir}/php-fpm.conf
    sed -i -r 's,;(ping.path.*),\1,g'  ${confdir}/php-fpm.conf
    sed -i -r "s,;(slowlog).*,\1 = ${phplog}/\$pool.log.slow,g" ${confdir}/php-fpm.conf
}

function self_boot () {
    chkconfig --add php-fpm
    chkconfig php-fpm on
}

if [ ! -f ${basedir}/sbin/php-fpm ];then
    download
    php_install
    configure
    echo -e "${GREEN}php install success${BLACK}\n"
else
    echo -e "${YELLOW}php was already installed${BLACK}\n"
fi

chkconfig --list php-fpm >/dev/null 2>&1 || self_boot
/etc/init.d/php-fpm start
