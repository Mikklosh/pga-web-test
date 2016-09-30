#!/bin/bash

#ENV_HOST_IP - external IP
#ENV_HOST_NAME— server hostname (like pga-master-prj)
#ENV_PRJ_NAME— pgax project name (provided that the DB and WWW named identically)
#ENV_PWD_MYSQL_ROOT— password for MySQL root user
#ENV_PWD_ROOT_USER— password for unix root user
#ENV_BLOWFISH_SECRET— blowfish secret for phpmyadmin
#ENV_CENTOS_USER— secondary unix user
#ENV_PWD_CENTOS_USER— password for secondary unix user
#ENV_FTP_USER— ftp user (like pga-prj)
#ENV_PWD_FTP_USER— password for ftp user
#ENV_WEBMIN_ADMIN— superuser for webmin
#ENV_PWD_WEBMIN_ADMIN— password for webmin superuser
#ENV_WEBMIN_USER— webmin development user
#ENV_PWD_WEBMIN_USER— password for webmin development user
#ENV_RSYNCD_SCRT_NJ— password for rsync deamon in NJ
#ENV_RSYNCD_SCRT_NL— password for rsync deamon in NL

#Script variables
SETUP_COMPLETE="/src/setup_complete"
REBOOT_COMPLETE="/src/reboot_complete"
SCRIPTS_FOLDER="/src/scripts"

#Set executable for all scripts
chmod 770 /src/scripts/*

#Setup MySQL
if [ ! -d /storage/mysql/ ]; then
cp -R /var/lib/mysql.bak/ /storage/mysql/
chown -R mysql:mysql /storage/mysql/
sed -i "s/ENV_PRJ_NAME/$ENV_PRJ_NAME/g" /storage/conf/mysql/my.cnf
/etc/init.d/mysql start
sed -i "s/ENV_PWD_MYSQL_ROOT/$ENV_PWD_MYSQL_ROOT/g" $SCRIPTS_FOLDER/mysql_setup.sh
/bin/bash -c $SCRIPTS_FOLDER/mysql_setup.sh
fi

#Start loop for checking settings 
if [ ! -f $SETUP_COMPLETE ]; then

#Configure SSH
sed -i "s/#PermitRootLogin yes/PermitRootLogin no/g" /etc/ssh/sshd_config
sed -i "s/#UseDNS yes/UseDNS no/g" /etc/ssh/sshd_config

#Set host IP
ENV_HOST_IP=$(ifconfig venet0:0 | awk '{ print $2}' | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
sed -i "s/ENV_HOST_IP/$ENV_HOST_IP/g" /etc/nginx/vhosts/ip.conf

#Setup NGINX
sed -i "s/ENV_HOST_NAME/$ENV_HOST_NAME/g" /storage/conf/nginx/vhosts/ip.conf
sed -i "s/ENV_PRJ_NAME/$ENV_PRJ_NAME/g" /storage/conf/nginx/vhosts/pgaprj.conf

#Setup PhpMyAdmin
sed -i "s/ENV_BLOWFISH_SECRET/$ENV_BLOWFISH_SECRET/g" /usr/share/phpMyAdmin/config.inc.php
sed -i 's/localhost/pga-web/g' /usr/share/phpMyAdmin/config.inc.php
cat /TEMP/servers.txt  >> /usr/share/phpMyAdmin/config.inc.php

#Webmin configuration
sed -i "s/ENV_WEBMIN_ADMIN/$ENV_WEBMIN_ADMIN/g" $SCRIPTS_FOLDER/webmin_setup.sh
sed -i "s/ENV_PWD_WEBMIN_ADMIN/$ENV_PWD_WEBMIN_ADMIN/g" $SCRIPTS_FOLDER/webmin_setup.sh
sed -i "s/ENV_WEBMIN_USER/$ENV_WEBMIN_USER/g" $SCRIPTS_FOLDER/webmin_setup.sh
sed -i "s/ENV_PWD_WEBMIN_USER/$ENV_PWD_WEBMIN_USER/g" $SCRIPTS_FOLDER/webmin_setup.sh
/bin/bash -c $SCRIPTS_FOLDER/webmin_setup.sh

#Munin configuration
sed -i "s/ENV_HOST_NAME/$ENV_HOST_NAME/g" /etc/munin/munin.conf
sed -i "s/ENV_HOST_NAME/$ENV_HOST_NAME/g" /etc/munin/munin-node.conf
sed -i "s/ENV_PWD_MYSQL_ROOT/$ENV_PWD_MYSQL_ROOT/g" /etc/munin/plugin-conf.d/munin-node
rm -f /var/run/munin/*
rm -f /etc/munin/plugins/diskstats && rm -f /etc/munin/plugins/if_err_eth0 && rm -f /etc/munin/plugins/if_eth0 && rm -f /etc/munin/plugins/sendmail_mailqueue && rm -f /etc/munin/plugins/sendmail_mailstats && rm -f /etc/munin/plugins/sendmail_mailtraffic && rm -f /etc/munin/plugins/interrupts && rm -f /etc/munin/plugins/irqstats

#Monit configuration
sed -i "s/ENV_HOST_NAME/$ENV_HOST_NAME/g" /etc/monit.conf

#Change password for system root user
sed -i "s/ENV_PWD_ROOT_USER/$ENV_PWD_ROOT_USER/g" $SCRIPTS_FOLDER/root_user_setup.sh
/bin/bash -c $SCRIPTS_FOLDER/root_user_setup.sh

#Add centos user
userdel $ENV_CENTOS_USER
useradd $ENV_CENTOS_USER
sed -i "s/ENV_PWD_CENTOS_USER/$ENV_PWD_CENTOS_USER/g" $SCRIPTS_FOLDER/centos_user_setup.sh
/bin/bash -c $SCRIPTS_FOLDER/centos_user_setup.sh

#Add ftp user
useradd -md /storage/www -s /sbin/nologin $ENV_FTP_USER
chmod 755 /storage/www/
sed -i "s/ENV_PWD_FTP_USER/$ENV_PWD_FTP_USER/g" $SCRIPTS_FOLDER/ftp_user_setup.sh
echo $ENV_FTP_USER >> /etc/vsftpd/user_list
/bin/bash -c $SCRIPTS_FOLDER/ftp_user_setup.sh

#Add index.php
cp /conf/nginx/index.php /storage/www/index.php
sed -i "s/ENV_HOST_NAME/$ENV_HOST_NAME/g" /storage/www/index.php

#Backup configuration
sed -i "s/ENV_PRJ_NAME/$ENV_PRJ_NAME/g" /etc/backup.sh
sed -i "s/ENV_PWD_MYSQL_ROOT/$ENV_PWD_MYSQL_ROOT/g" /etc/backup.sh
sed -i "s/ENV_PRJ_NAME/$ENV_PRJ_NAME/g" /etc/backup_table.sh
sed -i "s/ENV_PWD_MYSQL_ROOT/$ENV_PWD_MYSQL_ROOT/g" /etc/backup_table.sh
chmod 770 /etc/backup.sh && chmod 770 /etc/backup_table.sh && chmod a+rwx /BACKUP/ 
touch /etc/rsyncdnj.scrt && touch /etc/rsyncdnl.scrt
chmod 600 /etc/rsyncdnj.scrt && chmod 600 /etc/rsyncdnl.scrt
echo $ENV_RSYNCD_SCRT_NJ > /etc/rsyncdnj.scrt
echo $ENV_RSYNCD_SCRT_NL > /etc/rsyncdnl.scrt

#Disable iptables NAT redirect
sed -i "/&/s/setRedirect/#setRedirect/g" /etc/rc.d/init.d/jelinit

#Additional parametrs
chmod a+rwx /TEMP/
chmod 600 /etc/sysconfig/iptables
chkconfig iptables off && chkconfig --del iptables
chkconfig ip6tables off &&  chkconfig --del ip6tables
touch $SETUP_COMPLETE

fi
#End loop for checking settings 

#Start loop for reboot after first run
if [ ! -f $REBOOT_COMPLETE ]; then
touch $REBOOT_COMPLETE 
sleep 3m
reboot
fi
#End loop for reboot after first run

#Flush iptables after each reboot
/bin/bash -c $SCRIPTS_FOLDER/iptables_flush.sh