#!/bin/bash
sudo  yum update -y
sudo   groupadd docker
sudo   useradd John -aG docker 
sudo   yum install git unzip wget httpd -y
sudo   systemctl start httpd
sudo   systemctl enable httpd
cd /opt
wget https://github.com/kserge2001/web-consulting/archive/refs/heads/dev.zip
unzip dev.zip
cp -r /opt/web-consulting-dev/* /var/www/html