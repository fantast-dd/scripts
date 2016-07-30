#!/bin/bash
# pdd 2016/7/28
# 文件5天没有被修改 且目前没有被任何进程占用 则删除

for i in `find /tmp/TsManager -type f`
do
    if [ `stat -c "%Y" $i` -lt `date -d '-5 day' +%s` ];then
        fuser -s $i && : || rm -f $i
    fi
done
