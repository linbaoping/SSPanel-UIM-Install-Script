#!/bin/bash
cccc
# 安装 赖软件包
yum -y install epel-release
yum -信息
read -p "请输入数据库名称：" db_name
read -p "请输入数据库密码：" db_password
read -p "请输入域名：" domain
read -p "请输入端口号：" port

# 安装MySQL
