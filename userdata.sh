#!/bin/bash
sudo apt update
sudo apt install nginx -y
echo 'AVINASH - A' | sudo tee /var/www/html/index.nginx-debian.html > /dev/null
sudo systemctl restart nginx
sudo systemctl enable nginx
