#!/bin/bash

# add nginx stable package repo
echo "deb http://nginx.org/packages/mainline/ubuntu/ jammy nginx" | sudo tee /etc/apt/sources.list.d/nginx.list

# add nginx package signing key
wget -q -O - https://nginx.org/keys/nginx_signing.key | sudo apt-key add -

# update package indexes
sudo apt-get update

# install nginx version 1.23
sudo apt-get install -y nginx=1.23.1-1~jammy

# start nginx
sudo systemctl start nginx

# start on boot
sudo systemctl enable nginx

# get status
sudo systemctl status nginx
