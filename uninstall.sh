#!/bin/bash

service stop nginx

userdel cyrusworks

rm -rf /cyrusworks/

apt-get remove docker-engine -y nginx nginx-common ufw fail2ban sudo curl unattended-upgrades wget ntp

apt-get purge docker-engine -y nginx nginx-common ufw fail2ban sudo curl unattended-upgrades wget ntp
