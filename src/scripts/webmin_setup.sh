#!/bin/bash
#
ENTER=`echo -e "\n"`

#Configure Webmin without SSL
sed -i "s/ssl=1/ssl=0/g" /etc/webmin/miniserv.conf
WEBMIN_SETUP=$(expect -c "
set timeout 10
spawn /usr/libexec/webmin/setup.sh
expect \"Config file directory /etc/webmin:\"
send \"$ENTER\r\"
expect eof
")
echo "$WEBMIN_SETUP"

#Add Webmin users
echo ENV_WEBMIN_ADMIN:x:0 > /etc/webmin/miniserv.users
echo ENV_WEBMIN_USER:x:0 >> /etc/webmin/miniserv.users
echo ENV_WEBMIN_ADMIN: acl adsl-client ajaxterm apache at backup-config bacula-backup bandwidth bind8 burner change-user cluster-copy cluster-cron cluster-passwd cluster-shell cluster-software cluster-useradmin cluster-usermin cluster-webmin cpan cron custom dfsadmin dhcpd dovecot exim exports fail2ban fdisk fetchmail file filemin filter firewall firewalld fsdump grub heartbeat htaccess-htpasswd idmapd inetd init inittab ipfilter ipfw ipsec iscsi-client iscsi-server iscsi-target iscsi-tgtd jabber krb5 ldap-client ldap-server ldap-useradmin logrotate lpadmin lvm mailboxes mailcap man mon mount mysql net nis openslp package-updates pam pap passwd phpini postfix postgresql ppp-client pptp-client pptp-server proc procmail proftpd qmailadmin quota raid samba sarg sendmail servers shell shorewall shorewall6 smart-status smf software spam squid sshd status stunnel syslog-ng syslog system-status tcpwrappers telnet time tunnel updown useradmin usermin vgetty webalizer webmin webmincron webminlog wuftpd xinetd > /etc/webmin/webmin.acl
echo ENV_WEBMIN_USER: cron mysql >> /etc/webmin/webmin.acl
/usr/libexec/webmin/changepass.pl /etc/webmin ENV_WEBMIN_ADMIN ENV_PWD_WEBMIN_ADMIN
/usr/libexec/webmin/changepass.pl /etc/webmin ENV_WEBMIN_USER ENV_PWD_WEBMIN_USER