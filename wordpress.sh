amazon-linux-extras install php7.2
yum localinstall https://dev.mysql.com/get/mysql80-community-release-el7-1.noarch.rpm -y
yum-config-manager --disable mysql80-community
yum-config-manager --enable mysql57-community
yum install -y httpd php mysql-community-server
systemctl start httpd mysqld
systemctl enable mysqld httpd
cd /var/www/html/
wget https://ja.wordpress.org/latest-ja.tar.gz
tar -xzvf latest-ja.tar.gz
rm latest-ja.tar.gz
