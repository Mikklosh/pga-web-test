#!/bin/bash
#
PWD_ROOT_USER=$(expect -c "
set timeout 10
spawn passwd root
expect \"New password:\"
send \"ENV_PWD_ROOT_USER\r\"
expect \"Retype new password:\"
send \"ENV_PWD_ROOT_USER\r\"
expect eof
")

echo "$PWD_ROOT_USER"