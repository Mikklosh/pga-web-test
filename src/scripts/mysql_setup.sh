#!/bin/bash
#
ENTER=`echo -e "\n"`

SECURE_MYSQL=$(expect -c "
set timeout 10
spawn mysql_secure_installation
expect \"Enter current password for root (enter for none):\"
send \"$ENTER\r\"
expect \"Change the root password?\"
send \"y\r\"
expect \"New password:\"
send \"ENV_PWD_MYSQL_ROOT\r\"
expect \"Re-enter new password:\"
send \"ENV_PWD_MYSQL_ROOT\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"y\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
")

echo "$SECURE_MYSQL"
