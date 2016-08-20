#!/bin/bash
# author pdd
# -f sender email address, -xu USERNAME, -xp PASSWORD
# -t to email address, -u message subject, -m message body

exec 1>>/tmp/zabbix_mail.log 2>&1  # 记录发送日志

to="$1"

subject="$2"

body="$3"

/usr/local/bin/sendEmail -f test@qq.com -t "$to" -s smtp.exmail.qq.com -u "$subject" -o message-content-type=text -o message-charset=utf8 -xu test@qq.com -xp test123 -m "$body"
