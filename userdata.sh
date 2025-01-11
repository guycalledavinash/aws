#!/bin/bash
sudo apt update -y
sudo apt install nginx -y
sudo systemctl restart nginx
sudo systemctl enable nginx
echo "<h1>AVINASH - A</h1>" | sudo tee /var/www/html/index.nginx-debian.html > /dev/null
