#!/bin/bash

logs_folder="/var/log/expense"
script_name=$(echo $0 | cut -d "." -f1) #$0 is used to get current running script name
timestamp=$(date +%Y-%m-%d-%H-%M-%S)
log_file="$logs_folder/$script_name-$timestamp.log"
mkdir -p $logs_folder #if file is not there it will create if file is there we won't get an error

userid=$(id -u)
r="\e[31m"
g="\e[32m]"
y="\e[33m"
n="\e[0m]"

check_root(){
    if [ $userid -ne 0 ]
    then
        echo -e "$r please run this script with root access $n" | tee -a $log_file #tee is used to print output on the screen and as well as used to write in log_file
        exit 1 
    fi
}

validate(){ 
    if [ $1 -ne 0 ]
    then
        echo -e "$2 is...$r FAILED $n" | tee -a $log_file
        exit 1
    else
        echo -e "$2 is...$g SUCCESS $n" | tee -a $log_file
    fi 
}

echo "script started executing at: $(date)" | tee -a $log_file

check_root

dnf install mysql-server -y
validate $? "installing mysql server"

systemctl enable mysqld
validate $? "Enabled mysql server"

systemctl start mysqld
validate $? "started mysql server"

mysql_secure_installation --set-root-pass ExpenseApp@1
validate $? "setting up root password"