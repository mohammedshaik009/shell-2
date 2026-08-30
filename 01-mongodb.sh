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
#check root user or not
if [ $USERID -ne 0 ]; then
    echo -e "$TIMESTAMP [ERROR] $R please run this scirpt with root access $N" | tee -a $LOGS_FILE
    exit 1
fi

VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "$TIMESTAMP [error] $2 is...$R FAILURE $N"   | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$TIMESTAMP [INFO] $2 is...$G SUCCESS $N"  | tee -a $LOGS_FILE
    fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "adding mongo.repo"

dnf install mongodb-org -y &>> $LOGS_FILE
VALIDATE $? "installing MongoDB"

systemctl enable --now mongod &>> $LOGS_FILE
VALIDATE $? "starting and enabling MongoDB"

sed -i -e '/s/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Allowing remote connections"

systemctl restart mongod   &>> $LOGS_FILE
VALIDATE $? "Restarting MongoDB"