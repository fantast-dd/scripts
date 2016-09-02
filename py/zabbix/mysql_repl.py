#!/usr/bin/python
# -*- coding: utf-8 -*-
# check mysql slave status
# 2016/1/18 pdd

'''
    sys.argv[1] -> (/tmp/mysql3306.sock,/tmp/mysql3307.sock ...) 因为有多个mysql slave运行在mysqld_multi上
    if Slave_IO_Running=Yes && Slave_SQL_Running=Yes print 1 else print 0
'''

import MySQLdb
import sys

class check_mysql_repl:
    def __init__(self,sock):
        self.dbhost = 'localhost'
        self.dbuser = 'zabbix_check'
        self.dbpass = 'zabbix@check'
        self.sock = sock

    def execution(self):
        try:
            conn = MySQLdb.connect(host=self.dbhost,user=self.dbuser,passwd=self.dbpass,unix_socket=self.sock)
            cursor = conn.cursor(cursorclass = MySQLdb.cursors.DictCursor)
            execute = 'show slave status'
            cursor.execute(execute)
            data = cursor.fetchall()
            conn.close()
            return data

        except MySQLdb.Error,e:
            print "Mysql Error %d: %s" % (e.args[0], e.args[1])
            sys.exit(1)

    def get_repl_status(self):
        result = self.execution()
        io = result[0]['Slave_IO_Running']
        sql = result[0]['Slave_SQL_Running']
        if io == 'Yes' and sql == 'Yes':
            return 1
        else:
            return 0

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print "Usage: %s mysql.sock" % sys.argv[0]
        sys.exit(1)
    mysql = check_mysql_repl(sys.argv[1])
    print mysql.get_repl_status()
