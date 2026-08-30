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

dnf module disable redis -y &>> $LOGS_FILE
dnf module enable redis:7 &>> $LOGS_FILE
dnf install redis -y &>> $LOGS_FILE
VALIDATE $? "installing redis"

sed -i -e 's/127.0.0.1/0.0.0.0/' -e '/protected-mode/ c /protected-mode no' /etc/redis/redis.conf
VALIDATE $? "Allowing remote connetions"

systemctl enable --now redis  &>> $LOGS_FILE
VALIDATE $? "enable and start"