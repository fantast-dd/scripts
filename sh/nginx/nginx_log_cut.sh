#!/bin/bash
# date 2016/8/3 pdd
# nginx 访问日志切割


logs_path="/storage/log/"
cut_log_path="/storage/log/logs/"

date=$(date -d "-1 days" +"%y%m%d")
ldate=$(date -d "-8 days" +"%y%m%d")  # nginx 访问日志保留7天

pid_path="/storage/server/nginx/logs/nginx.pid"

[ -d ${cut_log_path} ] || mkdir -p /storage/log/logs

mv ${logs_path}access.log ${cut_log_path}access_${date}.log

kill -USR1 `cat ${pid_path}`

cd ${cut_log_path} && tar -zc -f access_${date}.log.tar.gz access_${date}.log --remove-files

[ -e access_${ldate}.log.tar.gz ] && rm -f access_${ldate}.log.tar.gz
