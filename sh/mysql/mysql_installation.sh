#!/bin/bash
# 二进制安装MYSQL

lsof -i:3306 >/dev/null && { echo "3306端口已被占用，请检查是否被其它进程占用，或MYSQL已经安装完成"; exit 1; }

basedir=/m2odata/server/mysql
datadir=/storage/db
socket=/tmp/mysql.sock
user=mysql
password="test"
[ -n "$password" ] || { echo "Error: 请在配置文件中输入正确的mysql password"; exit 1; }

# 安装所需包，添加用户名
grep -q $user /etc/passwd || useradd -M -s /sbin/nologin $user
rpm -q --quiet compat-libstdc++-33.x86_64 || yum -y install compat-libstdc++-33.x86_64
rpm -q --quiet libaio.x86_64 || yum -y install libaio.x86_64

# 配置文件
function config () {
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

# 安装
function install () {
    tar -xz -f mysql-5.6.31-linux-glibc2.5-x86_64.tar.gz
    \cp -rf mysql-5.6.31-linux-glibc2.5-x86_64 /m2odata/server/mysql
    chown -R $user:$user $basedir
}

# 数据库初始化
function init_db () {
    # 新建mysql数据目录
    [ -d $datadir ] || { mkdir -p $datadir; chown -R $user:$user $datadir; }
    cd $basedir
    ./scripts/mysql_install_db --user=$user --basedir=$basedir --datadir=$datadir
}

# 开机启动
function self_boot () {
    [ -f /etc/init.d/mysqld ] || { cp support-files/mysql.server /etc/init.d/mysqld; chmod 755 /etc/init.d/mysqld; }
    chkconfig --list mysqld >/dev/null  || { chkconfig --add mysqld; chkconfig mysqld on; }
}

# 添加iptables
function add_iptables() {
    grep -w -q 3306 /etc/sysconfig/iptables
    if [ $? != 0 ];then
        sed -i '/--dport 22/a -A INPUT -m state --state NEW -m tcp -p tcp --dport 3306 -j ACCEPT' /etc/sysconfig/iptables
        /etc/init.d/iptables reload
    fi
}

# 安全设置
function security () {
./bin/mysql_secure_installation<<EOF

Y
$password
$password
Y  
Y  
Y  
Y
EOF
}

if [ ! -d /m2odata/server/mysql ];then
    config
    install
    init_db  # 数据库初始化的时候要读取my.cnf里面的参数
    self_boot
    add_iptables
    /etc/init.d/mysqld start
    security
    echo -e "MYSQL安装完成！\n"
else
    echo -e "MYSQL已安装！\n"
fi
