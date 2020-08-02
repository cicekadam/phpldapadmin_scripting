#!/bin/bash

#Install requirements
yum install -y php php-cgi php-mbstring php-common php-pear php-{gd,json,zip} php-ldap

if [[ !$(rpm -qa | grep httpd) ]]; then
	yum install -y httpd
fi

#Install git and clone phpLdapAdmin project
yum install git
git clone https://github.com/breisig/phpLDAPadmin.git /usr/share/phpldapadmin

#Let's configure it
cp /usr/share/phpldapadmin/config/config.php{.example,} 

#Name of PhpLdapAdmin
echo "Name your Ldap Server: "
read servname
if [[ !servname ]]; then
	servname="My LDAP Server"
fi
sed -i "s#My LDAP Server#${servname}#g" /usr/share/phpldapadmin/config/config.php


#IP of OpenLdap Server
echo "What is the IP of your Ldap Server(leave blank for localhost): "
read servip
if [[ !servname ]]; then
	servip="127.0.0.1"
fi
sed -i "s#127.0.0.1#${servname}#g" /usr/share/phpldapadmin/config/config.php


#Port number of OpenLdap Server
echo "What is the port number of your Ldap Server(leave blank for default): "
read servport
if [[ !servname ]]; then
	servport=",389" # The reason i used "," is to locate the true port number in the config file (eliminating comments) 
fi
sed -i "s#,389#${servname}#g" /usr/share/phpldapadmin/config/config.php


# I tought the uid will be a lot usefull for logins, you may change it as 'dn' to require full dn
echo "$servers->setValue('login','attr','uid');" >> /usr/share/phpldapadmin/config/config.php

# Fixing file configuration
chown -R apache:apache /usr/share/phpldapadmin

# Httpd config file (I used ${HOSTNAME} for ServerName option, you may edit it)
cp ./httpdconf /etc/httpd/conf.d/phpldapadmin.conf

# Configuring firewall tools
echo "Do you use firewalld (y/n)(leave blank if you don't know): "
read answer

if [[ !$answer && $answer=="y" ]]; then
	firewall-cmd --add-port=80/tcp --permanent
	firewall-cmd --reload
fi

echo "Do you use Selinux (y/n)(leave blank if you don't know): "
read answer

if [[ !$answer && $answer=="y" ]]; then
	setsebool -P httpd_can_network_connect 1
	setsebool -P httpd_can_connect_ldap 1
	setsebool -P authlogin_nsswitch_use_ldap 1
	setsebool -P nis_enabled 1
fi


# Let's run it boi!!!
systemctl enable --now httpd