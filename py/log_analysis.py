#!/usr/bin/env python
#-*- coding:utf-8 -*-
#date 2016/6
__author__ = 'pdd'

' 读取前一天nginx访问日志 并处理分析后写入mongodb '

import re
import os
import time
import socket
import logging
import pymongo
import tarfile
import datetime

logging.basicConfig(level=logging.DEBUG,format='%(asctime)s %(levelname)s %(message)s',datefmt='%a, %d %b %Y %H:%M:%S',filename='/var/log/nginx_access_analysis',filemode='w')

class Log_Analysis(object):

    def __init__(self, hosts, full_path):
        self.hosts = hosts
        self.full_path = full_path
        self.templates = {}
        for host in self.hosts:
            self.templates[host] = {'num': 0, 'code': {'2xx': 0, '3xx': 0, '4xx': 0, '5xx': {'all': 0, '504': 0}},'size': 0, 'response_time': 0.0}

    def __uncompress(self):
        tar = tarfile.open(self.full_path)
        for tar_info in tar:
            file = tar.extractfile(tar_info)  # 生成file object 可迭代 
            for line in file:
                self.__process(line)

    def __process(self, line):
        for host in self.hosts:
            if re.search(host + '.kan0512.com', line):
                host_status = re.split(r'\s+', line)
                self.templates[host]['num'] += 1
                code = host_status[6].strip('|')[0]
                if '2' is code:
                    self.templates[host]['code']['2xx'] += 1
                elif '3' is code:
                    self.templates[host]['code']['3xx'] += 1
                elif '4' is code:
                    self.templates[host]['code']['4xx'] += 1
                else:
                    if '504' == host_status[6].strip('|'):
                        self.templates[host]['code']['5xx']['504'] += 1
                    self.templates[host]['code']['5xx']['all'] += 1
                self.templates[host]['size'] += int(host_status[7])
                try:
                    self.templates[host]['response_time'] += float(host_status[-3])  # response_time值出现过是'-'
                except ValueError as e:
                    self.templates[host]['response_time'] += 0.0
                break  # 如果匹配到就跳出循环 读取下一条日志进行匹配处理

    def result(self):
        self.__uncompress()

    def w_mongo(self):
        hostname = socket.gethostname()
        client = pymongo.MongoClient('192.168.0.52',27017)
        db = client.access_log
        collection = db[hostname]
        for key,value in self.templates.items():
            try:
                collection.insert_one({key:value,"create_time":time.time()})
            except:
                logging.error('insert mongodb failed!')

def elapse_time(func):
    def wrapper():
        start_time = time.clock()
        func()
        end_time = time.clock()
        logging.debug('%s elapse time: %.2f' % (func.__name__, (end_time - start_time)))
    return wrapper

def interval():
    today = datetime.date.today()
    difference = datetime.timedelta(days=-1)
    last_day = (today + difference).strftime("%Y%m%d")
    path = '/m2odata/log/logs/%s/%s/' % (last_day[0:4],last_day[4:6])
    log = 'access_%s.log.tar.gz' % last_day
    return '%s' % (path + log)

if __name__ == '__main__':

    #hosts_raw = 'mobile.%s img.%s m2o.%s html.%s mobilesc.%s yao.%s live.%s tuwen.%s feedback.%s im.%s template.%s syssc.%s circuseesc.%s adv.%s' % (('kan0512.com',) * 14)  # 域名访问量从大到小依次排序+break语句 减少循环次数 mongodb 字段不能包含.
    hosts_raw = 'mobile img m2o html mobilesc yao live tuwen feedback im template syssc circuseesc adv'  # 域名访问量从大到小依次排序+break语句 减少循环次数
    hosts = hosts_raw.split( )
    full_path = interval()
    if os.path.exists(full_path) and os.path.getsize(full_path):
        status = Log_Analysis(hosts, full_path)
        result = elapse_time(status.result)
        result()
        w_mongo = elapse_time(status.w_mongo)
        w_mongo()
    else:
        logging.error('file not exists or empty')
