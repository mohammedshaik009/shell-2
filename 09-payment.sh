#!/bin/bash

LOGS_FOLDER="/var/log/roboshop" 
sudo mkdir -p $LOGS_FOLDER
sudo chown -R ec2-user:ec2-user $LOGS_FOLDER
sudo chmod -R 755 $LOGS_FOLDER
LOGS_FILE="$LOGS_FOLDER/$0.log"
SCRIPT_DIR="$PWD"
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

dnf install python3 gcc python3-devel -y
VALIDATE $? "installing python"

id roboshop $LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "setting up system user"
else
    echo -e "system user already created ...$Y SKIPPING $N"
fi

dnf install python3 gcc python3-devel -y  $LOGS_FILE
VALIDATE $? "installing python"

id roboshop 
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "setting up system user"
else
    echo -e "system user already created ....$Y SKIPPING $N"
fi

rm -rf /app
VALIDATE $? "removing existing code"

mkdir -p /app  $LOGS_FILE
VALIDATE $? "creating directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip  $LOGS_FILE
cd /app 
unzip /tmp/payment.zip
VALIDATE $? "downloaded and extracted code"

pip3 install $LOGS_FILE
VALIDATE $? "installing dependencies"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service
VALIDATE $? "creating systemctl service"

systemctl enable payment  $LOGS_FILE
systemctl start payment  $LOGS_FILE
VALIDATE $? "restarting payment"
