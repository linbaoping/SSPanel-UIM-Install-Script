#!/bin/bash

# 更新系统软件包
yum update -y

# 安装必要的软件
yum install -y epel-release
yum install -y git nginx mariadb mariadb-server php php-fpm php-mysqlnd

# 启动并设置开机启动服务
systemctl enable nginx
systemctl enable mariadb
systemctl enable php-fpm

# 启动服务
systemctl start nginx
systemctl start mariadb
systemctl start php-fpm

# 配置MariaDB数据库
mysql_secure_installation <<EOF

y
yourpassword
yourpassword
y
y
y
y
EOF

# 下载SSPanel UIM源码
git clone https://github.com/Anankke/SSPanel-Uim.git /var/www/html/SSPanel-Uim

# 设置文件权限
chown -R nginx:nginx /var/www/html/SSPanel-Uim
chmod -R 755 /var/www/html/SSPanel-Uim

# 创建SSPanel UIM数据库
mysql -u root -p'yourpassword' <<EOF
CREATE DATABASE sspanel_uim DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL ON sspanel_uim.* TO 'sspanel'@'localhost' IDENTIFIED BY 'yourpassword';
FLUSH PRIVILEGES;
EOF

# 导入数据库结构
mysql -u root -p'yourpassword' sspanel_uim < /var/www/html/SSPanel-Uim/sql/glzjin_all.sql

# 配置SSPanel UIM
cp /var/www/html/SSPanel-Uim/.env.example /var/www/html/SSPanel-Uim/.env
sed -i 's/DB_DATABASE=sspanel/DB_DATABASE=sspanel_uim/g' /var/www/html/SSPanel-Uim/.env
sed -i 's/DB_USERNAME=root/DB_USERNAME=sspanel/g' /var/www/html/SSPanel-Uim/.env
sed -i 's/DB_PASSWORD=/DB_PASSWORD=yourpassword/g' /var/www/html/SSPanel-Uim/.env

# 安装Composer
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php --install-dir=/usr/local/bin --filename=composer
php -r "unlink('composer-setup.php');"

# 安装Composer依赖
cd /var/www/html/SSPanel-Uim
composer install --no-dev --optimize-autoloader

# 生成密钥
php artisan key:generate

# 配置Nginx虚拟主机
cat <<EOF > /etc/nginx/conf.d/sspanel.conf
server {
    listen 8443;
    server_name www.wanganky.club; # 将yourdomain.com替换为你的域名

    root /var/www/html/SSPanel-Uim/public;
    index index.php index.html index.htm;

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

# 重启Nginx
systemctl restart nginx

echo "SSPanel UIM已成功部署！"
