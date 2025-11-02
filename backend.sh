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

id expense &>>$log_file #if expense user exists then exit status will be 0 (echo $?) if expense user does not exists exit status will return 1
if [ $? -ne 0 ]
then
    echo -e "expense user does not exists... $g creating $n"
    useradd expense &>>$log_file
    validate $? "creating expense user"
else
    echo -e "expense user already exists... $y skipping $n"
fi

mkdir -p /app #if app folder is there this step will skip else app folder will be created.
validate $? "creating /app folder"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$log_file
validate $? "downloading backend app code"

cd /app
rm -rf /app/* #remove the existing code
unzip /tmp/backend.zip &>>$log_file
validate $? "extracting backend app code"

npm install &>>$log_file
cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service

#load the data before running the backend
dnf install mysql -y &>>$log_file
validate $? "installing mysql client"

mysql -h mysql.dawsconnect.org -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$log_file
validate $? "schema loading"

systemctl daemon-reload &>>$log_file
validate $? "daemon reload"

systemctl enable backend &>>$log_file
validate $? "enabled backend"

systemctl restart backend &>>$log_file
validate $? "restarted backend"