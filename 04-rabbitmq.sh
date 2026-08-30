#!/bin/bash

LOGS_FOLDER="/var/log/roboshop"
sudo mkdir -p $LOGS_FOLDER
sudo chown -R ec2-user:ec2-user $LOGS_FOLDER
sudo chmod -R 755 $LOGS_FOLDER
LOGS_FILE="$LOGS_FOLDER/$0.log"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

USERID=$(id -u)
#check root access or not
if [ $USERID -ne 0 ]; then
    echo -e "$TIMESTAMP [ERROR] $R please run this script with root access $N"  | tee -a $LOGS_FILE
    exit 1
fi

VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "$TIMESTAMP [ERROR] $2 is ...$R FAILURE $N"  | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$TIMESTAMP [INFO] $2 is ...$G SUCCESS $N"   | tee -a $LOGS_FILE
    fi
}

cp rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
VALIDATE $? "Adding rabbitmq.repo"

dnf install rabbitmq-server -y &>> $LOGS_FILE
VALIDATE $? "installing Rabbitmq"

systemctl enable --now rabbitmq &>> $LOGS_FIL
VALIDATE $? "starting and enabling"

rabbitmqctl add_user roboshop roboshop123 &>> $LOGS_FIL
VALIDATE $? "Setting up user"

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"   &>> $LOGS_FILE
VALIDATE $? "setting up password"