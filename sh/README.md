##shell安装服务一般步骤

1. 判断服务端口是否存在，存在则退出安装
2. 安装，生成配置文件，修改iptables，开机启动等等函数
3. 判断服务是否已安装（根据程序目录路径来判断），是调用第二步骤中的各个函数，否pass
4. 启动服务

### 伪代码
	#!/bin/bash
	# date 06/9/18 pdd
	
	# procedure 1
    # exec 1 >out.log 2>&1 记录日志
	lsof -i:port && { echo -e "端口已被占用！\n"; exit 1; }
	
	# procedure 2
	function install () {
		# 安装程序
	}
	
	function config () {
		# 生成配置文件
	}
	
	function add_iptables () {
		grep -q -w port /etc/sysconfig/iptables
		if [ ! $? = 0 ];then
			sed -i '/--dport 22/a -A INPUT -m state --state NEW -m tcp -p tcp --dport $port -j ACCEPT' /etc/sysconfig/iptables
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
		add_iptables
		self_boot
		...
		echo -e "服务安装完成！\n"
	else
		echo -e "服务已安装！\n"
		
	# procedure 4
	$EXEC
