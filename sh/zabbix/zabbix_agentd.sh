#!/bin/bash
# install zabbix_agentd
# 2016/1/7 pdd

PORT=10050
EXEC=/usr/local/zabbix-agent/sbin/zabbix_agentd

exec 1>/tmp/zabbix_install.log 2>&1 # record install log;tail -f /tmp/zabbix_install.log 在客户端实时查看安装日志

function Check_running() {
        netstat -tpln | grep -q ${PORT} && echo "zabbix agentd is running"
}

function Check_sbin() {
        test -f /usr/local/zabbix-agent/sbin/zabbix_agentd && echo "zabbix has been installed"
}

function Config() {
        id zabbix || useradd -M -s /sbin/nologin zabbix
        test -f /usr/lib64/libiconv.so.2 || ln -s /usr/local/lib/libiconv.so.2.5.1 /usr/lib64/libiconv.so.2 #某些节点启动zabbix_agentd需要libiconv库函数 某些不需要 目前不清楚原因

cat >/usr/local/zabbix-agent/etc/zabbix_agentd.conf<<EOF  #有时不能正常运行
LogFile=/tmp/zabbix_agentd.log
Server=172.18.2.196
#ServerActive=172.18.2.196
Hostname=$(hostname)
Include=/usr/local/zabbix-agent/etc/zabbix_agentd.conf.d/
EOF
}

function Install() {
        Config
        cd /usr/local/src/ && tar -zx -f zabbix-2.4.7.gz
        cd zabbix-2.4.7 && ./configure --prefix=/usr/local/zabbix-agent --enable-agent && make && make install
        $EXEC
}

date +"%D %T" #记录程序安装时间

Check_running && exit #if zabbix_agentd在运行中 退出

Check_sbin && ${EXEC} || Install #if zabbix_agentd已经安装 就启动程序 else 源码安装程序
