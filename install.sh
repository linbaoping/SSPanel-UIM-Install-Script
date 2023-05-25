#!/bin/bash

# 安装必要的软件和依赖项
yum update -y
yum install -y epel-release
yum install -y nginx php php-fpm php-mysqlnd mysql-server composer git

# 配置Nginx
cat << EOF > /etc/nginx/conf.d/sspanel.conf
server {
    listen 8888;
    server_name _;
    root /path/to/sspanel-uim/public;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php-fpm/php-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF

# 配置MySQL
systemctl start mysqld
systemctl enable mysqld
mysql_secure_installation <<EOF

y
your_mysql_root_password
your_mysql_root_password
y
y
y
y
EOF

# 下载和安装SSPanel-Uim
git clone https://github.com/Anankke/SSPanel-Uim.git /path/to/sspanel-uim
cd /path/to/sspanel-uim
composer install --no-dev

# 配置SSPanel-Uim
cp .env.example .env
php xcat initenv
php xcat key:generate
php xcat migrate
php xcat initdownload
php xcat resetTraffic

# 重启服务
systemctl start nginx
systemctl enable nginx
systemctl restart php-fpm

echo "SSPanel-Uim已成功安装和配置！"
