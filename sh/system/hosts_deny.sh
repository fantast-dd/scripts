#!/bin/bash
# 从/var/log/secure 找出Failed Password >= 5的ip 并写入/etc/hosts.deny文件

awk '/Failed password/ {print $(NF-3)}' /var/log/secure* | sort | uniq -c | \
while read a b
do
        grep -q $b /etc/hosts.deny

        if [ $? != 0 ];then

                if [ $a -ge 5 ];then

                        echo "sshd:$b" >> /etc/hosts.deny
　　             fi
        fi
done
