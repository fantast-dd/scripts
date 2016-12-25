#!/bin/bash
# 2016/12/16 pdd
# Nginx Version 1.8.1

clear

# linux shell color support.
RED="\\033[31m"    # Error
GREEN="\\033[32m"  # Success
YELLOW="\\033[33m" # Warning
BLACK="\\033[0m"

port=80

netstat -tpln | grep -q -w "$port" && { echo -e "${RED}${port} has been occupied${BLACK}\n"; exit 1; }

basedir="/usr/local/nginx"
user="www"
group="www"

function download () {
    if [ -f /usr/local/src/nginx-1.8.1.tar.gz ];then
        echo -e "${YELLOW}nginx file was already downloaded${BLACK}\n"
    else
        wget -c http://nginx.org/download/nginx-1.8.1.tar.gz -P /usr/local/src
        [ $? != 0 ] && { echo -e "${RED}nginx download fail !!!${BLACK}\n"; exit 1 ; }
    fi
}

function nginx_install () {
    # install dependent packages
    yum install -y pcre pcre-devel

    echo -e "${GREEN}uncompress nginx file${BLACK}\n"
    cd /usr/local/src
    tar -zx -f nginx-1.8.1.tar.gz
    cd nginx-1.8.1
    ./configure --prefix="$basedir" \
    --user="$user" \
    --group="$group" \
    --with-http_ssl_module \
    --with-http_stub_status_module
    [ $? != 0 ] && { echo -e "${RED}nginx configure fail !!!${BLACK}\n"; exit 1; }
    local CPU_NUM=$(grep -c processor /proc/cpuinfo)
    [ "$CPU_NUM" -gt 1 ] && make -j$CPU_NUM || make
    make install
    ln -sf ${basedir}/sbin/nginx /usr/local/bin/nginx
    [ -d ${basedir}/conf/conf.d ] || mkdir ${basedir}/conf/conf.d
}

function add_iptables () {
	local iptables_conf=/etc/sysconfig/iptables
    grep -q -w "$port" "$iptables_conf"
    if [ ! $? = 0 ];then
        sed -i "/-i lo/a -A INPUT -m state --state NEW -m tcp -p tcp --dport $port -j ACCEPT" "$iptables_conf"
        /etc/init.d/iptables reload
    fi
}

function self_boot () {
	grep -q -w "#nginx" /etc/rc.local
    if [ ! $? = 0 ];then
cat >>/etc/rc.local<<EOF
#nginx
${basedir}/sbin/nginx
EOF
fi
}

if [ ! -f ${basedir}/sbin/nginx ];then
    download
    nginx_install
    echo -e "${GREEN}nginx install success${BLACK}\n"
else
    echo -e "${YELLOW}nginx was already installed${BLACK}\n"
fi
add_iptables
self_boot
${basedir}/sbin/nginx
