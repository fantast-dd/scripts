#!/bin/bash
# 2016/01/04 pdd
# Zabbix Version 3.2.3

clear

# linux shell color support.
RED="\\033[31m"    # Error
GREEN="\\033[32m"  # Success
YELLOW="\\033[33m" # Warning
BLACK="\\033[0m"

# zabbix
basedir="/usr/local/zabbix"
port="10051"
# nginx
document_root="/storage/www/zabbix"
# php
php_ini="/usr/local/php/etc/php.ini"
# mysql
DBUser="root"
DBPassword="wxgdwxwx"
mysql_base="/usr/local/mysql"

netstat -tpln | grep -q -w $port && { echo -e "${RED}${port} has been occupied${BLACK}\n"; exit 1; }

function php_configure () {
	# adjust php.ini
	sed -i -r 's/(^max_input_time).*/\1 = 300/g' $php_ini
	sed -i -r 's/;(mbstring.func_overload.*)/\1/g' $php_ini
	sed -i -r 's/;(always_populate_raw_post_data.*)/\1/g' $php_ini
    /etc/init.d/php-fpm reload
}

function download () {
    if [ -f /usr/local/src/zabbix-3.2.3.tar.gz ];then
        echo -e "${YELLOW}zabbix file was already downloaded${BLACK}\n"
    else
        wget -c "https://nchc.dl.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/3.2.3/zabbix-3.2.3.tar.gz" -P /usr/local/src
        [ $? != 0 ] && { echo -e "${RED}zabbix download fail !!!${BLACK}\n"; exit 1; }
    fi
}

function zabbix_install () {
    # add user
    grep "zabbix" /etc/passwd >/dev/null || useradd -M -s /sbin/nologin zabbix
    # install dependent packages
    yum install -y net-snmp net-snmp-devel
    cd /usr/local/src
    echo -e "${GREEN}uncompress zabbix file${BLACK}\n"
    tar -zx -f zabbix-3.2.3.tar.gz
    cd zabbix-3.2.3
    ./configure --prefix=$basedir \
     --enable-server \
     --with-mysql=${mysql_base}/bin/mysql_config \
     --with-net-snmp \
     --with-libcurl \
     --with-libxml2 \
     --with-openssl
	[ $? != 0 ] && { echo -e "${RED}zabbix configure fail !!${BLACK}\n"; exit 1; }
    local CPU_NUM=$(grep -c processor /proc/cpuinfo)
    [ "$CPU_NUM" -gt 1 ] && make -j$CPU_NUM || make
    make install
    install -m755 misc/init.d/fedora/core5/zabbix_server /etc/init.d/
    # create zabbix DB and import sql
    ${mysql_base}/bin/mysql -u${DBUser} -p${DBPassword} -e "create database zabbix;"
    for db in schema.sql images.sql data.sql
    do
        ${mysql_base}/bin/mysql -u${DBUser} -p${DBPassword} zabbix < database/mysql/${db}
    done
}

function zabbix_configure () {
	# adjust init.d scripts
    sed -i -r "s,(^ZABBIX_BIN).*,\1=\"${basedir}/sbin/zabbix_server\",g" /etc/init.d/zabbix_server
    # adjust zabbix_server.conf
    sed -i -r "s,(^DBUser).*,\1=${DBUser},g" ${basedir}/etc/zabbix_server.conf
    sed -i -r "s,#( DBPassword),\1=${DBPassword},g" ${basedir}/etc/zabbix_server.conf
    # access zabbix
    mkdir -p $document_root
    cp -rp frontends/php/* $document_root
}

function add_iptables () {
    local iptables_conf=/etc/sysconfig/iptables
    grep -q -w $port $iptables_conf
    if [ ! $? = 0 ];then
        sed -i "/-i lo/a -A INPUT -m state --state NEW -m tcp -p tcp --dport $port -j ACCEPT" $iptables_conf
        /etc/init.d/iptables reload
    fi
}

function self_boot () {
    chkconfig --add zabbix_server
    chkconfig zabbix_server on
}

if [ ! -f ${basedir}/sbin/zabbix_server ];then
    download
    zabbix_install
    zabbix_configure
    php_configure
    echo -e "${GREEN}zabbix install success${BLACK}\n"
else
    echo -e "${YELLOW}zabbix was already installed${BLACK}\n"
fi

add_iptables
chkconfig --list zabbix_server >/dev/null 2>&1 || self_boot
/etc/init.d/zabbix_server start
