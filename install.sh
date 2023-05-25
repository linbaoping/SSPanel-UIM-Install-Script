#!/bin/bash

# 安装依赖软件包
yum -y install epel-release
yum -y install wget curl tar unzip

# 获取本地IP地址
ip_address=$(hostname -I | awk '{print $1}')

# 获取用户输入的配置信息
read -p "请输入后端数据库名称：" db_name
read -p "请输入后端数据库密码：" db_password
read -p "请输入后端域名（使用本地IP地址：$ip_address）：" backend_domain
read -p "请输入后端端口号：" backend_port
read -p "请输入前端登录用户名：" frontend_username
read -p "请输入前端登录密码：" frontend_password

# 安装MySQL
yum -y install mariadb-server mariadb
systemctl start mariadb
systemctl enable mariadb

# 配置MySQL
mysql_secure_installation <<EOF

y
$db_password
$db_password
y
y
y
y
EOF

# 安装Nginx
yum -y install nginx
systemctl start nginx
systemctl enable nginx

# 安装PHP和相关扩展
yum -y install php php-fpm php-mysql php-mbstring php-xml php-gd php-json

# 配置PHP-FPM
sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php.ini
systemctl start php-fpm
systemctl enable php-fpm

# 下载SSPanel UIM
cd /var/www/html
wget https://github.com/Anankke/SSPanel-Uim/archive/refs/heads/dev.zip
unzip dev.zip
mv SSPanel-Uim-dev sspanel
rm dev.zip

# 配置SSPanel UIM后端
cd sspanel
cp .env.example .env
sed -i "s/DB_DATABASE=.*/DB_DATABASE=$db_name/" .env
sed -i "s/DB_USERNAME=.*/DB_USERNAME=root/" .env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$db_password/" .env
sed -i "s/APP_URL=.*/APP_URL=http:\/\/$backend_domain:$backend_port/" .env

# 配置SSPanel UIM前端
sed -i "s/const APP_NAME = 'SSPanel UIM';/const APP_NAME = 'SSPanel UIM';\nconst FRONTEND_USERNAME = '$frontend_username';/" resources/lang/en/app.php

# 设置文件权限
chown -R nginx:nginx /var/www/html/sspanel
chmod -R 755 /var/www/html/sspanel/storage

# 配置Nginx虚拟主机
cat > /etc/nginx/conf.d/sspanel.conf <<EOF
server {
    listen 80;
    server_name $backend_domain;

    root /var/www/html/sspanel/public;
    index index.php;

    location / {
        try_files \$uri \$uri/ /index.php\$is_args\$args;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php-fpm/php-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF

# 重启Nginx
systemctl restart nginx

echo "安装完成！请访问 http://$backend_domain:$backend_port 进行配置。"
