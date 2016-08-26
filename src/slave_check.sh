#!/bin/bash

EMAIL="monitoring@g5e.com"

HOST[0]="pga-slave-ddp.g5e.com"
HOST[1]="pga-slave-hsp.g5e.com"
#HOST[2]="pga-slave-vcp.g5e.com"
#HOST[3]="pga-slave-survivors.g5e.com"
#HOST[4]="pga-slave-mapg.g5e.com"
#HOST[5]="pga-slave-lfnpg.g5e.com"
#HOST[6]="pga-slave-btp.g5e.com"
#HOST[7]="pga-slave-hc.g5e.com"
#HOST[8]="pga-slave-sofpg.g5e.com"
##HOST[9]="pga-slave-rorpg.g5e.com"
##HOST[10]="pga-slave-sed.g5e.com"
##HOST[11]="pga-slave-smmpg.g5e.com"
##HOST[12]="pga-slave-ticpg.g5e.com"

for ((i=0; i<${#HOST[@]}; i++)); do

MYSQL_USR="monitoring"
MYSQL_PWD="ADfgpowj9jh5t89g89h48235"

#Check connection to server
MYSQL_CHECK=$(mysql --host=${HOST[$i]} --user=$MYSQL_USR --password=$MYSQL_PWD -e "SHOW VARIABLES LIKE '%version%';" || echo 1)

## Check if I can connect to Mysql ##
if [ "$MYSQL_CHECK" == 1 ]; then
    ERRORS=("${ERRORS[@]}" "Can't connect to MySQL Server:\n \t- Access denied\n\n")
else

#Check processing relay log
LAST_ERRNO=$(mysql --host=${HOST[$i]} --user=$MYSQL_USR --password=$MYSQL_PWD -e "SHOW SLAVE STATUS\G" | grep "Last_Errno:" | awk '{ print $2 }')
LAST_ERROR=$(mysql --host=${HOST[$i]} --user=$MYSQL_USR --password=$MYSQL_PWD -e "SHOW SLAVE STATUS\G" | grep "Last_Error:" | awk '{ print }')

#Check IO
SLAVE_IO_RUNNING=$(mysql --host=${HOST[$i]} --user=$MYSQL_USR --password=$MYSQL_PWD -e "SHOW SLAVE STATUS\G" | grep "Slave_IO_Running" | awk '{ print $2 }')
LAST_IO_ERRNO=$(mysql --host=${HOST[$i]} --user=$MYSQL_USR --password=$MYSQL_PWD -e "SHOW SLAVE STATUS\G" | grep "Last_IO_Errno:" | awk '{ print }')
LAST_IO_ERROR=$(mysql --host=${HOST[$i]} --user=$MYSQL_USR --password=$MYSQL_PWD -e "SHOW SLAVE STATUS\G" | grep "Last_IO_Error:" | awk '{ print }')

#Check SQL
SLAVE_SQL_RUNNING=$(mysql --host=${HOST[$i]} --user=$MYSQL_USR --password=$MYSQL_PWD -e "SHOW SLAVE STATUS\G" | grep "Slave_SQL_Running:" | awk '{ print $2 }')
LAST_SQL_ERRNO=$(mysql --host=${HOST[$i]} --user=$MYSQL_USR --password=$MYSQL_PWD -e "SHOW SLAVE STATUS\G" | grep "Last_SQL_Errno:" | awk '{ print }')
LAST_SQL_ERROR=$(mysql --host=${HOST[$i]} --user=$MYSQL_USR --password=$MYSQL_PWD -e "SHOW SLAVE STATUS\G" | grep "Last_SQL_Error:" | awk '{ print }')

#Check seconds behind master
SECONDS_BEHIND_MASTER=$(mysql --host=${HOST[$i]} --user=$MYSQL_USR --password=$MYSQL_PWD -e "SHOW SLAVE STATUS\G"| grep "Seconds_Behind_Master:" | awk '{ print $2 }')

ERRORS=()

    ## Check For Last Error ##
    if [ "$LAST_ERRNO" != 0 ]; then
        ERRORS=("${ERRORS[@]}" "Error when processing relay log:\n \t- Last_Errno:$LAST_ERRNO\n \t- $LAST_ERROR\n\n")
    fi

    ## Check if IO thread is running ##
    if [ "$SLAVE_IO_RUNNING" != "Yes" ]; then
        ERRORS=("${ERRORS[@]}" "I/O thread for reading the master's binary log is not running:\n \t- Slave_IO_Running:$SLAVE_IO_RUNNING\n \t- $LAST_IO_ERRNO\n \t- $LAST_IO_ERROR\n\n")
    fi

    ## Check for SQL thread ##
    if [ "$SLAVE_SQL_RUNNING" != "Yes" ]; then
        ERRORS=("${ERRORS[@]}" "SQL thread for executing events in the relay log is not running:\n \t- Slave_SQL_Running:$SLAVE_SQL_RUNNING\n \t- $LAST_SQL_ERRNO\n \t- $LAST_SQL_ERROR\n\n")
    fi

    ## Check how slow the slave is ##
    if [ "$SECONDS_BEHIND_MASTER" == "NULL" ]; then
        ERRORS=("${ERRORS[@]}" "The Slave is reporting behind master is 'NULL':\n \t- Seconds_Behind_Master:$SECONDS_BEHIND_MASTER\n\n")
    elif [ "$SECONDS_BEHIND_MASTER" -ge 500 ]; then
        ERRORS=("${ERRORS[@]}" "The Slave is at least 500 seconds behind the master:\n \t- Seconds_Behind_Master:$SECONDS_BEHIND_MASTER\n\n")
    fi

fi

### Send and Email if there is an error ###
if [ "${#ERRORS[@]}" -gt 0 ]; then
    MESSAGE="An error has been detected on ${HOST[$i]} involving the mysql replciation.\n\n
    Below is a list of the reported errors:\n\n
    $(for ((z=0; z<${#ERRORS[@]}; z++));
    do
    echo "${ERRORS[$z]}\n";
    done
    )"
    echo -e $MESSAGE | mail -s "[MYSQL REPLICATION] ${HOST[$i]} is reporting ERROR" ${EMAIL}
fi

done
exit 0