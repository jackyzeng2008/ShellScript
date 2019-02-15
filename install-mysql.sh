#!/bin/bash
#Run this script under "root" account

USER=mysql
SOURCE_PATH=./mysql
INSTALL_PATH=
MYSQL_VERSION=5.6.42-1
CONFIG_FILE_MASTER=my_m.cnf
CONFIG_FILE_SLAVE=my_s.cnf
CONFIG_FILE=my.cnf
CONFIG_FILE_INSTALL_PATH=/usr
PORT=3306
PASSWORD=varta168!
TIMEZONE="Asia\/Shanghai"
INSTALL_MODE=master
MASTER_HOST="db_master"
SLAVE_HOST="db_slave"
MASTER_USER="repl_user"
MASTER_PASSWORD="Repl168!"

#Check Source File
if [ ! -f $SOURCE_PATH/MySQL-client-$MYSQL_VERSION.el7.x86_64.rpm ] || [ ! -f $SOURCE_PATH/MySQL-devel-$MYSQL_VERSION.el7.x86_64.rpm ] || [ ! -f $SOURCE_PATH/MySQL-server-$MYSQL_VERSION.el7.x86_64.rpm ];then
   echo "[`date '+%Y-%m-%d %H:%M:%S'`] MySQL RPM file is missing,please check."
   exit
fi

#Remove Mariadb
yum remove mariadb* -y

#Check Master Config File
if [ ! -f $SOURCE_PATH/$CONFIG_FILE_MASTER ];then
   echo "[`date '+%Y-%m-%d %H:%M:%S'`] MySQL master config file doesn't exist,please check."
   exit
fi

#Check Slave File
if [ ! -f $SOURCE_PATH/$CONFIG_FILE_SLAVE ];then
   echo "[`date '+%Y-%m-%d %H:%M:%S'`] MySQL slave config file doesn't exist,please check."
   exit
fi

#Install RPM
yum localinstall -y $SOURCE_PATH/MySQL*

#Get MySQL Password
PASSWORD_TEMP=`cat ~/.mysql_secret |awk -F"): " '{print $2}'|sed '/^$/d'`

#Copy Config File
read -p "Enter Master/Slave:[m/s]" answer
if [ $answer == "m" ] || [ $answer == "M" ];then
   \cp $SOURCE_PATH/$CONFIG_FILE_MASTER $CONFIG_FILE_INSTALL_PATH/$CONFIG_FILE
else
   INSTALL_MODE=slave
   \cp $SOURCE_PATH/$CONFIG_FILE_SLAVE $CONFIG_FILE_INSTALL_PATH/$CONFIG_FILE
fi

#Start MySQL Service
systemctl restart mysql

#Set MySQL Password
echo "1)Please Enter Password:[$PASSWORD_TEMP]"
echo "2)Please Enter SQL:[SET PASSWORD FOR 'root'@'localhost'=PASSWORD(\"$PASSWORD\");]"
echo "3)Please Enter SQL:[FLUSH PRIVILEGES;]"
echo "4)Please Enter SQL:[EXIT;]"
mysql -uroot -p

#Delete User
EXEC_SQL="use mysql;delete from user where host='::1' or host='localhost.localdomain' or host='127.0.0.1';"
mysql -uroot -p"$PASSWORD" -e "$EXEC_SQL"

#Drop Test Database
EXEC_SQL="drop database test;"
mysql -uroot -p"$PASSWORD" -e "$EXEC_SQL"

#Create Replication User
if [ $INSTALL_MODE == "master" ];then
   EXEC_SQL="drop user $MASTER_USER;"
   mysql -uroot -p"$PASSWORD" -e "$EXEC_SQL"

   EXEC_SQL="create user $MASTER_USER identified by '$MASTER_PASSWORD';grant replication slave on *.* to $MASTER_USER;"
   mysql -uroot -p"$PASSWORD" -e "$EXEC_SQL"
fi

#Reset Master
if [ $INSTALL_MODE == "master" ];then
   EXEC_SQL="reset master;"
   mysql -uroot -p"$PASSWORD" -e "$EXEC_SQL"
fi

#Load Timezone File From System
mysql_tzinfo_to_sql /usr/share/zoneinfo/|mysql -u root -p"$PASSWORD" mysql

#Add TimeZone to CONFIG_FILE
sed -i "s/^#default-time-zone = $TIMEZONE/default-time-zone = $TIMEZONE/g" $CONFIG_FILE_INSTALL_PATH/$CONFIG_FILE

#Set Host File
read -p "Enter Master Local IP:" answer
echo "$answer $MASTER_HOST" >> /etc/hosts

if [ $INSTALL_MODE == "master" ];then
   sed -i "/^server-id/d" $CONFIG_FILE_INSTALL_PATH/$CONFIG_FILE
   SERVER_ID=`echo $answer|awk -F'.' '{print $4}'`
   echo "server-id=$SERVER_ID" >> $CONFIG_FILE_INSTALL_PATH/$CONFIG_FILE
fi

read -p "Enter Slave Local IP:" answer
echo "$answer $SLAVE_HOST" >> /etc/hosts

if [ $INSTALL_MODE == "slave" ];then
   sed -i "/^server-id/d" $CONFIG_FILE_INSTALL_PATH/$CONFIG_FILE
   SERVER_ID=`echo $answer|awk -F'.' '{print $4}'`
   echo "server-id=$SERVER_ID" >> $CONFIG_FILE_INSTALL_PATH/$CONFIG_FILE
fi

#Start MySQL Service
systemctl restart mysql

#Stop and Reset Slave
if [ $INSTALL_MODE == "slave" ];then
   EXEC_SQL='stop slave;reset slave;'
   mysql -uroot -p"$PASSWORD" -e "$EXEC_SQL"
fi

#Set Slave Info
if [ $INSTALL_MODE == "slave" ];then
   EXEC_SQL="change master to master_host='$MASTER_HOST',master_port=$PORT,master_user='$MASTER_USER',master_password='$MASTER_PASSWORD';"
   mysql -uroot -p"$PASSWORD" -e "$EXEC_SQL"
fi

#Start Slave
if [ $INSTALL_MODE == "slave" ];then
   EXEC_SQL='start slave;'
   mysql -uroot -p"$PASSWORD" -e "$EXEC_SQL"
fi

#Check Slave Status
if [ $INSTALL_MODE == "slave" ];then
   EXEC_SQL='show slave status\G;'
   mysql -uroot -p"$PASSWORD" -e "$EXEC_SQL"|grep -E "Slave_IO_Running:|Slave_SQL_Running:"
fi

#Add Port to Firewall
systemctl status firewalld
if [ $? -ne 0 ];then
   systemctl start firewalld
fi
firewall-cmd --add-port=$PORT/tcp --permanent --zone=public
firewall-cmd --reload

#Show MySQL Process
ps -ef |grep mysqld
