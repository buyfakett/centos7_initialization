#!/bin/bash
####################################################参数修改开始########################################################################

#检查版本（0是不检查；1是检测gitee；2是检测github）
inspect_script=1
#是否全部执行（y为全部执行）
if_all=n

####################################################参数修改结束########################################################################

flag=n
pwd=$(pwd)

#颜色参数，让脚本更好看
Green="\033[32m"
Font="\033[0m"
Red="\033[31m" 

#本地脚本版本号
shell_version=v1.0.1
#远程仓库作者
git_project_author_name=buyfakett
#远程仓库项目名
git_project_project_name=centos7_initialization
#远程仓库名
git_project_name=${git_project_author_name}/${git_project_project_name}

#打印帮助文档
function echo_help(){
    echo -e "${Green}
    ——————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
    #脚本是为了初始化centos7而准备的
    #脚本不是很成熟，有bug请及时在github反馈哦~
    #或者发作者邮箱：buyfakett@vip.qq.com
    ——————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
    ${Font}"
}

#root权限
function root_need(){
    if [[ $EUID -ne 0 ]]; then
        echo -e "${Red}你现在不是root权限，请使用sudo命令或者联系网站管理员${Font}"
        exit 1
    fi
}

#检查版本
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
            bash <( curl -s -S -L "https://gitee.com/${git_project_name}/releases/download/${remote_version}/$(basename $0)" )
        elif [ $inspect_script == 2 ];then
            bash <( curl -s -S -L "https://github.com/${git_project_name}/releases/download/${remote_version}/$(basename $0)" )
        fi
    else
        echo -e "${Green}您现在的版本是最新版${Font}"
    fi
}

#检测输入封装的方法
function judge(){
        read -p "输入y继续:" para

        case $para in 
                [yY])
                        flag=y
                        ;;
                [nN])
                        flag=n
                        ;;
                *)
                        echo "输入不对,请重新输入"
                        judge
        esac  
}

#更新yum包
function update(){
        yum install -y wget
        cd /etc/yum.repos.d
        clear
        echo -e "${Green}
0:不换源
1:阿里
2:网易
3:清华大学
        ${Font}"
        read -p "是否换源:" para
        case $para in 
                0)
                        echo -e "您已选择不换源"
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
                        echo "输入不对,请重新输入"
                        update
        esac
        yum install -y yum-utils device-mapper-persistent-data lvm2 tree
        yum update -y

        cd ${pwd}
}

#安装工具
function install_tools(){
        wget https://gitee.com/buyfakett/script/raw/main/tools/swap.sh
}

#下载docker
function install_docker(){
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
        sed -i 's/#$ModLoad imtcp/$ModLoad imtcp/g' /etc/rsyslog.conf
        sed -i 's/#$InputTCPServerRun 514/$InputTCPServerRun 514/g' /etc/rsyslog.conf
        systemctl restart rsyslog

        cat << EOF > /etc/yum.repos.d/docker-ce.repo
[dockerCe]
name=dockerCe
baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/7.9/x86_64/stable
gpgcheck=0
enabled=1
EOF
        yum makecache
        yum -y install docker-ce docker-ce-cli containerd.io && systemctl start docker && systemctl enable docker

        cat << EOF > /etc/docker/daemon.json
{
  "registry-mirrors": [
    "https://pee6w651.mirror.aliyuncs.com"
  ],
  "data-root": "/data/data-docker",
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

curl -L https://get.daocloud.io/docker/compose/releases/download/1.25.1/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
}

#全部执行（不用输入y）
function all(){
        update
        install_docker
}

#需要手动确认
function not_all(){
        update
        install_tools
        echo -e "${Green}是否安装docker${Font}"
        judge
        if [[ "$flag"x == "y"x ]];then
                install_docker
                flag=n
        fi
}

function main(){
        root_need
        if [ ! $inspect_script == 0 ];then
                is_inspect_script
        else
                echo -e "${Green}您已跳过检查版本${Font}"
        fi

        echo_help
        [ "$if_all"x == "y"x ] && all || not_all

        install_tools
        echo -e "${Green}是否生成虚拟缓存${Font}"
        judge
        if [[ "$flag"x == "y"x ]];then
                /bin/bash swap.sh
                flag=n
        fi
}

main