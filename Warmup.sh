#!/bin/bash

# checking server version
cat /etc/os-release

# disk size of root volume and extra disk
lsblk

# to check ram 
free -m

# to check CPU
cat /proc/cpuinfo

# update server packages
yum update -y

# format disk and mount
# to create disk2 volume LVM type 
pvcreate /dev/xvdb

vgcreate mylvm1 /dev/xvdb

lvcreate --name part1 --size 4080M mylvm1

# format
mkfs.xfs /dev/mylvm1/part1

mkdir /home2

# entry in fstab
sed -i '$ a  /dev/mylvm1/part1   /home2    xfs   noexec'  /etc/fstab

mount -a

# disable selinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

setenforce 0

# set timezone of server
timedatectl set-timezone "Asia/Kolkata"

# installing vim,wget,git,net-tools
yum install vim git wget net-tools  -y

# reboot your server to check all entries were permanent
reboot

# motd file entry
cat << EOF >>/etc/profile.d/motd.sh
#!/bin/bash
echo "
###############################################################
#                 Authorized access only!                     #
# Disconnect IMMEDIATELY if you are not an authorized user!!! #
#         All actions Will be monitored and recorded          #
###############################################################
+++++++++++++++++++++++++++++++ SERVER INFO ++++++++++++++++++++++++++++++++
"
cpu_info=$(cat /proc/cpuinfo | grep -w 'model name' |awk -F: '{print $2}')
echo "   CPU: $cpu_info"
memo_info=$(cat /proc/meminfo | grep -w 'MemTotal' | awk -F: '{print $2 / 1000}')
echo "   Memory: $memo_info M"
swap=$(cat /proc/meminfo | grep -w 'SwapTotal' | awk -F: '{print $2 / 1000}')
echo "   Swap: $swap M"
disk_space=$(df -h | grep -w '/dev/xvda1' | awk '{print $2}')
echo "   Disk: $disk_space"
distro=$(cat /etc/centos-release)
distro2=$(uname -r)
echo "   Distro: $distro with $distro2 "
load=$(cat /proc/loadavg | awk '{print $1" , "$2" , "$3}' )
echo "   CPU Load: $load"
mem_free=$(cat /proc/meminfo | grep -w 'MemFree'| awk -F: '{print $2 / 1000}')
echo "   Free Memory: $mem_free M"
swap_free=$(cat /proc/meminfo | grep -w 'SwapFree' | awk -F: '{print $2 / 1000}')
echo "   Free Swap: $swap_free M"
disk_free=$(df -h | grep  -w '/dev/xvda1' | awk '{print $4}')
echo "   Free Disk: $disk_free"
pub_addr=$(wget -qO- ifconfig.me/ip )
echo "   Public Address: $pub_addr "
pri_addr=$(hostname -i)
echo "   Private Address: $pri_addr"
echo "
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
"
EOF


# installing SCL repository
yum install centos-release-scl -y

# installing php modules
yum install rh-php72 rh-php72-php rh-php72-php-gd rh-php72-php-mbstring rh-php72-php-intl rh-php72-php-pecl-apcu  -y

yum install rh-php72-php-mysqlnd -y

# symlink apache modules into place
ln -s /opt/rh/httpd24/root/etc/httpd/conf.d/rh-php72-php.conf /etc/httpd/conf.d/
ln -s /opt/rh/httpd24/root/etc/httpd/conf.modules.d/15-rh-php72-php.conf /etc/httpd/conf.modules.d/
ln -s /opt/rh/httpd24/root/etc/httpd/modules/librh-php72-php7.so /etc/httpd/modules/

# restart apache service 
systemctl restart httpd.service


# user setup
mkdir /home2

# adding blu user and making /home2 default home directory
useradd -b /home2 blu

mkdir /home2/blu/public_html

# create keygen
mkdir -m 700 /home2/blu/.ssh

ssh-keygen -C "Key generated for blu user" -N "" -f /home2/blu/.ssh/blu-key

cat /home2/blu/.ssh/blu-key.pub >> /home2/blu/.ssh/authorized_keys

#fix permission
chmod 600 /home2/blu/.ssh/authorized_keys

chown blu:blu /home2/blu/.ssh -R

# setup user permission
usermod -a -G apache blu

chown blu:apache  /home2/blu/public_html

chmod 711 /home2/blu

chmod 2771 /home2/blu/public_html

# to change document root of apache
sed -i 's/DocumentRoot "/var/www/html"/DocumentRoot "/home2/blu/public_html"/g' /etc/httpd/conf/httpd.conf

sed '124  s/<Directory "/var/www/html"/<Directory "/home2/blu/public_html">/' /etc/httpd/conf/httpd.conf 



# Virtual Host setup
cat << EOF >>/etc/httpd/conf.d/blu-php.conf
<VirtualHost *:80>
    ServerName bluboy.adhocnw.com
    ServerAlias www.bluboy.adhocnw.com
    ServerAdmin webmaster@bluboy.adhocnw.com
    DocumentRoot /home2/blu/public_html

    <Directory /home2/blu/public_html>
        Options -Indexes +FollowSymLinks
        AllowOverride All
    </Directory>

    ErrorLog /home2/blu/blu-adhocnw.com-error.log
    CustomLog /home2/blu/blu-adhocnw.com-access.log combined
</VirtualHost>
EOF

#creation of log files manually
cat << EOF >>/home2/blu/blu-adhocnw.com-error.log
EOF

cat << EOF >>/home2/blu/blu-adhocnw.com-access.log combined
EOF

# permission to fies created
chown :apache /home2/blue/blu-adhocnw.com-error.log

chown :apache /home2/blu/blu-adhocnw.com-access.log combined

chmod g+rw /home2/blu/blu-adhocnw.com-error.log

chmod g+rw /home2/blu/blu-adhocnw.com-access.log combined

# to check all entries are correct or not
sudo apachectl configtest 

# restarting httpd service
sudo systemctl restart httpd

# Domain dns information
sed -i '$ a 13.234.33.163    bluboy.adhocnw.com' /etc/hosts

# setting up phpinfo.php file
cat << EOF >>/home2/blu/public_html/blu-php.php
<?php
phpinfo();
?>
EOF

# changing the permission of blu-php.php file
chmod 777 /home2/blu/public_html/blu-php.php

# On web browser run  ip-address/phpinfo.php. It would display version of php.
