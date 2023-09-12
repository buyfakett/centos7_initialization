<h1 align="center">centos7_initialization</h1>


<p align="center">
<a href="https://github.com/buyfakett/centos7_initialization/releases"><img alt="releases" src="https://img.shields.io/github/release/buyfakett/centos7_initialization.svg?logo=github&style=flat-square"/></a>
<a href="https://github.com/buyfakett/centos7_initialization/releases"><img alt="downloads" src="https://img.shields.io/github/downloads/buyfakett/centos7_initialization/total?logo=github"/></a>
<a href="https://github.com/buyfakett/centos7_initialization/releases"><img alt="size" src="https://img.shields.io/github/languages/code-size/buyfakett/centos7_initialization?style=flat-square"/></a>
<a href="https://github.com/buyfakett/centos7_initialization"><img alt="badge" src="https://img.shields.io/badge/codacy-S-/total?logo=github"/></a>
</p>


中文名：初始化centos7用的脚本

* [问题](#问题)

* [安装网络版本](#安装网络版本)

* [安装本地版本](#安装本地版本)

* [安装测试版本](#安装测试版本)
* [支持](#支持)

### 问题

如果遇到执行不了请执行 

```bash
vim 脚本名

:set ff=unix

:x
```
### 安装网络版本

可以使用以下命令直接执行

```bash
# 方法1（推荐）
wget https://gitee.com/buyfakett/centos7_initialization/raw/beta/initialization.sh && bash initialization.sh
```
```bash
# 方法2
curl -LO "$(curl -sL https://gitee.com/api/v5/repos/buyfakett/centos7_initialization/releases/latest | grep -oE 'https://[^"]+/initialization.sh')" && bash initialization.sh
```
```bash
# 方法3：克隆到本地
git clone https://gitee.com/buyfakett/centos7_initialization.git && cd centos7_initialization && bash initialization.sh
```

### 安装本地版本

```bash
# 方法1：在发行版下载压缩包，安装（发行版只在github）
https://github.com/buyfakett/centos7_initialization/releases
```
```bash
# 方法2：克隆到本地
git clone https://github.com/buyfakett/centos7_initialization.git && cd centos7_initialization && bash initialization_local.sh
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

1. 【Star】他，让他看到你是爱他的；
2. 【Watching】他，时刻感知他的动态；
3. 【Fork】他，为他增加新功能，修Bug，让他更加卡哇伊；
4. 【Issue】他，告诉他有哪些小脾气，他会改的，手动小绵羊；
5. 【打赏】他，为他买jk；

脚本不是很成熟，有bug请及时在github反馈哦~ 或者发作者邮箱：buyfakett@vip.qq.com

觉得作者写的不错的话可以支持一下作者，请作者喝一杯咖啡哦~

| 支付宝                                                       | 微信                                                         |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| ![alipay](./pay_img/wechat.webp) | ![wechat](./pay_img/ali.webp) |
