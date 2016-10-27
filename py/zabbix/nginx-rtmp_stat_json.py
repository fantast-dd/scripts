#!/usr/bin/python
# -*- coding: utf-8 -*-
# date 2016/10/27 author pdd

'''
    curl的直播流状态值写入本地CACHE文件 后续具体的直播频道流值从该文件获取 CACHE文件CACHETTL秒更新一次（基于文件属性ctime）
    http://127.0.0.1:81/control/get/all_streams
'''

import os
import sys
import time
import json
import urllib2

class Live(object):

    def __init__(self,url,CACHETTL,CACHE,STREAM):
        self.url = url
        self.CACHETTL = CACHETTL
        self.CACHE = CACHE
        self.STREAM = STREAM
    
    def __request(self):
        try:
            r = urllib2.urlopen(self.url,timeout=1)
        except urllib2.URLError, e:
            print 0  # 给zabbix触发直播流down报警的值
            exit(1)  # 异常退出
        else:
            stream = json.loads(r.read())
            channel = stream["servers"][0]["applications"][0]["pushes"]  # 选择推流模式数据
            clear = {}
            for i in channel:
                clear.update({i["name"]:{ "active":i["active"],"bitrate":(i["audio_bitrate"]+i["video_bitrate"])}})
            with open(self.CACHE,'w') as f:
                f.write(json.dumps(clear))  # 把clear(dict类型)序列化后写入CACHE文件
    
    def __generate_cache(self):
        TIMENOW = int(time.time())
        if os.path.isfile(self.CACHE) and os.path.getsize(self.CACHE) > 0:
            TIMECACHE = int(os.path.getctime(self.CACHE))
        else:
            TIMECACHE = 0
        if (TIMENOW - TIMECACHE) > self.CACHETTL:
            self.__request()

    def get_status(self):
        self.__generate_cache()
        with open(self.CACHE,'r') as f:
            r = json.load(f)  # 从CACHE文件中读取字符串并反序列化
            if r[self.STREAM]["active"] == 1:
                print r[self.STREAM]["bitrate"]
            else:
                print 0

if __name__ == "__main__":
    url = "http://192.168.0.55:81/control/get/all_streams"  # 直播频道流状态值url
    CACHETTL = 60  # 本地CACHE文件更新时间间隔
    CACHE = "/tmp/pyrtmp-status.cache"  # 本地CACHE文件绝对路径
    STREAM = sys.argv[1]  # 某个具体直播频道
    status = Live(url,CACHETTL,CACHE,STREAM)
    status.get_status()
