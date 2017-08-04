# LAMP 一键安装脚本

LAMP各组件版本：

* L：CentOS 7.3
* A：httpd 2.4.27
* M：MariaDB 10.2.7
* P：PHP 7.1.7

## git方式安装(recommended)：

```
git clone https://github.com/yulongjun/lamp.git
cd lamp
bash install.sh
```
## curl方式安装：

```bash
curl -L http://ou5hkxl8l.bkt.clouddn.com/lamp-web-installer |bash
```

> 用的七牛云存储，域名备案中，暂时下载速度不快，只有100KB左右。（MariaDB除外，用的清华的yum源）
