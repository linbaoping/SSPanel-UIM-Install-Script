#!/bin/bash

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo "请以root用户或使用sudo来运行脚本。"
    exit
fi

# 获取系统的IP地址
ip_address=$(curl -s https://api.ipify.org)

# 安装必要的软件和工具
echo "正在安装必要的软件和工具..."
yum install -y epel-release
yum install -y httpd mariadb-server php php-mysql git

# 配置和启动Web服务器（LAMP堆栈）
echo "正在配置和启动Web服务器..."
systemctl start httpd
systemctl enable httpd

# 配置数据库
echo "正在配置数据库..."
systemctl start mariadb
systemctl enable mariadb
mysql_secure_installation <<EOF

y
your_mysql_root_password
your_mysql_root_password
y
y
y
y
EOF

# 克隆SSPanel-Uim项目
echo "正在克隆SSPanel-Uim项目..."
cd /var/www/html/ || exit
git clone https://github.com/Anankke/SSPanel-Uim.git

# 配置和安装SSPanel-Uim
echo "正在配置和安装SSPanel-Uim..."
cd SSPanel-Uim || exit
cp .env.example .env
composer install --no-dev
php artisan key:generate
php artisan migrate --seed

# 配置Web服务器
echo "正在配置Web服务器..."
echo "<VirtualHost *:8888>
    ServerName $ip_address
    DocumentRoot /var/www/html/SSPanel-Uim/public
    <Directory /var/www/html/SSPanel-Uim/public>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>" > /etc/httpd/conf.d/sspanel.conf

systemctl restart httpd

# 完成安装
echo "SSPanel-Uim已成功安装！"
echo "请在浏览器中访问 http://$ip_address:8888 ，按照向导完成设置。"
