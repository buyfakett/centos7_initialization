#!/bin/bash

# coding:utf-8

# **********************************************************
# * Author        : buyfakett
# * Email         : buyfakett@vip.qq.com
# * Create time   : 2023-1-28
# * Last modified : 2023-9-25
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
# node版本
install_node_version=${install_node_version:-"16"}
# 是否是中国大陆(1:是,2:不是)
is_mainland=${is_mainland:-"1"}
# wget重试次数
wget_retry_number=${wget_retry_number:-"3"}
# 如果$1传一个y就全自动
is_auto_key=$1

# 颜色参数，让脚本更好看
Green="\033[32m"
Font="\033[0m"
Red="\033[31m" 

# 本地脚本版本号
shell_version=v1.7.0
# 远程仓库作者
git_project_author_name=buyfakett
# 远程仓库项目名
git_project_project_name=centos7_initialization
# 远程仓库名
git_project_name=${git_project_author_name}/${git_project_project_name}

# 打印初始化
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

# 检查版本
function is_inspect_script(){
        yum install -y wget jq
        echo -e "${Green}您已开始检查版本${Font}"

        if [ $inspect_script == 1 ];then
                remote_version=$(wget -qO- -t1 -T2 "https://gitee.com/api/v5/repos/${git_project_name}/releases/latest" |  jq -r '.tag_name')
        elif [ $inspect_script == 2 ];then
                remote_version=$(wget -qO- -t1 -T2 "https://api.github.com/repos/${git_project_name}/releases/latest" |  jq -r '.tag_name')
        fi

        if [ ! "${remote_version}"x = "${shell_version}"x ];then
                if [ $inspect_script == 1 ];then
                        bash <( curl -s -S -L "https://gitee.com/${git_project_name}/raw/master/$(basename $0)" )
                elif [ $inspect_script == 2 ];then
                        bash <( curl -s -S -L "https://github.com/${git_project_name}/raw/master/$(basename $0)" )
                fi
        else
                echo -e "${Green}您现在的版本是最新版${Font}"
        fi
}

# 关闭防火墙
function close_firewall(){
        systemctl disable firewalld.service --now
}

# 更新yum包
function update_packages(){
        yum install -y wget whiptail
        cd /etc/yum.repos.d

        if [ "${is_mainland}"x == "1"x ] && [ ${is_auto_key,,}x != 'y'x ];then
                inspect_script_yum=$(whiptail --title "# 是否yum换源 #" --menu "# 是否yum换源 #" --ok-button 确认 --cancel-button 退出 20 65 13 \
                "0" "不换源" \
                "1" "阿里" \
                "2" "网易"\
                "3" "清华大学"\
                "4" "退出" 3>&1 1>&2 2>&3)
                EXITSTATUS_YUM=$?
                if [ $EXITSTATUS_YUM = 0 ]; then
                        case $inspect_script_yum in
                        0)
                                echo -e "${Green}您已选择不换源${Font}"
                                ;;
                        1)
                                mv Centos-Base.repo Centos-Base.repo.bak
                                wget -t ${wget_retry_number} -O Centos-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
                                yum clean all && yum makecache
                                ;;
                        2)
                                mv Centos-Base.repo Centos-Base.repo.bak
                                wget -t ${wget_retry_number} -O Centos-Base.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo
                                yum clean all && yum makecache
                                ;;
                        3)
                                sed -e 's|^mirrorlist=|#mirrorlist=|g' \
                                -e 's|^#baseurl=http://mirror.centos.org|baseurl=https://mirrors.tuna.tsinghua.edu.cn|g' \
                                -i.bak \
                                /etc/yum.repos.d/CentOS-*.repo
                                yum clean all && yum makecache
                                ;;
                        *)
                                echo -e "${Red}操作错误${Font}"
                                ;;
                        esac
                else
                        exit 0
                fi
                wget -t ${wget_retry_number} -O Centos-ali.repo http://mirrors.aliyun.com/repo/Centos-7.repo
                wget -t ${wget_retry_number} -O Centos-qh.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo
        fi
        
        yum install -y yum-utils device-mapper-persistent-data lvm2 tree git bash-completion.noarch \
         chrony lrzsz tar zip unzip gcc-c++ pcre pcre-devel zlib zlib-devel openssl openssl--devel \
         screen tree

        systemctl enable chronyd --now

        yum update -y

        cd ${pwd}
}

# 安装工具
function install_tools(){
        if [ "${is_mainland}"x == "1"x ];then
                [ ! -f add2swap.sh ] && wget -t ${wget_retry_number} https://gitee.com/${git_project_name}/raw/master/download_file/add2swap.sh
        elif [ "${is_mainland}"x == "2"x ];then
                [ ! -f add2swap.sh ] && wget -t ${wget_retry_number} https://github.com/${git_project_name}/raw/master/download_file/add2swap.sh
        fi
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

#         cat << EOF > /etc/yum.repos.d/docker-ce.repo
# [dockerCe]
# name=dockerCe
# baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/7.9/x86_64/stable
# gpgcheck=0
# enabled=1
# EOF
        
        cd /etc/yum.repos.d
        [ ! -f CentOS7-Base-163.repo ] && wget -t ${wget_retry_number} http://mirrors.163.com/.help/CentOS7-Base-163.repo
        [ ! -f Centos-7.repo ] && wget -t ${wget_retry_number} http://mirrors.aliyun.com/repo/Centos-7.repo
        [ ! -f epel-testing.repo ] && wget -t ${wget_retry_number} http://mirrors.aliyun.com/repo/epel-testing.repo
        [ ! -f epel-7.repo ] && wget -t ${wget_retry_number} http://mirrors.aliyun.com/repo/epel-7.repo
        [ ! -f epel.repo ] && wget -t ${wget_retry_number} http://mirrors.aliyun.com/repo/epel.repo
        yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
        cd ${pwd}

        yum makecache
        yum -y install docker-ce docker-ce-cli containerd.io && systemctl enable docker --now

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

        fi

        systemctl restart docker

        if [ "${is_mainland}"x == "1"x ];then
                [ ! -f /usr/local/bin/docker-compose ] && wget -t ${wget_retry_number} https://gitee.com/${git_project_name}/releases/download/v1.2.3/docker-compose -O /usr/local/bin/docker-compose
        elif [ "${is_mainland}"x == "2"x ];then
                [ ! -f /usr/local/bin/docker-compose ] && wget -t ${wget_retry_number} https://github.com/${git_project_name}/releases/download/v1.2.3/docker-compose -O /usr/local/bin/docker-compose
        fi

        chmod +x /usr/local/bin/docker-compose


        cd ${pwd}
}

#安装本地版的nginx
function install_local_nginx(){
        mkdir -p ${local_nginx_site}
        yum install -y yum-utils logrotate

        yum-config-manager --add-repo https://openresty.org/package/centos/openresty.repo
        yum install openresty -y

        ln -s /usr/local/openresty/nginx/conf /root/nginx

        mkdir -p ${local_nginx_site}/conf/conf.d
        mkdir -p ${local_nginx_site}/web
        mkdir -p ${local_nginx_site}/ssl
        mkdir -p ${local_nginx_site}/res
        mkdir -p ${local_nginx_site}/lua
        mkdir -p ${local_nginx_site}/logs
        chmod -R 755 ${local_nginx_site}/logs

        if [ "${is_mainland}"x == "1"x ];then
                [ ! -f /usr/local/openresty/nginx/conf/nginx.conf ] && wget -t ${wget_retry_number} https://gitee.com/${git_project_name}/raw/master/download_file/nginx_local.conf -O /usr/local/openresty/nginx/conf/nginx.conf
                [ ! -f ${local_nginx_site}/conf/conf.d/api.conf.bak ] && wget -t ${wget_retry_number} https://gitee.com/${git_project_name}/raw/master/download_file/api.conf.bak -O ${local_nginx_site}/conf/conf.d/api.conf.bak
                [ ! -f ${local_nginx_site}/conf/conf.d/reload.sh ] && wget -t ${wget_retry_number} https://gitee.com/${git_project_name}/raw/master/download_file/reload_local.sh -O ${local_nginx_site}/conf/conf.d/reload.sh
                [ ! -f ${local_nginx_site}/conf/conf.d/index.conf ] && wget -t ${wget_retry_number} https://gitee.com/${git_project_name}/raw/master/download_file/local_nginx_index.conf -O ${local_nginx_site}/conf/conf.d/index.conf
        elif [ "${is_mainland}"x == "2"x ];then
                [ ! -f /usr/local/openresty/nginx/conf/nginx.conf ] && wget -t ${wget_retry_number} https://github.com/${git_project_name}/raw/master/download_file/nginx_local.conf -O /usr/local/openresty/nginx/conf/nginx.conf
                [ ! -f ${local_nginx_site}/conf/conf.d/api.conf.bak ] && wget -t ${wget_retry_number} https://github.com/${git_project_name}/raw/master/download_file/api.conf.bak -O ${local_nginx_site}/conf/conf.d/api.conf.bak
                [ ! -f ${local_nginx_site}/conf/conf.d/reload.sh ] && wget -t ${wget_retry_number} https://github.com/${git_project_name}/raw/master/download_file/reload_local.sh -O ${local_nginx_site}/conf/conf.d/reload.sh
                [ ! -f ${local_nginx_site}/conf/conf.d/index.conf ] && wget -t ${wget_retry_number} https://github.com/${git_project_name}/raw/master/download_file/local_nginx_index.conf -O ${local_nginx_site}/conf/conf.d/index.conf
        fi

        cat << EOF > ${local_nginx_site}/nginx_log.sh
#!/bin/bash
now_date=\`date -d '-1 day' +%Y-%m-%d\`
cat ${local_nginx_site}/logs/nginx.log > ${local_nginx_site}/logs/nginx-\${now_date}.log && > ${local_nginx_site}/logs/nginx.log
EOF

        cat << EOF > ${local_nginx_site}/gzip_log.sh
#!/bin/bash

for day in 1;
do
find ${local_nginx_site}/logs/ -name nginx-\`date -d "\${day} days ago" +%Y-%m-%d\`*.log -type f -exec gzip {} \;
done
EOF


        cat << EOF > ${local_nginx_site}/del_gz.sh 
#!/bin/bash
find ${local_nginx_site}/logs/ -mtime +30 -name "*.gz" -exec rm -rf {} \;
EOF

        chmod +x ${local_nginx_site}/del_gz.sh ${local_nginx_site}/gzip_log.sh ${local_nginx_site}/nginx_log.sh ${local_nginx_site}/conf/conf.d/reload.sh

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

        if [ "${is_mainland}"x == "1"x ];then
                [ ! -f ${docker_nginx_site}/config/nginx.conf ] && wget -t ${wget_retry_number} https://gitee.com/${git_project_name}/raw/master/download_file/nginx.conf -O ${docker_nginx_site}/config/nginx.conf
        elif [ "${is_mainland}"x == "2"x ];then
                [ ! -f ${docker_nginx_site}/config/nginx.conf ] && wget -t ${wget_retry_number} https://github.com/${git_project_name}/raw/master/download_file/nginx.conf -O ${docker_nginx_site}/config/nginx.conf
        fi

        cat << EOF > ${docker_nginx_site}/setup.sh
docker stop nginx
docker rm nginx

docker run -id \\
--name nginx \\
--restart=always \\
-e LC_ALL="C.UTF-8" \\
-e LANG="C.UTF-8" \\
--network=host \\
-v ./config/nginx.conf:/usr/local/openresty/nginx/conf/nginx.conf \\
-v ./config/conf.d/:/etc/nginx/conf.d/ \\
-v ./ssl/:/data/ssl/ \\
-v ./lua/:/data/lua/ \\
-v ./web/:/data/web/ \\
-v ./res/:/data/res/ \\
-v ./logs/:/data/logs/nginx/ \\
-v /etc/localtime:/etc/localtime:ro \\
openresty/openresty
EOF

        if [ "${is_mainland}"x == "1"x ];then
                [ ! -f ${docker_nginx_site}/config/conf.d/api.conf.bak ] && wget -t ${wget_retry_number} https://gitee.com/${git_project_name}/raw/master/download_file/api.conf.bak -O ${docker_nginx_site}/config/conf.d/api.conf.bak
                [ ! -f ${docker_nginx_site}/config/conf.d/reload.sh ] && wget -t ${wget_retry_number} https://gitee.com/${git_project_name}/raw/master/download_file/reload.sh -O ${docker_nginx_site}/config/conf.d/reload.sh
        elif [ "${is_mainland}"x == "2"x ];then
                [ ! -f ${docker_nginx_site}/config/conf.d/api.conf.bak ] && wget -t ${wget_retry_number} https://github.com/${git_project_name}/raw/master/download_file/api.conf.bak -O ${docker_nginx_site}/config/conf.d/api.conf.bak
                [ ! -f ${docker_nginx_site}/config/conf.d/reload.sh ] && wget -t ${wget_retry_number} https://github.com/${git_project_name}/raw/master/download_file/reload.sh -O ${docker_nginx_site}/config/conf.d/reload.sh
        fi

        cd ${docker_nginx_site}/
        chmod +x ${docker_nginx_site}/setup.sh ${docker_nginx_site}/config/conf.d/reload.sh
        /bin/bash -x ${docker_nginx_site}/setup.sh

        cd ${pwd}

}

# 宿主机安装maven和java17
function install_local_maven_java17(){
        cd /usr/local/

        # 安装maven
        if [ "${is_mainland}"x == "1"x ];then
                [ ! -f /usr/local/apache-maven-3.6.3-bin.zip ] && wget -t ${wget_retry_number} https://gitee.com/${git_project_name}/releases/download/v1.2.3/apache-maven-3.6.3-bin.zip -O /usr/local/apache-maven-3.6.3-bin.zip
        elif [ "${is_mainland}"x == "2"x ];then
                [ ! -f usr/local/apache-maven-3.6.3-bin.zip ] && wget -t ${wget_retry_number} https://github.com/${git_project_name}/releases/download/v1.2.3/apache-maven-3.6.3-bin.zip -O /usr/local/apache-maven-3.6.3-bin.zip
        fi
        unzip apache-maven-3.6.3-bin.zip
        rm -f apache-maven-3.6.3-bin.zip
        mv apache-maven-3.6.3 maven
        export PATH=/usr/local/maven/bin:$PATH
        mv /usr/local/maven/conf/settings.xml /usr/local/maven/conf/settings.xml.bak
        if [ "${is_mainland}"x == "1"x ];then
                [ ! -f /usr/local/maven/conf/settings.xml ] && wget -t ${wget_retry_number} https://gitee.com/${git_project_name}/releases/download/v1.2.3/settings.xml -O /usr/local/maven/conf/settings.xml
        elif [ "${is_mainland}"x == "2"x ];then
                [ ! -f /usr/local/maven/conf/settings.xml ] && wget -t ${wget_retry_number} https://github.com/${git_project_name}/releases/download/v1.2.3/settings.xml -O /usr/local/maven/conf/settings.xml
        fi

        # 安装java17
        [ ! -f /usr/local/jdk-17_linux-x64_bin.tar.gz ] && wget -t ${wget_retry_number} https://download.oracle.com/java/17/latest/jdk-17_linux-x64_bin.tar.gz -O /usr/local/jdk-17_linux-x64_bin.tar.gz
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
        mkdir /usr/local/nodejs
        cd /usr/local/nodejs

        if [ $install_node_version == 10 ];then
                if [ "${is_mainland}"x == "1"x ];then
                        [ ! -f /usr/local/nodejs/node-v10.23.0-linux-x64.tar.xz ] && wget -t ${wget_retry_number} https://gitee.com/${git_project_name}/releases/download/v1.2.3/node-v10.23.0-linux-x64.tar.xz -O /usr/local/nodejs/node-v10.23.0-linux-x64.tar.xz
                elif [ "${is_mainland}"x == "2"x ];then
                        [ ! -f /usr/local/nodejs/node-v10.23.0-linux-x64.tar.xz ] && wget -t ${wget_retry_number} https://github.com/${git_project_name}/releases/download/v1.2.3/node-v10.23.0-linux-x64.tar.xz -O /usr/local/nodejs/node-v10.23.0-linux-x64.tar.xz
                fi
                xz -d node-v10.23.0-linux-x64.tar.xz
                tar xvf node-v10.23.0-linux-x64.tar
                mv node-v10.23.0-linux-x64/ node-10/
        fi

        if [ $install_node_version == 12 ];then
                if [ "${is_mainland}"x == "1"x ];then
                        [ ! -f /usr/local/nodejs/node-v12.4.0-linux-x64.tar.xz ] && wget -t ${wget_retry_number} https://gitee.com/${git_project_name}/releases/download/v1.2.3/node-v12.4.0-linux-x64.tar.xz -O /usr/local/nodejs/node-v12.4.0-linux-x64.tar.xz
                elif [ "${is_mainland}"x == "2"x ];then
                        [ ! -f /usr/local/nodejs/node-v12.4.0-linux-x64.tar.xz ] && wget -t ${wget_retry_number} https://github.com/${git_project_name}/releases/download/v1.2.3/node-v12.4.0-linux-x64.tar.xz -O /usr/local/nodejs/node-v12.4.0-linux-x64.tar.xz
                fi
                xz -d node-v12.4.0-linux-x64.tar.xz
                tar xvf node-v12.4.0-linux-x64.tar
                mv node-v12.4.0-linux-x64/ node-12/
        fi

        if [ $install_node_version == 14 ];then
                if [ "${is_mainland}"x == "1"x ];then
                        [ ! -f /usr/local/nodejs/node-v14.17.1-linux-x64.tar.xz ] && wget -t ${wget_retry_number} https://gitee.com/${git_project_name}/releases/download/v1.2.3/node-v14.17.1-linux-x64.tar.xz -O /usr/local/nodejs/node-v14.17.1-linux-x64.tar.xz
                elif [ "${is_mainland}"x == "2"x ];then
                        [ ! -f /usr/local/nodejs/node-v14.17.1-linux-x64.tar.xz ] && wget -t ${wget_retry_number} https://github.com/${git_project_name}/releases/download/v1.2.3/node-v14.17.1-linux-x64.tar.xz -O /usr/local/nodejs/node-v14.17.1-linux-x64.tar.xz
                fi
                xz -d node-v14.17.1-linux-x64.tar.xz
                tar xvf node-v14.17.1-linux-x64.tar
                mv node-v14.17.1-linux-x64/ node-14/
        fi

        if [ $install_node_version == 16 ];then
                if [ "${is_mainland}"x == "1"x ];then
                        [ ! -f /usr/local/nodejs/node-v16.20.2-linux-x64.tar.xz ] && wget -t ${wget_retry_number} https://gitee.com/${git_project_name}/releases/download/v1.2.3/node-v16.20.2-linux-x64.tar.xz -O /usr/local/nodejs/node-v16.20.2-linux-x64.tar.xz
                elif [ "${is_mainland}"x == "2"x ];then
                        [ ! -f /usr/local/nodejs/node-v16.20.2-linux-x64.tar.xz ] && wget -t ${wget_retry_number} https://github.com/${git_project_name}/releases/download/v1.2.3/node-v16.20.2-linux-x64.tar.xz -O /usr/local/nodejs/node-v16.20.2-linux-x64.tar.xz
                fi
                xz -d node-v16.20.2-linux-x64.tar.xz
                tar xvf node-v16.20.2-linux-x64.tar
                mv node-v16.20.2-linux-x64/ node-16/
        fi

        rm -f node-v*.tar.xz && rm -f node-v*.tar

        cat << EOF >> /etc/profile


# nodejs
export NODEJS_HOME=/usr/local/nodejs/node-${install_node_version}
export PATH=\${NODEJS_HOME}/bin:\$PATH
EOF

        source /etc/profile
        node -v
        npm -v

        if [ "${is_mainland}"x == "1"x ];then
                npm config set registry https://registry.npm.taobao.org
        fi

        cd ${pwd}
}

# 安装全部node.js
function install_all_nodejs(){
        mkdir /usr/local/nodejs
        cd /usr/local/nodejs

        if [ "${is_mainland}"x == "1"x ];then
                [ ! -f /usr/local/nodejs/node-v10.23.0-linux-x64.tar.xz ] && wget -t ${wget_retry_number} https://gitee.com/${git_project_name}/releases/download/v1.2.3/node-v10.23.0-linux-x64.tar.xz -O /usr/local/nodejs/node-v10.23.0-linux-x64.tar.xz
        elif [ "${is_mainland}"x == "2"x ];then
                [ ! -f /usr/local/nodejs/node-v10.23.0-linux-x64.tar.xz ] && wget -t ${wget_retry_number} https://github.com/${git_project_name}/releases/download/v1.2.3/node-v10.23.0-linux-x64.tar.xz -O /usr/local/nodejs/node-v10.23.0-linux-x64.tar.xz
        fi
        xz -d node-v10.23.0-linux-x64.tar.xz
        tar xvf node-v10.23.0-linux-x64.tar
        mv node-v10.23.0-linux-x64/ node-10/

        if [ "${is_mainland}"x == "1"x ];then
                [ ! -f /usr/local/nodejs/node-v12.4.0-linux-x64.tar.xz ] && wget -t ${wget_retry_number} https://gitee.com/${git_project_name}/releases/download/v1.2.3/node-v12.4.0-linux-x64.tar.xz -O /usr/local/nodejs/node-v12.4.0-linux-x64.tar.xz
        elif [ "${is_mainland}"x == "2"x ];then
                [ ! -f /usr/local/nodejs/node-v12.4.0-linux-x64.tar.xz ] && wget -t ${wget_retry_number} https://github.com/${git_project_name}/releases/download/v1.2.3/node-v12.4.0-linux-x64.tar.xz -O /usr/local/nodejs/node-v12.4.0-linux-x64.tar.xz
        fi
        xz -d node-v12.4.0-linux-x64.tar.xz
        tar xvf node-v12.4.0-linux-x64.tar
        mv node-v12.4.0-linux-x64/ node-12/

        if [ "${is_mainland}"x == "1"x ];then
                [ ! -f /usr/local/nodejs/node-v14.17.1-linux-x64.tar.xz ] && wget -t ${wget_retry_number} https://gitee.com/${git_project_name}/releases/download/v1.2.3/node-v14.17.1-linux-x64.tar.xz -O /usr/local/nodejs/node-v14.17.1-linux-x64.tar.xz
        elif [ "${is_mainland}"x == "2"x ];then
                [ ! -f /usr/local/nodejs/node-v14.17.1-linux-x64.tar.xz ] && wget -t ${wget_retry_number} https://github.com/${git_project_name}/releases/download/v1.2.3/node-v14.17.1-linux-x64.tar.xz -O /usr/local/nodejs/node-v14.17.1-linux-x64.tar.xz
        fi
        xz -d node-v14.17.1-linux-x64.tar.xz
        tar xvf node-v14.17.1-linux-x64.tar
        mv node-v14.17.1-linux-x64/ node-14/

        if [ "${is_mainland}"x == "1"x ];then
                [ ! -f /usr/local/nodejs/node-v16.20.2-linux-x64.tar.xz ] && wget -t ${wget_retry_number} https://gitee.com/${git_project_name}/releases/download/v1.2.3/node-v16.20.2-linux-x64.tar.xz -O /usr/local/nodejs/node-v16.20.2-linux-x64.tar.xz
        elif [ "${is_mainland}"x == "2"x ];then
                [ ! -f /usr/local/nodejs/node-v16.20.2-linux-x64.tar.xz ] && wget -t ${wget_retry_number} https://github.com/${git_project_name}/releases/download/v1.2.3/node-v16.20.2-linux-x64.tar.xz -O /usr/local/nodejs/node-v16.20.2-linux-x64.tar.xz
        fi
        xz -d node-v16.20.2-linux-x64.tar.xz
        tar xvf node-v16.20.2-linux-x64.tar
        mv node-v16.20.2-linux-x64/ node-16/


        rm -f node-v*.tar.xz && rm -f node-v*.tar

        cat << EOF >> /etc/profile


# nodejs
export NODEJS_HOME=/usr/local/nodejs/node-16
export PATH=\${NODEJS_HOME}/bin:\$PATH
EOF

        source /etc/profile
        node -v
        npm -v

        if [ "${is_mainland}"x == "1"x ];then
                npm config set registry https://registry.npm.taobao.org
        fi

        cd ${pwd}
}

# 安装python3
function install_python3(){
        yum install -y epel-release python3 python3-devel
        python3 --version
        pip3 --version

        if [ "${is_mainland}"x == "1"x ];then
                pip config set global.index-url https：//pypi.tuna.tsinghua.edu.cn/simple/
        fi

        cd ${pwd}
}

function main(){
        if [ ${is_auto_key,,}x != 'y'x ]; then
                root_need

                inspect_script=$(whiptail --title "是否检查脚本" --menu "Choose your option" --ok-button 确认 --cancel-button 退出 20 65 13 \
                "0" "gitee" \
                "1" "github" \
                "2" "不检查更新"\
                "3" "退出" 3>&1 1>&2 2>&3)
                EXITSTATUS=$?
                if [ $EXITSTATUS = 0 ]; then
                        case $inspect_script in
                        0|1)
                                is_inspect_script
                                ;;
                        2)
                                echo -e "${Green}已跳过检查更新${Font}"
                                ;;               
                        3)
                                exit 0
                                ;;
                        *)
                                echo -e "${Red}操作错误${Font}"
                                ;;
                        esac
                else
                        exit 0
                fi

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
                        is_mainland=2
                        echo -e "${Red}已选择不换源${Font}"
                fi

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
                                                local_nginx_site=$(whiptail --title "#请输入本地版nginx位置#" --inputbox "本地版nginx默认位置有点深，推荐创建快捷方式到自己熟系的位置" 10 60 "${local_nginx_site}" --ok-button 确认 --cancel-button 取消 3>&1 1>&2 2>&3)
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
                                        NODE_OPTION=$(whiptail --title "#是否安装全版本的node.js#" --menu "是否安装全版本的node.js" --ok-button 确认 --cancel-button 退出 20 65 13 \
                                                "1" "安装指定版本" \
                                                "2" "安装全部版本(默认使用16)" \
                                                "3" "退出" 3>&1 1>&2 2>&3)

                                                NODE_EXITSTATUS=$?

                                                if [ $NODE_EXITSTATUS = 0 ]; then
                                                        case $NODE_OPTION in
                                                        1)
                                                                install_node_version=$(whiptail --title "#请输入需要安装的node.js的版本#" --inputbox "支持10,12,14,16,18" 10 60 "${install_node_version}" --ok-button 确认 --cancel-button 取消 3>&1 1>&2 2>&3)
                                                                install_nodejs_evn=1
                                                                ;;
                                                        2)
                                                                install_all_nodejs_evn=1
                                                                ;;
                                                        *)
                                                                echo -e "${Red}操作错误${Font}"
                                                                ;;
                                                        esac
                                                else
                                                        exit 0
                                                fi

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
                                close_firewall_evn=1
                                install_docker_evn=1
                                enable_docker_rsyslog=1
                                install_docker_nginx_evn=1
                                install_local_maven_java17_evn=1
                                install_all_nodejs_evn=1
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
                        update_packages
                        install_tools

                        if [ "${is_mainland}"x == "1"x ];then
                                echo 'Asia/Shanghai' > /etc/timezone
                        fi

                        [ "$close_firewall_evn" ] && close_firewall && echo -e "\n${Green}关闭防火墙成功${Font}\n"
                        [ "$install_docker_evn" ] && install_docker && echo -e "\n${Green}安装docker成功${Font}\n"
                        [ "$install_docker_nginx_evn" ] && install_docker_nginx && echo -e "\n${Green}安装docker版nginx成功${Font}\n"
                        [ "$install_local_nginx_evn" ] && install_local_nginx && echo -e "\n${Green}安装本地版nginx成功${Font}\n"
                        [ "$install_local_maven_java17_evn" ] && install_local_maven_java17 && echo -e "\n${Green}安装java和maven成功${Font}\n"
                        [ "$install_nodejs_evn" ] && install_nodejss && echo -e "\n${Green}安装nodejs成功${Font}\n"
                        [ "$install_all_nodejs_evn" ] && install_all_nodejs && echo -e "\n${Green}安装全部nodejs成功${Font}\n"
                        [ "$install_python3_evn" ] && install_python3 && echo -e "\n${Green}安装python3成功${Font}\n"
                        [ "$add2swap_evn" ] && /bin/bash add2swap.sh && echo -e "\n${Green}添加2倍虚拟内存成功${Font}\n"
                        
                else
                        exit 0
                fi

                rm -f add2swap.sh

                echo -e "${Green}执行完此脚本后，最好执行重启命令，因为关闭了SElinux，需要重启服务器才生效${Font}"
        else
                enable_docker_rsyslog=1
                setenforce 0
                update_packages && echo -e "\n${Green}更新包成功${Font}\n"
                install_tools && echo -e "\n${Green}下载工具成功${Font}\n"
                close_firewall && echo -e "\n${Green}关闭防火墙成功${Font}\n"
                install_docker && echo -e "\n${Green}安装docker成功${Font}\n"
                install_docker_nginx && echo -e "\n${Green}安装docker版nginx成功${Font}\n"
                install_local_maven_java17 && echo -e "\n${Green}安装java和maven成功${Font}\n"
                install_all_nodejs && echo -e "\n${Green}安装全部nodejs成功${Font}\n"
                install_python3 && echo -e "\n${Green}安装python3成功${Font}\n"
                /bin/bash add2swap.sh && echo -e "\n${Green}添加2倍虚拟内存成功${Font}\n"
                echo -e "${Green}脚本执行完成${Font}"
        fi

}

Inspection_system