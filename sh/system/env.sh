#!/bin/bash
# 系统初始化

# linux shell color support.
RED="\\033[31m"
GREEN="\\033[32m"
#YELLOW="\\033[33m"
BLACK="\\033[0m"

# 安装必要的包
yum -y install epel-release wget ntpdate gcc

# 更新所有包
yum update -y

# 修改主机名
function edit_hostname () {
    # 填写主机名
    local name=""
    [ -n "$name" ] || { echo -e "${RED}请填写正确的主机名\t\t[warning]${BLACK}"; return 2; }
    current_name=$(hostname)
    [ "$name" = "$current_name" ] || sed -r -i "s/^(HOSTNAME=).*/\1$name/" /etc/sysconfig/network
}

# 修改内核参数
function edit_sysctl () {
    cp /etc/sysctl.conf /etc/sysctl.conf.bak
cat >>/etc/sysctl.conf<<EOF

# hogesoft add
# IPv6 disabled
# net.ipv6.conf.all.disable_ipv6 = 1
# net.ipv6.conf.default.disable_ipv6 = 1
# net.ipv6.conf.lo.disable_ipv6 = 1

# add - time-wait
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 20000

#close rfc1323 timestamps
net.ipv4.tcp_timestamps = 0

# max open files
fs.file-max =6553560
# max read buffer
net.core.rmem_max = 67108864
# max write buffer
net.core.wmem_max = 67108864
# default read buffer
net.core.rmem_default = 65536
# default write buffer
net.core.wmem_default = 65536
# max processor input queue
net.core.netdev_max_backlog = 4096
# max backlog
net.core.somaxconn = 4096

net.netfilter.nf_conntrack_max = 524288
net.netfilter.nf_conntrack_buckets = 65536
net.netfilter.nf_conntrack_tcp_timeout_time_wait = 60
net.ipv4.tcp_synack_retries = 3
net.ipv4.tcp_syn_retries = 3
EOF
}

# 修改文件描述符
function edit_ulimit () {
    local limits="/etc/security/limits.conf"
    grep -q "\* soft nofile 65535" $limits || echo "* soft nofile 65535" >> $limits
    grep -q "\* hard nofile 65535" $limits || echo "* hard nofile 65535" >> $limits
}

# 关闭selinux
function edit_selinux () {
    status=$(getenforce)
    [ "$status" = "Disabled" ] || sed -r -i 's/^(SELINUX=).*/\1disabled/' /etc/sysconfig/selinux
}

# ntpdate加入计划任务
function add_ntpdate () {
    grep -q "ntpdate" /var/spool/cron/root || echo "1 * * * * /usr/sbin/ntpdate cn.pool.ntp.org" >>/var/spool/cron/root
}

# 新建相关目录，如果目录存在则chmod，不存在则新建目录并chmod
function add_dirs() {
    [ -d /storage ] || mkdir /storage && chmod 755 /storage
    [ -d /storage/server ] || mkdir /storage/server && chmod 755 /storage/server
    [ -d /storage/log ] || mkdir /storage/log && chmod 777 /storage/log
    [ -d /storage/tmp ] || mkdir /storage/tmp && chmod 777 /storage/tmp
    [ -d /storage/www ] || mkdir /storage/www && chmod 755 /storage/www
    [ -d /storage/sh ] || mkdir /storage/sh && chmod 755 /storage/sh
}

# 执行
edit_hostname
grep -q "# hogesoft add" /etc/sysctl.conf || { edit_sysctl; sysctl -p; }
edit_ulimit
edit_selinux
add_ntpdate
add_dirs

echo -e "${GREEN}环境初始化完成\t\t[success]${BLACK}\n"
