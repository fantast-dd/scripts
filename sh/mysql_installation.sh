#!/bin/bash
# date 2016/8/22 pdd
# 二进制安装

basedir=/storage/server/mysql
datadir=/storage/data/mysql
socket=/tmp/mysql.sock
user=mysql
passwd=hogesoft

# 安装包 添加用户名
grep -q $user /etc/passwd || useradd -M -s /sbin/nologin $user
yum -y install compat-libstdc++-33.x86_64 libaio.x86_64

# 安装
function Install () {
    cd /usr/local/src
    tar -xz -f mysql-5.5.43-linux2.6-x86_64.tar.gz
    [ -d /storage/server ] || mkdir -p /storage/server
    mv -f mysql-5.5.43-linux2.6-x86_64 /storage/server/
    ln -sf /storage/server/mysql-5.5.43-linux2.6-x86_64 $basedir
    chown -R mysql:mysql $basedir
}

[ -d /storage/server/mysql ] || Install

# 新建mysql数据目录
[ -d $datadir ] || mkdir -p $datadir;chown -R mysql:mysql $datadir

# 生成新的配置文件
function Config () {
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

cd $basedir
# 初始化
Config
./scripts/mysql_install_db --user=$user --basedir=$basedir --datadir=$datadir

# 启动
[ -f /etc/init.d/mysqld ] || cp support-files/mysql.server /etc/init.d/mysqld;chmod 755 /etc/init.d/mysqld
chkconfig --list mysqld >/dev/null 2>&1 || chkconfig --add mysqld;chkconfig mysqld on
/etc/init.d/mysqld restart

# 安全设置
./bin/mysql_secure_installation<<EOF

Y  # 设置root密码
$passwd 
$passwd
Y  
Y  
Y  
Y
EOF
