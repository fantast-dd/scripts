##shell安装服务一般步骤

1. 判断服务端口是否存在，存在则退出安装
2. 编写下载，安装，生成配置文件，修改iptables，开机启动等等函数
3. 判断服务是否已安装（根据程序目录路径来判断），是调用第二步骤中的各个函数，否pass
4. 调用iptables等非安装配置函数，启动服务

### 伪代码
	#!/bin/bash
	# date 06/9/18 pdd

    # linux shell color support.
    RED="\\033[31m"
    GREEN="\\033[32m"
    #YELLOW="\\033[33m"
    BLACK="\\033[0m"
	
	# procedure 1
    # exec 1 >out.log 2>&1 记录日志
	netstat -tupln | grep -q -w $port && { echo -e "${RED}端口已被占用\t\t[退出安装]${BLACK}\n"; exit 1; }
	
	# procedure 2
	function download () {
		# 下载文件
	}
	
	function install () {
		# 安装程序
	}
	
	function config () {
		# 生成配置文件
	}
	
	function add_iptables () {
   		local iptables_conf = /etc/sysconfig/iptables
		grep -q -w $port $iptables_conf
		if [ ! $? = 0 ];then
			sed -i "/--dport 22/a -A INPUT -m state --state NEW -m tcp -p tcp --dport $port -j ACCEPT" $iptables_conf
			/etc/init.d/iptables reload
		fi
	}
	
	function self_boot () {
        # chkconfig or /etc/rc.local 
	}
	
	function ... () {
		# 其它函数，按需求
	}
	
	# procedure 3
	if [ ! -f 服务安装路径 ];then
		install
		config
		echo -e "${YELLOW}服务安装完成\t\t[success]${BLACK}\n"
	else
		echo -e "${YELLOW}服务已安装！${BLACK}\n"
		
	# procedure 4
    add_iptables
    self_boot
	$EXEC