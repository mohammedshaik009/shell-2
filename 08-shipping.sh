#!/bin/bash

LOGS_FOLDER="/var/log/roboshop" 
sudo mkdir -p $LOGS_FOLDER
sudo chown -R ec2-user:ec2-user $LOGS_FOLDER
sudo chmod -R 755 $LOGS_FOLDER
LOGS_FILE="$LOGS_FOLDER/$0.log"
SCRIPT_DIR="$PWD"
MYSQL_HOST=mysql.mohammed.world
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

dnf module disable nodejs -y   &>> $LOGS_FILE
dnf module enable nodejs:20 -y  &>> $LOGS_FILE
dnf install nodejs -y   &>> $LOGS_FILE
VALIDATE $? "installing nodejs"

id roboshop  &>> $LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "setting up system user"
else
    echo -e "system user roboshop already created ...$Y SKIPPING $N"
fi

dnf install maven -y   &>> $LOGS_FILE
VALIDATE $? "installing Maven"

id roboshop   &>> $LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "setting up system user"
else
    echo -e "system user already created ...$Y SKIPPING $N"
fi
rm -rf /app 
VALIDATE $? "removing existing code"

mkdir -p /app &>> $LOGS_FILE
VALIDATE $? "creating app directory"

rm -rf /tmp/shipping.zip  &>> $LOGS_FILE
VALIDATE $? "removed shipping.zip"

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip  &>> $LOGS_FILE
cd /app 
unzip /tmp/shipping.zip  &>> $LOGS_FILE
VALIDATE $? "downloaded and extracted cart code"

cd /app
mvn clean package  &>> $LOGS_FILE 
mv target/shipping-1.0.jar shipping.jar 
VALIDATE $? "installing dependencies"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "creating systemctl service"

dnf install mysql -y &>> $LOGS_FILE
VALIDATE $? "installing mysql client"

mysql -h $MYSQL_HOST -u root -pRoboShop@1 -e "use cities" &>> $LOGS_FILE
if [ $? -ne 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql
    VALIDATE $? "Data loaded"
else
    echo -e "Data already loaded ...$Y SKIPPING $N"
fi

systemctl enable shipping &>> $LOGS_FILE
systemctl restart shipping &>> $LOGS_FILE
VALIDATE $? "enable and restarted shipping"
