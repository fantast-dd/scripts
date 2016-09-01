#!/bin/bash
# 2014-12-27 pdd
# backup mysql completely

USER="backupuser"  # Select and Lock Tables privileges
PASSWD="backupuser"
HOST="127.0.0.1"
BACKUP_DIR="/data/mysql_backup"
DATE=$(date "-d -1 days" "+%Y_%m_%d")
KDATE=$(date "-d -8 days" "+%Y_%m_%d") # keep 7 backup files

/usr/bin/mysqldump -u$USER -p$PASSWD -h $HOST --all-databases >$BACKUP_DIR/mysql_$DATE.sql

if [ 0 -eq $? ];then
        echo "mysql backup success !"
else
        echo "mysql backup fail !!!"
fi

[ -e $BACKUP_DIR/mysql_$KDATE.sql ] && rm -f $BACKUP_DIR/mysql_$KDATE.sql
