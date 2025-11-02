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

dnf install nginx -y &>>$log_file
validate $? "installing nginx"

systemctl enable nginx &>>$log_file
validate $? "enable nginx"

systemctl start nginx &>>$log_file
validate $? "start nginx"

rm -rf /usr/share/nginx/html/* &>>$log_file
validate $? "removing default website"

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>>$log_file
validate $? "downloading frontend code"

cd /usr/share/nginx/html
unzip /tmp/frontend.zip &>>$log_file
validate $? "extract frontend code"

cp /home/ec2-user/expense-shell/expense.conf /etc/nginx/default.d/expense.conf
validate $? "copied expense conf"

systemctl restart nginx