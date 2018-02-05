#!/bin/bash

# Sleep for 30 seconds to allow network initialization before intalling apache
sleep 30

# Update package repository
apt-get -y update

# install Apache2
apt-get -y install apache2

# Download HTML
if [ -z "$1" ]; then branch="master"; else branch="$1"; fi
curl k -s -f --retry 5 --retry-delay 10 --retry-max-time 10 https://raw.githubusercontent.com/F5Networks/f5-azure-arm-templates/$branch/experimental/reference/learning-stack/html/default.html > /var/www/html/index.html

# Add unique entity into default web page
webserver=`hostname`
sed -i.orig "/Example/c\<h1>Example Web Page($webserver)</h1>" /var/www/html/index.html
# restart Apache
apachectl restart
