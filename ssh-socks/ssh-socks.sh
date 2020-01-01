#!/bin/sh
PORT=1086
HOST=""
username=""
password=""
if [[ ${HOST} == "" ]] || [[ ${username} == "" ]] || [[ ${password} == "" ]]; then
	echo "请先把服务器地址、账号、密码填一下!"
	exit
fi
read -p "请输入您要的操作:【0关闭/1开启】" mode

function auto_login_ssh(){
	expect -c "
	set timeout 3600;
	spawn ssh -qTfnN -D $1 $2;
	expect {
		*assword:* {
			send $3\r;
		}
	}
	interact
	"
	return $?
}

#proxy_conf_helper用法：3个模式：自动、全局、关闭
#--mode auto --pac-url http://localhost:1089/proxy.pac -x 127.0.0.1 -x localhost -x 192.168.0.0/16 -x 10.0.0.0/8 -x FE80::/64 -x ::1 -x FD00::/8
#--mode global --port 1086 --socks-listen-address 127.0.0.1 -x 127.0.0.1 -x localhost -x 192.168.0.0/16 -x 10.0.0.0/8 -x FE80::/64 -x ::1 -x FD00::/8
#--mode off --pac-url http://localhost:1089/proxy.pac --port 1086 --socks-listen-address 127.0.0.1 -x 127.0.0.1 -x localhost -x 192.168.0.0/16 -x 10.0.0.0/8 -x FE80::/64 -x ::1 -x FD00::/8

#终端代理命令，这个还不能用
#export http_proxy=http://127.0.0.1:1087;export https_proxy=http://127.0.0.1:1087;

if [[ ${mode} -eq 1 ]]; then
	#不重复运行
	if (pgrep -f 'ssh -qTfnN'>/dev/null)
	then
		echo "Already running!"
		exit
	else
		echo "Starting"
		# ssh -qTfnN -D ${PORT} ${username}@${HOST}
		auto_login_ssh ${PORT} ${username}@${HOST} ${password}
	fi
	echo 111111 | sudo -S ./proxy_conf_helper --mode global --port ${PORT} --socks-listen-address 127.0.0.1 -x 127.0.0.1 -x localhost -x 192.168.0.0/16 -x 10.0.0.0/8 -x FE80::/64 -x ::1 -x FD00::/8
else
	#终止终端打开的所有ssh会话
	echo 111111 | sudo -S killall ssh
	echo 111111 | sudo -S ./proxy_conf_helper --mode off --pac-url http://localhost:1089/proxy.pac --port ${PORT} --socks-listen-address 127.0.0.1 -x 127.0.0.1 -x localhost -x 192.168.0.0/16 -x 10.0.0.0/8 -x FE80::/64 -x ::1 -x FD00::/8
fi
echo ""