#!/bin/bash
# date 2016/8/3 pdd
# nginx 访问日志切割


logs_path="/storage/log"
cut_log_path="/storage/log/logs"
pid_path="/usr/local/nginx/logs/nginx.pid"

date=$(date -d "-1 days" +"%y%m%d")
ldate=$(date -d "-8 days" +"%y%m%d")  # nginx 访问日志保留7天

[ -d $cut_log_path ] || mkdir -p $cut_log_path
mv "${logs_path}/access.log" "${cut_log_path}/access_${date}.log"
kill -USR1 `cat ${pid_path}`

cd $cut_log_path
[ -e "access_${ldate}.log" ] && rm -f "access_${ldate}.log"
