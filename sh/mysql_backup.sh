#!/bin/bash 
# backup single db 

DATE=`date +%Y%m%d%H%M%S` 
USER="backupuser"
PASSWORD="backupuser"
##The folder where database save，make sure the"/web/database_back/"folder is exist 
BACKDIR="/m2odata/backupdb/"`date -d "-1 days" "+%Y%m%d"`

[ -d ${BACKDIR} ] || mkdir -p ${BACKDIR}

##Where appropriate changes according to MySQL installation location 
cd /m2odata/server/mysql/bin/
echo "Backuping Database , please waiting..." 
for db in `./mysql -u$USER -p$PASSWORD -B -N -e 'show databases like "m2o_%"' | xargs`
do
    #Backup the entire database
    ./mysqldump -u$USER -p$PASSWORD --databases $db --skip-lock-tables --default-character-set=utf8 | gzip > $BACKDIR/${db}_$DATE.gz
    echo "Backup database $db success!!" 
done

##Here to keep a backup of 7 days
OBSOLOTESQL="/m2odata/backupdb/"`date -d -8day +%Y%m%d`
[ -d ${OBSOLOTESQL} ] && rm -rf ${OBSOLOTESQL}
