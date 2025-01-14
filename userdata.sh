#!/bin/bash
sudo apt update
sudo apt install nginx -y
echo 'AVINASH - A' >> /var/www/html/index.nginx-debian.html
sudo systemctl restart nginx
sudo systemctl start nginx
