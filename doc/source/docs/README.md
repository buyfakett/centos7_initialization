<h1 align="center">centos7_initialization</h1>


<p align="center">
<a href="https://github.com/buyfakett/centos7_initialization/releases"><img alt="releases" src="https://img.shields.io/github/release/buyfakett/centos7_initialization.svg?logo=github&style=flat-square"/></a>
<a href="https://github.com/buyfakett/centos7_initialization/releases"><img alt="downloads" src="https://img.shields.io/github/downloads/buyfakett/centos7_initialization/total?logo=github"/></a>
<a href="https://github.com/buyfakett/centos7_initialization/releases"><img alt="size" src="https://img.shields.io/github/languages/code-size/buyfakett/centos7_initialization?style=flat-square"/></a>
<a href="https://github.com/buyfakett/centos7_initialization"><img alt="badge" src="https://img.shields.io/badge/codacy-S-/total?logo=github"/></a>
</p>



Chinese name: Script for initializing centos7

[Docs](README.md)|[中文文档](README.zh-cn.md)
### Question


If it cannot be executed, please execute it


```Bash
Vim script name

: set ff=unix

: x
```

### Install Network Version


You can directly execute the following command


```Bash
# Method 1 (recommended)
wget https://gitee.com/buyfakett/centos7_initialization/raw/beta/initialization.sh && bash initialization.sh
```

```Bash
# Method 2
curl -LO "$(curl -sL https://gitee.com/api/v5/repos/buyfakett/centos7_initialization/releases/latest | grep -oE 'https://[^"]+/initialization.sh')" && bash initialization.sh
```

```Bash
# Method 3: Clone to local
git clone https://gitee.com/buyfakett/centos7_initialization.git && cd centos7_initialization && bash initialization.sh
```


### Install local version


```Bash
# Method 1: Download the compressed package from the distribution and install it (the distribution only works on GitHub)
https://github.com/buyfakett/centos7_initialization/releases
```

```Bash
# Method 2: Clone to local
git clone https://github.com/buyfakett/centos7_initialization.git && cd centos7_initialization && bash initialization_local.sh
```


### Support installation of test versions


If you need to use a test version of the script, please use the beta branch


```Bash
wget https://gitee.com/buyfakett/centos7_initialization/raw/beta/initialization.sh && bash initialization.sh
```


Or you may need to clone the specified branch


```Bash
git clone -b beta https://gitee.com/buyfakett/centos7_initialization.git && cd centos7_initialization && bash initialization.sh
```


### Support


1. [Star] He, let him see that you love him;


2. [Watching] He constantly perceives his dynamics;


3. [Fork] He added new features, fixed bugs, and made him more comfortable;


4. [Issue] He, tell him what kind of temper tantrums he has, and he will change them, manual lamb;


5. [Reward] He, buy him a jk;


### Contribution Guidelines


Modify or open a new branch on the development branch


### Other


The script is not very mature, please provide timely feedback on Github if there are any bugs~or send the author's email: buyfakett@vip.qq.com


If you think the author's writing is good, you can support the author and invite him to have a cup of coffee~

| alipay                                                       | wechat                                                         |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| ![alipay](./pay_img/wechat.webp) | ![wechat](./pay_img/ali.webp) |
