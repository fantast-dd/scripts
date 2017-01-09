#!/bin/bash
# 2017/1/5
# Version MySQL 5.6.35
# 二进制安装MYSQL

# linux shell color support.
RED="\\033[31m"
GREEN="\\033[32m"
YELLOW="\\033[33m"
BLACK="\\033[0m"

port="3306"
basedir="/usr/local/mysql"
datadir="/storage/db"
socket="/tmp/mysql.sock"
user="mysql"
password="wxgdwxwx"

netstat -tupln | grep -w -q $port && { echo -e "${RED}${port} has been occupied${BLACK}\n"; exit 1; }

function download () {
    if [ -f /usr/local/src/mysql-5.6.35-linux-glibc2.5-x86_64.tar.gz ];then
        echo -e "${YELLOW}mysql file was already downloaded${BLACK}\n";
    else
        wget -c "http://dev.mysql.com/get/Downloads/MySQL-5.6/mysql-5.6.35-linux-glibc2.5-x86_64.tar.gz" -P /usr/local/src
        [ $? != 0 ] && { echo -e "${RED}mysql download fail !!!${BLACK}\n"; exit 1 ; }
    fi
}

function mysql_install () {
    # prerequisite
    grep -q $user /etc/passwd || useradd -M -s /sbin/nologin $user
    [ -n "$password" ] || { echo -e "${RED}password is empty${BLACK}\n"; exit 1; }
    rpm -q --quiet compat-libstdc++-33.x86_64 || yum -y install compat-libstdc++-33.x86_64
    rpm -q --quiet libaio.x86_64 || yum -y install libaio.x86_64

    echo -e "${GREEN}uncompress mysql file${BLACK}\n"
    cd /usr/local/src
    tar -xz -f mysql-5.6.35-linux-glibc2.5-x86_64.tar.gz
    cp -rf mysql-5.6.35-linux-glibc2.5-x86_64 $basedir
    chown -R $user:$user $basedir
    install -m755 ${basedir}/support-files/mysql.server /etc/init.d/mysqld
}

function mysql_configure () {
cat >/etc/my.cnf<<EOF
[client]
port=3306
socket=$socket

[mysqld]
basedir=$basedir
datadir=$datadir
socket=$socket
user=$user
character-set-server=utf8
collation-server=utf8_unicode_ci
EOF
}

# initialize db
function init_db () {
    [ -d $datadir ] || { mkdir -p $datadir; chown -R $user:$user $datadir; }
    ${basedir}/scripts/mysql_install_db --user=$user \
    --basedir=$basedir \
    --datadir=$datadir
    [ $? != 0 ] && { echo -e "${RED}mysql init_db fail !!!${BLACK}\n"; exit 1; }
    ln -sf ${basedir}/bin/mysql /usr/local/bin/mysql
}

function self_boot () {
    chkconfig --add mysqld
    chkconfig mysqld on
}

function add_iptables() {
    local iptables_conf=/etc/sysconfig/iptables
    grep -w -q $port $iptables_conf
    if [ $? != 0 ];then
        sed -i "/-i lo/a -A INPUT -m state --state NEW -m tcp -p tcp --dport $port -j ACCEPT" $iptables_conf
        /etc/init.d/iptables reload
    fi
}

# 安全设置
function security () {
${basedir}/bin/mysql_secure_installation<<EOF

Y
$password
$password
Y  
Y  
Y  
Y
EOF
}

if [ ! -f ${basedir}/bin/mysql ];then
    download
    mysql_install
    mysql_configure
    init_db  # 数据库初始化的时候要读取my.cnf里面的参数
    /etc/init.d/mysqld start
    security
    echo -e "${GREEN}mysql install success${BLACK}\n"
else
    echo -e "${YELLOW}mysql was already installed ${BLACK}\n"
    /etc/init.d/mysqld start
fi
add_iptables
chkconfig --list mysqld >/dev/null 2>&1 || self_boot
