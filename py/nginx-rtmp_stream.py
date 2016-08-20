#!/usr/bin/python
# -*- coding: utf-8 -*-
# author pdd

'''
    curl的直播流状态值写入本地CACHE文件 后续具体的直播频道流值从该文件获取 CACHE文件根据ctime一分钟更新一次
'''

import os
import re
import sys
import time
import urllib2

class Live(object):

    def __init__(self,url,CACHETTL,CACHE,STREAM):
        self.url = url
        self.CACHETTL = CACHETTL
        self.CACHE = CACHE
        self.STREAM = STREAM
    
    def generate_cache(self):
        TIMENOW = int(time.time())
        if os.path.isfile(self.CACHE) and os.path.getsize(self.CACHE) > 0:
            TIMECACHE = int(os.path.getctime(self.CACHE))
        else:
            TIMECACHE = 0
        if (TIMENOW - TIMECACHE) > self.CACHETTL:
            try:
                r = urllib2.urlopen(self.url,timeout=1)
                with open(self.CACHE,'w') as f:
                    f.write(r.read())
            except urllib2.URLError, e:
                print 0  # 给zabbix触发直播流down报警的值
                exit(1)  # 退出程序 不让从CACHE文件获取值

    def get_status(self):
        self.generate_cache()
        with open(self.CACHE,'r') as f:
            r = f.read()
            name = re.findall(r'<name>(.*_sd)</name>',r)
            flow = re.findall(r'<bw_in>(.*)</bw_in>',r)[1:]
            stream = dict(zip(name,flow))
            print(stream[self.STREAM])

if __name__ == "__main__":
    url = "http://127.0.0.1:81/stat"  # 直播频道流状态值url
    CACHETTL = 60  # 本地CACHE文件更新时间间隔
    CACHE = "/tmp/nginx-rtmp-status.cache"  # 本地CACHE文件绝对路径
    STREAM = sys.argv[1]  # 某个具体直播频道
    status = Live(url,CACHETTL,CACHE,STREAM)
    status.get_status()
