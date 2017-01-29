#!/usr/bin/python
# -*- coding: utf-8 -*-
# Date: 2016/6/01

__author__ = 'pdd'

' 查看所有表的引擎类型 '

import MySQLdb
import json

def check_engine(dbhost, dbuser, dbpass):

    conn = MySQLdb.connect(host=dbhost, user=dbuser, passwd=dbpass)
    cursor = conn.cursor(cursorclass=MySQLdb.cursors.DictCursor)  # 查询结果以dict形式返回
    dbs_sql = "show databases like '%s'" % "m2o_%"
    cursor.execute(dbs_sql)
    dbs = cursor.fetchall()
    for db in dbs:
        table_sql = "show table status from %s" % db['Database (m2o_%)']
        cursor.execute(table_sql)
        tables = cursor.fetchall()
        info = [{table["Name"]:table["Engine"]} for table in tables]
        print(json.dumps({db['Database (m2o_%)']: info}, indent=4))
    conn.close()

if __name__ == "__main__":

    dbhost = '127.0.0.1'
    dbuser = 'root'
    dbpass = '*'
    check_engine(dbhost, dbuser, dbpass)
