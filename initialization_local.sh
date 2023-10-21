#!/bin/bash

# coding:utf-8

# **********************************************************
# * Author        : buyfakett
# * Email         : buyfakett@vip.qq.com
# * Create time   : 2023-6-5
# * Last modified : 2023-10-21
# * Filename      : initialization.sh
# * Description   : shell
# **********************************************************


pwd=$(pwd)
# docker位置
docker_data_site=${docker_data_site:-"/data/data-docker"}
# docker版nginx快捷位置
docker_nginx_site=${docker_nginx_site:-"/data/docker/nginx"}
# 本地版nginx快捷位置
local_nginx_site=${local_nginx_site:-"/data/docker/nginx"}
# 是否是中国大陆(1:是,2:不是)
is_mainland=${is_mainland:-"1"}

# 颜色参数，让脚本更好看
Green="\033[32m"
Font="\033[0m"
Red="\033[31m" 

# 打印帮助文档
function echo_initialization(){
        echo -e "${Green}
         _   __   _   _   _____   _       ___   _       _   ______      ___   _____   _   _____   __   _  
        | | |  \ | | | | |_   _| | |     /   | | |     | | |___  /     /   | |_   _| | | /  _  \ |  \ | | 
        | | |   \| | | |   | |   | |    / /| | | |     | |    / /     / /| |   | |   | | | | | | |   \| | 
        | | | |\   | | |   | |   | |   / / | | | |     | |   / /     / / | |   | |   | | | | | | | |\   | 
        | | | | \  | | |   | |   | |  / /  | | | |___  | |  / /__   / /  | |   | |   | | | |_| | | | \  | 
        |_| |_|  \_| |_|   |_|   |_| /_/   |_| |_____| |_| /_____| /_/   |_|   |_|   |_| \_____/ |_|  \_| 

                    Email:buyfakett@vip.qq.com  Author:buyfakett  Filename:initialization.sh
        ${Font}"
}

# 判断系统
function Inspection_system(){
        # 获取发行版信息
        distro=$(cat /etc/*-release | grep -w "ID" | awk -F '=' '{print $2}' | tr -d '"')
        # 获取操作系统版本
        os_version=$(cat /etc/centos-release | grep -oE '[0-9]+\.[0-9]+' | cut -d'.' -f1)

        case "$distro" in
        "centos")
                if [[ $os_version -eq 7 ]]; then
                        main
                else
                        if (whiptail --title "当前系统不是CentOS 7.*版本，是否继续安装" --yesno "当前系统不是CentOS 7.*版本，是否继续安装" --fb 15 70); then
                                main
                        else
                                echo -e "${Red}已跳过安装${Font}"
                                exit 0
                        fi
                fi
                ;;
        "ubuntu")
                echo "本脚本是为centos7设计的，当前系统是：Ubuntu"
                exit 1
                ;;
        "fedora")
                echo "本脚本是为centos7设计的，当前系统是：Fedora"
                exit 1
                ;;
        *)
                echo "本脚本是为centos7设计的，当前系统是：$distro"
                exit 1
                ;;
        esac   
}

# root权限
function root_need(){
        if [[ $EUID -ne 0 ]]; then
                echo -e "${Red}你现在不是root权限，请使用sudo命令或者联系网站管理员${Font}"
                exit 1
        fi
}

# 关闭防火墙
function close_firewall(){
        systemctl disable firewalld.service --now
}

# 开始之前
function start(){
        cd download_file/rpm
        yum localinstall ./*.rpm -y
        unzip nodejs.zip
        unzip other.zip
        unzip python3.zip
        unzip openresty.zip
        unzip -d docker docker1.zip
        unzip -d docker docker2.zip
        rm -f nodejs.zip other.zip python3.zip docker1.zip docker2.zip openresty.zip
        cd ..
        unzip download_file.zip
        rm -f download_file.zip
        yum localinstall download_file/rpm/other/*.rpm 
        cd ${pwd}
}

# 下载docker
function install_docker(){
        mkdir -p /data/docker
        
        if [ "${enable_docker_rsyslog}"x == "1"x ];then
                sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
                sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/sysconfig/selinux
                sed -i 's/#$ModLoad imtcp/$ModLoad imtcp/g' /etc/rsyslog.conf
                sed -i 's/#$InputTCPServerRun 514/$InputTCPServerRun 514/g' /etc/rsyslog.conf
                systemctl restart rsyslog
        fi

        yum localinstall download_file/rpm/docker/*.rpm -y && systemctl enable docker --now

        if [ "${enable_docker_rsyslog}"x == "1"x ];then
                if [ "${is_mainland}"x == "1"x ];then
                        cat << EOF > /etc/docker/daemon.json
{
  "registry-mirrors": [
    "https://pee6w651.mirror.aliyuncs.com",
    "http://hub-mirror.c.163.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://registry.docker-cn.com"
  ],
  "data-root": "${docker_data_site}",
  "log-driver": "syslog",
  "log-opts": {
    "syslog-address": "tcp://127.0.0.1:514",
    "tag": "docker/{{.Name}},"
   }
}
EOF
                else
                        cat << EOF > /etc/docker/daemon.json
{
  "data-root": "${docker_data_site}",
  "log-driver": "syslog",
  "log-opts": {
    "syslog-address": "tcp://127.0.0.1:514",
    "tag": "docker/{{.Name}},"
   }
}
EOF
                fi

                systemctl restart docker

                cat << EOF > /etc/rsyslog.d/rule.conf
\$EscapeControlCharactersOnReceive off
\$template CleanMsgFormat,"%msg:2:$%\n"

\$template docker,"data/logs/docker/%syslogtag:F,44:1%/%\$YEAR%-%\$MONTH%-%\$DAY%.log"
if \$syslogtag contains 'docker' then ?docker;CleanMsgFormat
& ~
EOF
                systemctl restart rsyslog

                cat << EOF > /data/logs/docker/gzip_log.sh
#!/bin/bash

for day in 1;
do
find /data/logs/ -name \`date -d "\${day} days ago" +%Y-%m-%d\`*.log -type f -exec gzip {} \;
done
EOF

                cat << EOF > /data/logs/docker/del_gz.sh 
#!/bin/bash
find /data/logs/ -mtime +30 -name "*.gz" -exec rm -rf {} \;
EOF

                chmod +x /data/logs/docker/del_gz.sh /data/logs/docker/gzip_log.sh

                cat << EOF >> /var/spool/cron/root
0 12 * * * /bin/sh -x /data/logs/docker/gzip_log.sh
30 12 * * * /bin/sh -x /data/logs/docker/del_gz.sh
EOF

        else
                if [ "${is_mainland}"x == "1"x ];then
                        cat << EOF > /etc/docker/daemon.json
{
  "registry-mirrors": [
    "https://pee6w651.mirror.aliyuncs.com",
    "http://hub-mirror.c.163.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://registry.docker-cn.com"
  ]
}
EOF
                fi

        systemctl restart docker

        cp download_file/docker-compose /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose



        cd ${pwd}
}

#安装本地版的nginx
function install_local_nginx(){
        mkdir -p ${loacl_nginx_site}

        yum localinstall download_file/rpm/openresty/*.rpm -y

        ln -s /usr/local/openresty/nginx/conf /root/nginx

        mkdir -p ${loacl_nginx_site}/conf/conf.d
        mkdir -p ${loacl_nginx_site}/web
        mkdir -p ${loacl_nginx_site}/ssl
        mkdir -p ${loacl_nginx_site}/res
        mkdir -p ${loacl_nginx_site}/lua
        mkdir -p ${loacl_nginx_site}/logs
        chmod -R 755 ${loacl_nginx_site}/logs

        cp download_file/nginx_local.conf /usr/local/openresty/nginx/conf/nginx.conf
        cp download_file/api.conf.bak ${loacl_nginx_site}/conf/conf.d/api.conf.bak
        cp download_file/reload_local.sh ${loacl_nginx_site}/conf/conf.d/reload.sh
        cp download_file/local_nginx_index.conf ${loacl_nginx_site}/conf/conf.d/index.conf

        cat << EOF > ${loacl_nginx_site}/nginx_log.sh
#!/bin/bash
now_date=\`date -d '-1 day' +%Y-%m-%d\`
cat ${loacl_nginx_site}/logs/nginx.log > ${loacl_nginx_site}/logs/nginx-\${now_date}.log && > ${loacl_nginx_site}/logs/nginx.log
EOF

        cat << EOF > ${loacl_nginx_site}/gzip_log.sh
#!/bin/bash

for day in 1;
do
find ${loacl_nginx_site}/logs/ -name nginx-\`date -d "\${day} days ago" +%Y-%m-%d\`*.log -type f -exec gzip {} \;
done
EOF


        cat << EOF > ${loacl_nginx_site}/del_gz.sh 
#!/bin/bash
find ${loacl_nginx_site}/logs/ -mtime +30 -name "*.gz" -exec rm -rf {} \;
EOF

        chmod +x ${loacl_nginx_site}/del_gz.sh ${loacl_nginx_site}/gzip_log.sh ${loacl_nginx_site}/nginx_log.sh ${loacl_nginx_site}/conf/conf.d/reload.sh

        cat << EOF >> /var/spool/cron/root
0 0 * * * /bin/sh -x /root/nginx/nginx_log.sh
0 12 * * * /bin/sh -x /root/nginx/gzip_log.sh
30 12 * * * /bin/sh -x /root/nginx/del_gz.sh
EOF

        systemctl enable openresty --now

        cd ${pwd}
}

# 安装docker版本的nginx
function install_docker_nginx(){
        mkdir -p ${docker_nginx_site}/config/conf.d/

        cp download_file/nginx.conf ${docker_nginx_site}/config/nginx.conf

        cat << EOF > ${docker_nginx_site}/setup.sh
docker stop nginx
docker rm nginx

docker run -id \\
--name nginx \\
--restart=always \\
-e LC_ALL="C.UTF-8" \\
-e LANG="C.UTF-8" \\
--network=host \\
-v ${docker_nginx_site}/config/nginx.conf:/usr/local/openresty/nginx/conf/nginx.conf \\
-v ${docker_nginx_site}/config/conf.d/:/etc/nginx/conf.d/ \\
-v ${docker_nginx_site}/ssl/:/data/ssl/ \\
-v ${docker_nginx_site}/lua/:/data/lua/ \\
-v ${docker_nginx_site}/web/:/data/web/ \\
-v ${docker_nginx_site}/res/:/data/res/ \\
-v /data/logs/nginx/:/data/logs/nginx/ \\
-v /etc/localtime:/etc/localtime:ro \\
openresty/openresty
EOF

        cp download_file/api.conf.bak ${docker_nginx_site}/config/conf.d/api.conf.bak
        cp download_file/reload.sh ${docker_nginx_site}/config/conf.d/reload.sh

        cd ${docker_nginx_site}/
        chmod +x ${docker_nginx_site}/setup.sh ${docker_nginx_site}/config/conf.d/reload.sh
        /bin/bash -x ${docker_nginx_site}/setup.sh

        cd ${pwd}

}

# 宿主机安装maven和java17
function install_local_maven_java17(){

        # 安装maven
        cp -R download_file/apache-maven-3.6.3 /usr/local/maven
        export PATH=/usr/local/maven/bin:$PATH
        mv /usr/local/maven/conf/settings.xml /usr/local/maven/conf/settings.xml.bak
        cp download_file/settings.xml /usr/local/maven/conf/settings.xml

        # 安装java17
        cp download_file/jdk-17_linux-x64_bin.tar.gz /usr/local/jdk-17_linux-x64_bin.tar.gz
        cd /usr/local/
        tar -zxvf jdk-17_linux-x64_bin.tar.gz
        mv jdk-*/ java/
        rm -f jdk-17_linux-x64_bin.tar.gz
        cat << EOF >> /etc/profile


# maven
export PATH=/usr/local/maven/bin:\$PATH

# java
export JAVA_HOME=/usr/local/java
export JRE_HOME=\${JAVA_HOME}/jre
export CLASSPATH=.:\${JAVA_HOME}/lib:\${JRE_HOME}/lib
export PATH=\${JAVA_HOME}/bin:\$PATH
EOF

        source /etc/profile
        java -version
        mvn -version

        cd ${pwd}
}

# 安装node.js
function install_nodejs(){
        yum localinstall download_file/rpm/nodejs/*.rpm -y
        node -v
        npm -v

        if [ "${is_mainland}"x == "1"x ];then
                npm config set registry https://registry.npm.taobao.org
        fi

        cd ${pwd}
}

# 安装python3
function install_python3(){
        yum localinstall download_file/rpm/python3/*.rpm -y
        python3 --version
        pip3 --version

        if [ "${is_mainland}"x == "1"x ];then
                pip config set global.index-url https：//pypi.tuna.tsinghua.edu.cn/simple/
        fi

        cd ${pwd}
}

function main(){
        root_need
        echo_initialization
        sleep 3

        if (whiptail --title "#是否关闭防火墙#" --yesno "是否关闭防火墙" --fb 15 70); then
                close_firewall_evn=1
        else
                echo -e "${Red}已跳过安装${Font}"
        fi

        if (whiptail --title "#是否所有程序换源#" --yesno "#是否所有程序换源#" --fb 15 70); then
                is_mainland=1
        else
                echo -e "${Red}已选择不换源${Font}"
        fi

        start

        OPTION=$(whiptail --title "centos7.* 初始化脚本,  made in 2023 by buyfakett" --menu "Choose your option" --ok-button 确认 --cancel-button 退出 20 65 13 \
        "1" "手动选择安装" \
        "2" "一键全部安装（安装docker版本nginx）" \
        "3" "退出" 3>&1 1>&2 2>&3)

        EXITSTATUS=$?

        if [ $EXITSTATUS = 0 ]; then
                case $OPTION in
                1)
                        if (whiptail --title "#是否安装docker#" --yesno "是否安装docker" --fb 15 70); then
                                docker_data_site=$(whiptail --title "#请输入docker位置#" --inputbox "docker默认位置为：/var/lib/docker\n推荐修改！！！！" 10 60 "${docker_data_site}" --ok-button 确认 --cancel-button 取消 3>&1 1>&2 2>&3)
                                install_docker_evn=1
                                if (whiptail --title "#是否开启docker日志发送到本地rsyslog#" --yesno "是否开启rsyslog" --fb 15 70); then
                                        enable_docker_rsyslog=1
                                else
                                        enable_docker_rsyslog=2
                                        echo -e "${Red}已跳过安装${Font}"
                                fi
                        else
                                echo -e "${Red}已跳过安装${Font}"
                        fi

                        NGINX_OPTION=$(whiptail --title "#安装什么版本的nginx/不安装#" --menu "Choose your option" --ok-button 确认 --cancel-button 退出 20 65 13 \
                        "1" "安装docker版本的nginx" \
                        "2" "安装local版本的nginx" \
                        "3" "不安装nginx" \
                        "4" "退出" 3>&1 1>&2 2>&3)

                        NGINX_EXITSTATUS=$?

                        if [ $NGINX_EXITSTATUS = 0 ]; then
                                case $NGINX_OPTION in
                                1)
                                        docker_nginx_site=$(whiptail --title "#请输入docker版nginx位置#" --inputbox "自定义nginx的安装位置" 10 60 "${docker_nginx_site}" --ok-button 确认 --cancel-button 取消 3>&1 1>&2 2>&3)
                                        install_docker_nginx_evn=1
                                        ;;
                                2)
                                        loacl_nginx_site=$(whiptail --title "#请输入本地版nginx位置#" --inputbox "本地版nginx默认位置有点深，推荐创建快捷方式到自己熟系的位置" 10 60 "${loacl_nginx_site}" --ok-button 确认 --cancel-button 取消 3>&1 1>&2 2>&3)
                                        install_local_nginx_evn=1
                                        ;;
                                3)
                                        echo -e "${Red}已跳过安装${Font}"
                                        ;;
                                *)
                                        echo -e "${Red}操作错误${Font}"
                                        ;;
                                esac
                        else
                                exit 0
                        fi

                        if (whiptail --title "#是否安装宿主机版本的maven和java17#" --yesno "是否安装宿主机版本的maven和java17" --fb 15 70); then
                                install_local_maven_java17_evn=1
                        else
                                echo -e "${Red}已跳过安装${Font}"
                        fi

                        if (whiptail --title "#是否安装node.js#" --yesno "是否安装node.js" --fb 15 70); then
                                install_nodejs_evn=1
                        else
                                echo -e "${Red}已跳过安装${Font}"
                        fi

                        if (whiptail --title "#是否安装python3#" --yesno "是否安装python3" --fb 15 70); then
                                install_python3_evn=1
                        else
                                echo -e "${Red}已跳过安装${Font}"
                        fi

                        if (whiptail --title "#是否生成2倍虚拟缓存#" --yesno "是否生成2倍虚拟缓存" --fb 15 70); then
                                add2swap_evn=1
                        else
                                echo -e "${Red}已跳过安装${Font}"
                        fi
                        ;;
                2)
                        install_docker_evn=1
                        enable_docker_rsyslog=1
                        install_docker_nginx_evn=1
                        install_local_maven_java17_evn=1
                        install_nodejs_evn=1
                        install_python3_evn=1
                        add2swap_evn=1
                        ;;
                3)
                        exit 0
                        ;;
                *)
                        echo -e "${Red}操作错误${Font}"
                        ;;
                esac

                setenforce 0

                if [ "${is_mainland}"x == "1"x ];then
                        echo 'Asia/Shanghai' > /etc/timezone
                fi
                
                [ "$close_firewall_evn" ] && close_firewall
                [ "$install_docker_evn" ] && install_docker
                [ "$install_docker_nginx_evn" ] && install_docker_nginx
                [ "$install_local_nginx_evn" ] && install_local_nginx
                [ "$install_local_maven_java17_evn" ] && install_local_maven_java17
                [ "$install_nodejs_evn" ] && install_nodejs
                [ "$install_python3_evn" ] && install_python3
                [ "$add2swap_evn" ] && /bin/bash download_file/add2swap.sh
                
        else
                exit 0
        fi

        rm -f add2swap.sh

        echo -e "${Green}执行完此脚本后，最好执行重启命令，因为关闭了SElinux，需要重启服务器才生效${Font}"


}

Inspection_system