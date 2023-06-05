#  centos7_initialization

![GitHub release](https://img.shields.io/github/release/buyfakett/centos7_initialization.svg?logo=github&style=flat-square) ![GitHub release downloads](https://img.shields.io/github/downloads/buyfakett/centos7_initialization/total?logo=github) ![codacy](https://img.shields.io/badge/codacy-S-/total?logo=github) 

初始化centos7用的脚本

* [问题](#问题)

* [安装](#安装)

* [安装测试版本](#安装测试版本)
* [支持](#支持)

### 问题

如果遇到执行不了请执行 

```bash
vim 脚本名

:set ff=unix

:x
```
### 安装

可以使用以下命令直接执行

```bash
# 方法1
curl -LO "$(curl -sL https://gitee.com/api/v5/repos/buyfakett/centos7_initialization/releases/latest | grep -oE 'https://[^"]+/initialization.sh')" && bash initialization.sh

# 方法2
wget https://gitee.com/buyfakett/centos7_initialization/raw/beta/initialization.sh && bash initialization.sh

# 方法3：克隆到本地
git clone https://gitee.com/buyfakett/centos7_initialization.git && cd centos7_initialization && bash initialization.sh
```

### 支持安装测试版本

如果需要使用测试版本的脚本，请使用beta分支

```bash
wget https://gitee.com/buyfakett/centos7_initialization/raw/beta/initialization.sh && bash initialization.sh
```

或者需要克隆指定分支

```bash
git clone -b beta https://gitee.com/buyfakett/centos7_initialization.git && cd centos7_initialization && bash initialization.sh
```

### 支持

脚本不是很成熟，有bug请及时在github反馈哦~ 或者发作者邮箱：buyfakett@vip.qq.com

觉得作者写的不错的话可以支持一下作者，请作者喝一杯咖啡哦~

![](./pay_img/ali.webp)![](./pay_img/wechat.webp)
