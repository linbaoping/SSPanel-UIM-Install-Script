#!/bin/bash

# 检查是否以root用户身份运行脚本
if [[ $EUID -ne 0 ]]; then
    echo "请以root用户身份运行该脚本。"
    exit 1
fi

# 停止并卸载SSPanel UIM
systemctl stop nginx
systemctl stop php-fpm
systemctl stop mariadb

systemctl disable nginx
systemctl disable php-fpm
systemctl disable mariadb

rm -rf /var/www/html/sspanel

# 卸载软件包
yum -y remove nginx
yum -y remove php php-fpm php-mysql php-mbstring php-xml php-gd php-json
yum -y remove mariadb-server mariadb

# 清理残留文件和配置
rm -rf /etc/nginx/conf.d/sspanel.conf
rm -rf /etc/php.ini
rm -rf /etc/my.cnf.d/sspanel.cnf
rm -rf /etc/my.cnf.d/server.cnf
rm -rf /var/lib/mysql
rm -rf /var/log/nginx
rm -rf /var/log/php-fpm

echo "卸载完成！"

