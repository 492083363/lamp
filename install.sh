#!/bin/bash
# ┌───────────────────────────────────────────────────────┐
# │Script Name | install.sh                    ▮▮▮▮▮▮▮▮   │
# │Date        | 2017-08-04                       ▮▮      │
# │Author      | Yu Longjun                  ▮▮▮▮▮▮▮▮▮▮▮▮ │
# │Blog        | http://www.yulongnjun.com        ▮▮      │
# │Version     | 1.0                           ▮▮▮▮▮      │
# │Description | LNMP Install Script              ▮▮      │
# └───────────────────────────────────────────────────────┘
#

# 安装必需的yum包
yum groupinstall -y "Development Tools"
yum install -y pcre-devel openssl-devel expat-devel libxml2-devel  # 都是编译安装时候需要的依赖包
yum remove -y apr  # 装Development Tools包组的时候，装了旧版本的apr和apr-util了，后续需要装apr-1.6.2和apr-util-1.6.0，所以卸载掉旧版本apr。apr-util会自动一起卸载掉。

# 校验源码包
echo "============================="
echo "开始校验源码包……"
cd src
sha1sum -c shasums
[ $? -eq 0 ] && echo "校验成功。" || (echo "校验失败，请检查源码包完整性。"&& exit 1)
echo "============================="

# 解压源码包
echo "开始解压源码包……"
for pkg in `ls *.bz2`;do
    echo "解压 $pkg ……"
    tar -xf $pkg
    echo "解压 $pkg 完毕。"
done
echo "============================="

# 移动apr和apr-util到httpd目录，和httpd一起编译安装，并且启动httpd服务
mv -v apr-1.6.2 httpd-2.4.27/srclib/apr
mv -v apr-util-1.6.0 httpd-2.4.27/srclib/apr-util
cd httpd-2.4.27
mkdir -v build1
cd build1
../configure --prefix=/usr/local/httpd24 \
    --enable-mods-shared=most   \
    --enable-headers            \
    --enable-mime-magic         \
    --enable-proxy              \
    --enable-so                 \
    --enable-rewrite            \
    --with-ssl                  \
    --enable-ssl                \
    --enable-deflate            \
    --with-pcre                 \
    --with-included-apr         \
    --with-apr-util             \
    --enable-mpms-shared=all    \
    --with-mpm=prefork          \
    --enable-remoteip


make && make install
# 加到PATH变量里去
cat >/etc/profile.d/httpd.sh<<EOF
export PATH=/usr/local/httpd24/bin:$PATH
EOF
echo "启动apache..."
/usr/local/httpd24/bin/apachectl
ss -tnl |grep ":80\>" >/dev/null
[ $? -eq 0 ] && echo "apache启动成功。" || (echo "apache启动失败" && exit 1)
echo "============================="

# yum 安装mariadb 10.2, 需要联网
echo "安装mariadb 10.2……"
cd ../../..
\cp -f MariaDB.repo /etc/yum.repos.d/
yum install -y MariaDB-server MariaDB-client
echo "安装完毕。"
echo "设置开机启动服务，并实时启动MariaDB..."
systemctl enable mariadb
systemctl start mariadb
[ $? -eq 0 ] && echo "MariaDB启动成功。" || (echo "MariaDB启动失败。" && exit 1)
echo "============================="

# 编译安装PHP 7.1
yum -y install libxml2-devel bzip2-devel libmcrypt-devel libicu-devel libxslt-devel
cd src/php*
mkdir build1
cd build1
../configure --prefix=/usr/local/php                            \
             --with-config-file-path=/usr/local/php/etc         \
             --with-config-file-scan-dir=/usr/local/php/conf.d  \
             --with-apxs2=/usr/local/httpd24/bin/apxs           \
    	     --enable-mysqlnd				                	\
             --with-mysqli=mysqlnd                              \
             --with-pdo-mysql=mysqlnd                           \
             --with-freetype-dir                                \
             --with-jpeg-dir                                    \
             --with-png-dir                                     \
             --with-zlib                                        \
             --with-libxml-dir=/usr                             \
             --enable-xml                                       \
             --enable-bcmath                                    \
             --enable-shmop                                     \
             --enable-sysvsem                                   \
             --enable-inline-optimization                       \
             --enable-mbregex                                   \
             --enable-mbstring                                  \
             --enable-intl                                      \
             --enable-pcntl                                     \
             --with-mcrypt                                      \
             --enable-ftp                                       \
             --with-openssl                                     \
             --with-mhash                                       \
             --enable-pcntl                                     \
             --enable-sockets                                   \
             --with-xmlrpc                                      \
             --enable-zip                                       \
             --enable-soap                                      \
             --with-gettext                                     \
             --disable-fileinfo                                 \
             --enable-opcache                                   \
             --with-xsl
make && make install
libtool --finish libs
echo "复制php.ini……"
mkdir -p /usr/local/php/{etc,conf.d}
\cp ../php.ini-production /usr/local/php/etc/php.ini
s#pm.max_children.*#pm.max_children = 20#
sed -i 's#DirectoryIndex index.html#DirectoryIndex index.php index.html#' /usr/local/httpd24/conf/httpd.conf
sed -i '/AddType application\/x-gzip .gz .tgz/a\    AddType application/x-httpd-php .php\n    AddType application/x-httpd-php-source .phps' /usr/local/httpd24/conf/httpd.conf
/usr/local/httpd24/bin/apachectl restart
[ $? -eq 0 ] && echo "apache启动成功。" || (echo "apache启动失败" && exit 1)

# 测试LAMP

cd ../../..

cp -v test.php /usr/local/httpd24/htdocs/
/usr/local/httpd24/bin/apachectl restart
curl 127.0.0.1/test.php
rm -rf /usr/local/httpd24/htdocs/test.php
