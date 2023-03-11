#!/usr/bin/env bash
Green="\033[32m"
Font="\033[0m"
Red="\033[31m" 


mem=$(free -m | grep Mem | awk '{print $2}')
swapsize=`expr $mem + $mem`

#检查是否存在swapfile
grep -q "swapfile" /etc/fstab

#如果不存在将为其创建swap
if [ $? -ne 0 ]; then
	echo -e "${Green}swapfile未发现，正在为其创建swapfile${Font}"
	fallocate -l ${swapsize}M /swapfile
	chmod 600 /swapfile
	mkswap /swapfile
	swapon /swapfile
	echo '/swapfile none swap defaults 0 0' >> /etc/fstab
         echo -e "${Green}swap创建成功，并查看信息：${Font}"
         cat /proc/swaps
         cat /proc/meminfo | grep Swap
else
	echo -e "${Red}swap已存在${Font}"
fi
