#!/bin/bash
# 2017/1/28 pdd

red='\e[0;31m' # 红色  
green='\e[0;32m' # 绿色  
blue='\e[0;34m' # 蓝色  
purple='\e[0;35m' # 紫色  
NC='\e[0m' # 没有颜色  

MySQL_USER=zabbix
MySQL_PASSWORD=zabbix
MySQL_HOST=localhost
MySQL_PORT=3306
MySQL_DUMP_PATH=/storage/mysql_backup
MYSQL_BIN_PATH=/usr/bin/mysql
MYSQL_DUMP_BIN_PATH=/usr/bin/mysqldump
MySQL_DATABASE_NAME=zabbix
DATE=$(date '+%Y-%m-%d')

MySQLDUMP () {
    [ -d "$MySQL_DUMP_PATH" ] || mkdir $MySQL_DUMP_PATH
    cd $MySQL_DUMP_PATH
    [ -d logs ] || mkdir logs
    [ -d "$DATE" ] || mkdir $DATE
    cd $DATE
    
    local TABLE_NAME_ALL=$($MYSQL_BIN_PATH -u${MySQL_USER} -p${MySQL_PASSWORD} -h${MySQL_HOST} $MySQL_DATABASE_NAME -e \
    "show tables" | egrep -v "(Tables_in_zabbix|history*|trends*|acknowledges|alerts|auditlog|events|service_alarms)")
    for TABLE_NAME in $TABLE_NAME_ALL
    do
        $MYSQL_DUMP_BIN_PATH --opt -u${MySQL_USER} -p${MySQL_PASSWORD} -P${MySQL_PORT} -h${MySQL_HOST} \
        $MySQL_DATABASE_NAME $TABLE_NAME > ${TABLE_NAME}.sql
        sleep 0.01
    done

    local STATUS_LOG=${MySQL_DUMP_PATH}/logs/ZabbixMysqlDump.log
    [ "$?" == 0 ] && echo "${DATE}: Backup zabbix succeed"  >> $STATUS_LOG || echo "${DATE}: Backup zabbix not succeed" >> $STATUS_LOG
    
    cd ${MySQL_DUMP_PATH}
    [ "$?" == 0 ] && rm -rf $(date +%Y-%m-%d --date='5 days ago')
    exit 0
}

MySQLImport () {
    cd ${MySQL_DUMP_PATH}
    local DATE=$(ls $MySQL_DUMP_PATH | egrep "\b^[0-9]+-[0-9]+-[0-9]+$\b")
    echo -e "${green}${DATE}${NC}"
    echo -e "${blue}what DATE do you want to import,please input date:${NC}"
    read SELECT_DATE
    if [ -d "$SELECT_DATE" ];then
        echo -e "you select is ${green}${SELECT_DATE}${NC}, do you want to contine,if,input ${red}(yes|y|Y)${NC},if other exit"
        read Input
        [[ 'yes|y|Y' =~ "$Input" ]]
        status="$?"
        if [ "$status" == "0"  ];then
            echo "now import SQL....... Please wait......."
        else
            exit 1
        fi
        cd $SELECT_DATE
        for PER_TABEL_SQL in $(ls *.sql)
        do
           $MYSQL_BIN_PATH -u${MySQL_USER} -p${MySQL_PASSWORD}  -h${MySQL_HOST} $MySQL_DATABASE_NAME < $PER_TABEL_SQL
           echo -e "import ${PER_TABEL_SQL} ${purple}........................${NC}"
        done 
        echo "Finish import SQL,Please check Zabbix database"
    else 
        echo "Don't exist ${SELECT_DATE} DIR" 
    fi
}

case "$1" in
MySQLDUMP|mysqldump)
    MySQLDUMP
    ;;
MySQLImport|mysqlimport)
    MySQLImport
    ;;
*)
    echo "Usage: $0 {(MySQLDUMP|mysqldump) (MySQLImport|mysqlimport)}"
    ;;
esac
