#!/bin/bash
#
PWD_CENTOS_USER=$(expect -c "
set timeout 10
spawn passwd $ENV_CENTOS_USER
expect \"New password:\"
send \"ENV_PWD_CENTOS_USER\r\"
expect \"Retype new password:\"
send \"ENV_PWD_CENTOS_USER\r\"
expect eof
")

echo "$PWD_CENTOS_USER"