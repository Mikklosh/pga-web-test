#!/bin/bash
#
PWD_FTP_USER=$(expect -c "
set timeout 10
spawn passwd $ENV_FTP_USER
expect \"New password:\"
send \"ENV_PWD_FTP_USER\r\"
expect \"Retype new password:\"
send \"ENV_PWD_FTP_USER\r\"
expect eof
")

echo "$PWD_FTP_USER"
