#!/bin/bash
#
#ENV_HOST_IP - external IP
#ENV_HOST_NAME - hostname (like pga-web)
#ENV_CENTOS_USER - standart centos system user
#ENV_PWD_CENTOS_USER - Password for standart centos system user
#ENV_FTP_USER - ftp-user programmres (like pga-web)
#ENV_PWD_FTP_USER - Password for ftp-user programmres (like pga-web)
#ENV_WEBMIN_ADMIN - root user for webmin
#ENV_PWD _WEBMIN_ADMIN- password for webmin root
#ENV_WEBMIN_USER - user for webmin
#ENV_PWD_WEBMIN_USER - password for webmin user

SETUP_COMPLETE="/src/setup_complete"

if [ ! -f $SETUP_COMPLETE ]; then

#Set host IP
ENV_HOST_IP=$(ifconfig venet0:0 | awk '{ print $2}' | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
sed -i "s/ENV_HOST_IP/$ENV_HOST_IP/g" /etc/nginx/vhosts/ip.conf

#Webmin configuration
sed -i "s/ENV_WEBMIN_ADMIN/$ENV_WEBMIN_ADMIN/g" /src/webmin_setup.sh
sed -i "s/ENV_PWD_WEBMIN_ADMIN/$ENV_PWD_WEBMIN_ADMIN/g" /src/webmin_setup.sh
sed -i "s/ENV_WEBMIN_USER/$ENV_WEBMIN_USER/g" /src/webmin_setup.sh
sed -i "s/ENV_PWD_WEBMIN_USER/$ENV_PWD_WEBMIN_USER/g" /src/webmin_setup.sh

#Munin configuration
sed -i "s/ENV_HOST_NAME/$ENV_HOST_NAME/g" /etc/munin/munin.conf
sed -i "s/ENV_HOST_NAME/$ENV_HOST_NAME/g" /etc/munin/munin-node.conf

#Monit configuration
sed -i "s/ENV_HOST_NAME/$ENV_HOST_NAME/g" /etc/monit.conf

#Add centos user
useradd $ENV_CENTOS_USER
sed -i "s/ENV_PWD_CENTOS_USER/$ENV_PWD_CENTOS_USER/g" /src/users_pwd.sh

#Add ftp user
useradd -md /storage/www -s /sbin/nologin $ENV_FTP_USER
sed -i "s/ENV_PWD_FTP_USER/$ENV_PWD_FTP_USER/g" /src/users_pwd.sh
echo $ENV_FTP_USER >> /etc/vsftpd/user_list

#Additional parametrs
/bin/bash -c /src/users_pwd.sh
/bin/bash -c /src/webmin_setup.sh
chmod 755 /storage/www/
rm -f /var/run/munin/*
rm -f /etc/munin/plugins/diskstats && rm -f /etc/munin/plugins/if_err_eth0 && rm -f /etc/munin/plugins/if_eth0 && rm -f /etc/munin/plugins/sendmail_mailqueue && rm -f /etc/munin/plugins/sendmail_mailstats && rm -f /etc/munin/plugins/sendmail_mailtraffic && rm -f /etc/munin/plugins/interrupts && rm -f /etc/munin/plugins/irqstats
chkconfig iptables off && chkconfig --del iptables
chkconfig ip6tables off &&  chkconfig --del ip6tables
touch $SETUP_COMPLETE
fi

#Flush iptables after each reboot
iptables --flush