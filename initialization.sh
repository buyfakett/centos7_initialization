#!/bin/bash

pwd=$(pwd)
# docker位置
docker_data="/data/data-docker"

# 颜色参数，让脚本更好看
Green="\033[32m"
Font="\033[0m"
Red="\033[31m" 

# 本地脚本版本号
shell_version=v1.3.3
# 远程仓库作者
git_project_author_name=buyfakett
# 远程仓库项目名
git_project_project_name=centos7_initialization
# 远程仓库名
git_project_name=${git_project_author_name}/${git_project_project_name}

# 打印帮助文档
function echo_help(){
    echo -e "${Green}
    ——————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
    # 脚本是为了初始化centos7而准备的
    # 本脚本集成了关闭防火墙、换源、更新yum包、docker、nginx、maven、java17、node.js、生成两倍虚拟内存
    # 脚本不是很成熟，有bug请及时在github反馈哦~
    # 或者发作者邮箱：buyfakett@vip.qq.com
    ——————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
    ${Font}"
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
        systemctl stop firewalld.service
        systemctl disable firewalld.service
}

# 更新yum包
function update(){
        yum install -y wget whiptail
        cd /etc/yum.repos.d

        inspect_script_yum=$(whiptail --title "是否换源" --menu "Choose your option" --ok-button 确认 --cancel-button 退出 20 65 13 \
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
                        wget -O Centos-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
                        yum clean all && yum makecache
                        ;;
                2)
                        mv Centos-Base.repo Centos-Base.repo.bak
                        wget -O Centos-Base.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo
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
        
        yum install -y yum-utils device-mapper-persistent-data lvm2 tree git bash-completion.noarch \
         chrony lrzsz tar zip unzip gcc-c++ pcre pcre-devel zlib zlib-devel openssl openssl--devel

        systemctl enable chronyd
        systemctl start chronyd

        yum update -y

        cd ${pwd}
}

# 安装工具
function install_tools(){
        wget https://gitee.com/${git_project_name}/raw/master/download_file/add2swap.sh
}

# 下载docker
function install_docker(){
        mkdir -p /data/docker
        
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
        sed -i 's/#$ModLoad imtcp/$ModLoad imtcp/g' /etc/rsyslog.conf
        sed -i 's/#$InputTCPServerRun 514/$InputTCPServerRun 514/g' /etc/rsyslog.conf
        systemctl restart rsyslog

#         cat << EOF > /etc/yum.repos.d/docker-ce.repo
# [dockerCe]
# name=dockerCe
# baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/7.9/x86_64/stable
# gpgcheck=0
# enabled=1
# EOF
        
        cd /etc/yum.repos.d
        [ -f CentOS7-Base-163.repo ] || wget http://mirrors.163.com/.help/CentOS7-Base-163.repo
        [ -f Centos-7.repo ] || wget http://mirrors.aliyun.com/repo/Centos-7.repo
        [ -f epel-testing.repo ] || wget http://mirrors.aliyun.com/repo/epel-testing.repo
        [ -f epel-7.repo ] || wget http://mirrors.aliyun.com/repo/epel-7.repo
        [ -f epel.repo ] || wget http://mirrors.aliyun.com/repo/epel.repo
        yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
        cd ${pwd}

        yum makecache
        yum -y install docker-ce docker-ce-cli containerd.io && systemctl start docker && systemctl enable docker

        cat << EOF > /etc/docker/daemon.json
{
  "registry-mirrors": [
    "https://pee6w651.mirror.aliyuncs.com"
  ],
  "data-root": "${docker_data}",
  "log-driver": "syslog",
  "log-opts": {
    "syslog-address": "tcp://127.0.0.1:514",
    "tag": "docker/{{.Name}},"
   }
}
EOF
        systemctl restart docker

        cat << EOF > /etc/rsyslog.d/rule.conf
\$EscapeControlCharactersOnReceive off
\$template CleanMsgFormat,"%msg:2:$%\n"

\$template docker,"data/logs/docker/%syslogtag:F,44:1%/%\$YEAR%-%\$MONTH%-%\$DAY%.log"
if \$syslogtag contains 'docker' then ?docker;CleanMsgFormat
& ~
EOF
        systemctl restart rsyslog

        systemctl restart docker

        wget https://gitee.com/${git_project_name}/releases/download/v1.2.3/docker-compose -O /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose

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

        cat << EOF >> /var/spool/cron/root
0 12 * * * /bin/sh -x /data/logs/docker/gzip_log.sh
30 12 * * * /bin/sh -x /data/logs/docker/del_gz.sh
EOF
}

# 安装nginx
function install_nginx(){
        mkdir -p /root/nginx/config/conf.d/

        wget https://gitee.com/${git_project_name}/raw/master/download_file/nginx.conf -O /root/nginx/config/nginx.conf

        cat << EOF > /root/nginx/setup.sh
docker run -id \\
--name nginx \\
--restart=always \\
-e LC_ALL="C.UTF-8" \\
-e LANG="C.UTF-8" \\
--network=host \\
-v \$(pwd)/config/nginx.conf:/usr/local/openresty/nginx/conf/nginx.conf \\
-v \$(pwd)/config/conf.d/:/etc/nginx/conf.d/ \\
-v \$(pwd)/ssl/:/etc/nginx/ssl/ \\
-v \$(pwd)/lua/:/etc/nginx/lua/ \\
-v \$(pwd)/web/:/data/web/ \\
-v \$(pwd)/res/:/data/res/ \\
-v \$(pwd)/logs/nginx/:/data/logs/nginx/ \\
-v /etc/localtime:/etc/localtime:ro \\
openresty/openresty
EOF

        wget https://gitee.com/${git_project_name}/raw/master/download_file/api.conf.bak -O /root/nginx/config/conf.d/api.conf.bak
        wget https://gitee.com/${git_project_name}/raw/master/download_file/reload.sh -O /root/nginx/config/conf.d/reload.sh

        cd /root/nginx/
        /bin/bash -x /root/nginx/setup.sh
        cd ${pwd}

}

# 宿主机安装maven和java17
function install_local_maven_java17(){
        cd /usr/local/

        # 安装maven
        wget https://gitee.com/${git_project_name}/releases/download/v1.2.3/apache-maven-3.6.3-bin.zip -O /usr/local/apache-maven-3.6.3-bin.zip
        unzip apache-maven-3.6.3-bin.zip
        rm -f apache-maven-3.6.3-bin.zip
        mv apache-maven-3.6.3 maven
        export PATH=/usr/local/maven/bin:$PATH
        mv /usr/local/maven/conf/settings.xml /usr/local/maven/conf/settings.xml.bak
        wget https://gitee.com/${git_project_name}/releases/download/v1.2.3/settings.xml -O /usr/local/maven/conf/settings.xml
        wget https://gitee.com/buyfakett/centos7_initialization/releases/download/v1.2.3/settings.xml -O /usr/local/maven/conf/settings.xml

        # 安装java17
        wget https://download.oracle.com/java/17/latest/jdk-17_linux-x64_bin.tar.gz -O /usr/local/jdk-17_linux-x64_bin.tar.gz
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
        curl -sL https://rpm.nodesource.com/setup_14.x | bash -
        yum install nodejs
        node -v
        npm -v
}

function main(){
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

        echo_help
        sleep 3

        if (whiptail --title "是否关闭防火墙" --yesno "是否关闭防火墙" --fb 15 70); then
                close_firewall
        else
                echo -e "${Red}已跳过安装${Font}"
        fi

        OPTION=$(whiptail --title "centos7.* 初始化脚本,  made in 2023" --menu "Choose your option" --ok-button 确认 --cancel-button 退出 20 65 13 \
        "1" "手动选择安装" \
        "2" "一键全部安装" \
        "3" "退出" 3>&1 1>&2 2>&3)

        EXITSTATUS=$?

        if [ $EXITSTATUS = 0 ]; then
                case $OPTION in
                1)
                        update
                        install_tools

                        if (whiptail --title "是否安装docker" --yesno "是否安装docker" --fb 15 70); then
                                docker_data=$(whiptail --title "#请输入docker位置#" --inputbox "docker默认位置为：/var/lib/docker\n推荐修改！！！！" 10 60 "${docker_data}" --ok-button 确认 --cancel-button 取消 3>&1 1>&2 2>&3)
                                install_docker
                        else
                                echo -e "${Red}已跳过安装${Font}"
                        fi

                        if (whiptail --title "是否安装docker版本的nginx" --yesno "是否安装docker版本的nginx" --fb 15 70); then
                                install_nginx
                        else
                                echo -e "${Red}已跳过安装${Font}"
                        fi

                        if (whiptail --title "是否安装宿主机版本的maven和java17" --yesno "是否安装宿主机版本的maven和java17" --fb 15 70); then
                                install_local_maven_java17
                        else
                                echo -e "${Red}已跳过安装${Font}"
                        fi

                        if (whiptail --title "是否安装node.js" --yesno "是否安装node.js" --fb 15 70); then
                                install_nodejs
                        else
                                echo -e "${Red}已跳过安装${Font}"
                        fi

                        if (whiptail --title "是否生成2倍虚拟缓存" --yesno "是否生成2倍虚拟缓存" --fb 15 70); then
                                /bin/bash add2swap.sh
                        else
                                echo -e "${Red}已跳过安装${Font}"
                        fi
                        ;;
                2)
                        update
                        install_docker
                        install_tools
                        install_nginx
                        install_local_maven_java17
                        install_nodejs
                        /bin/bash add2swap.sh
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

}

main