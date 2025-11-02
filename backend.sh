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

dnf module disable nodejs -y &>>$log_file
validate $? "disable default node js"

dnf module enable nodejs:20 -y &>>$log_file
validate $? "enable nodejs:20"

dnf install nodejs -y &>>$log_file
validate $? "install nodejs"

id expense &>>$log_file
if [ $? -ne 0 ]
then
    echo -e "expense user does not exists... $g creating $n"
    useradd expense &>>$log_file
    validate $? "creating expense user"
else
    echo -e "expense user already exists... $y skipping $n"
fi