#!/bin/bash

line="\-A INPUT \-s 192.168.0.8 \-m state \-\-state NEW \-m tcp \-p tcp \-\-dport 10050 \-j ACCEPT"
iptables_conf="/etc/sysconfig/iptables"

grep -s "$line" $iptables_conf
if [ $? != 0 ];then
    sed -i "/^-A INPUT -i lo/a $line" $iptables_conf
    /etc/init.d/iptables reload
fi
