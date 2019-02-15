#!/bin/bash
#Run this script under "root" account

INSTALL_USER=redis
SOURCE_PATH=./redis
INSTALL_PATH=/opt/redis
REDIS_VERSION=5.0.2
REDIS_CONFIG_FILE_MASTER=redis_m.conf
REDIS_CONFIG_FILE_SLAVE=redis_s.conf
REDIS_CONFIG_FILE=redis.conf
SENTINEL_CONFIG_FILE=sentinel.conf
REDIS_PID_FILE=redis.pid
SENTINEL_PID_FILE=redis-sentinel.pid
REDIS_PORT=6379
SENTINEL_PORT=26379
MASTER_IP=
MASTER_NAME=mymaster
PASSWORD=varta168!

#Check Source File
if [ ! -f $SOURCE_PATH/redis-$REDIS_VERSION.tar.gz ];then
   echo "[`date '+%Y-%m-%d %H:%M:%S'`] Redis tar file doesn't exist,please check."
   exit
fi

#Check Master Config File
if [ ! -f $SOURCE_PATH/$REDIS_CONFIG_FILE_MASTER ];then
   echo "[`date '+%Y-%m-%d %H:%M:%S'`] Redis master config file doesn't exist,please check."
   exit
fi

#Check Slave File
if [ ! -f $SOURCE_PATH/$REDIS_CONFIG_FILE_SLAVE ];then
   echo "[`date '+%Y-%m-%d %H:%M:%S'`] Redis slave config file doesn't exist,please check."
   exit
fi

#Stop Redis process
rm -rf $INSTALL_PATH/$REDIS_PID_FILE
killall redis-server

#Stop Sentinel process
rm -rf $INSTALL_PATH/$SENTINEL_PID_FILE
killall redis-sentinel

#Delete Old Redis file
rm -rf $SOURCE_PATH/redis-$REDIS_VERSION

#Extract Redis tar file
tar -zxvf $SOURCE_PATH/redis-$REDIS_VERSION.tar.gz -C $SOURCE_PATH

#Check Whether Redis Exist Under $INSTALL_PATH
if [ -d $INSTALL_PATH ];then
   rm -rf $INSTALL_PATH
fi 

#Copy new file to $INSTALL_PATH
mv $SOURCE_PATH/redis-$REDIS_VERSION $INSTALL_PATH

#Check $USER Exist
id $INSTALL_USER >& /dev/null 
if [ $? -ne 0 ];then
   groupadd $INSTALL_USER
   useradd -r -g $INSTALL_USER -s /bin/false $INSTALL_USER
fi

#Create Logs Folder
mkdir $INSTALL_PATH/logs

#Create Data Folder
mkdir $INSTALL_PATH/data

#Copy Config File to $INSTALL_PATH
mv $INSTALL_PATH/redis.conf $INSTALL_PATH/redis.conf.bak
read -p "Enter Master IP:" MASTER_IP
read -p "Install as Master/Slave?[m/s]" answer
if [ $answer == "m" ] || [ $answer == "M" ];then
   \cp $SOURCE_PATH/$REDIS_CONFIG_FILE_MASTER $INSTALL_PATH/$REDIS_CONFIG_FILE
   sed -i "/# requirepass/a\requirepass $PASSWORD" $INSTALL_PATH/$REDIS_CONFIG_FILE
else
   \cp $SOURCE_PATH/$REDIS_CONFIG_FILE_SLAVE $INSTALL_PATH/$REDIS_CONFIG_FILE
   sed -i "/# replicaof/a\replicaof $MASTER_IP $REDIS_PORT" $INSTALL_PATH/$REDIS_CONFIG_FILE
   sed -i "/# masterauth/a\masterauth $PASSWORD" $INSTALL_PATH/$REDIS_CONFIG_FILE
fi

#Compile Redis
make -C $INSTALL_PATH/src&&make install -C $INSTALL_PATH/src PREFIX=$INSTALL_PATH

#Change Redis Owner
chown -R $INSTALL_USER:$INSTALL_USER $INSTALL_PATH

#Set Sysctl Param
cat >> /etc/sysctl.conf <<EOF
vm.overcommit_memory = 1
net.core.somaxconn = 2048
vm.swappiness = 0
EOF
sysctl -p

#Set Transparent_hugepage
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag
if ! grep 'transparent_hugepage/enabled' /etc/rc.local;then
   echo never > /sys/kernel/mm/transparent_hugepage/enabled
fi

if ! grep 'transparent_hugepage/defrag' /etc/rc.local;then
   echo never > /sys/kernel/mm/transparent_hugepage/defrag
fi

#Set Redis Env
cat >> /etc/profile <<EOF

#Set Redis Env
export REDIS_HOME="$INSTALL_PATH"
export PATH="\$REDIS_HOME/bin:\$PATH"
EOF
source /etc/profile

#Install Tcl
#yum install tcl -y

#Test Redis
#make test -C $INSTALL_PATH/src

#Add Port to Firewall
systemctl status firewalld
if [ $? -ne 0 ];then
   systemctl start firewalld
fi
firewall-cmd --add-port=$REDIS_PORT/tcp --permanent --zone=public
firewall-cmd --reload

#Add Redis Service
cat > /usr/lib/systemd/system/redis.service <<EOF
[Unit]
Description=Redis Service
After=redis.service

[Service]
Type=forking
User=redis
Group=redis
PIDFile=/opt/redis/redis.pid
ExecStart=/opt/redis/bin/redis-server /opt/redis/redis.conf
ExecStop=/opt/tomcat/bin/redis-cli shutdown
PrivateTmp=yes

[Install]
WantedBy=multi-user.target
EOF
chmod 644 /usr/lib/systemd/system/redis.service
systemctl daemon-reload

#Start Redis
systemctl start redis

#Set Auto Start
systemctl enable redis

#Show Redis Process
systemctl status redis

#Install Sentinel
read -p "Do you want to install sentinel?[y/n]" answer
echo "answer: $answer"
if [[ $answer != y ]] && [[ $answer != Y ]];then exit 0;fi

#Check Sentinel Config File
if [ ! -f $SOURCE_PATH/sentinel.conf ];then
   echo "[`date '+%Y-%m-%d %H:%M:%S'`] Redis sentinel config file doesn't exist,please check."
   exit
fi

#Copy new Config File
\cp $SOURCE_PATH/$SENTINEL_CONFIG_FILE $INSTALL_PATH/$SENTINEL_CONFIG_FILE

sed -i "s/hostname/$MASTER_NAME/g" $INSTALL_PATH/$SENTINEL_CONFIG_FILE
sed -i "s/masterip/$MASTER_IP/g" $INSTALL_PATH/$SENTINEL_CONFIG_FILE
sed -i "s/masterport/$REDIS_PORT/g" $INSTALL_PATH/$SENTINEL_CONFIG_FILE
sed -i "s/hostpass/$PASSWORD/g" $INSTALL_PATH/$SENTINEL_CONFIG_FILE

#Change Redis Owner
chown -R $INSTALL_USER:$INSTALL_USER $INSTALL_PATH

#Add Port to Firewall
systemctl status firewalld
if [ $? -ne 0 ];then
   systemctl start firewalld
fi
firewall-cmd --add-port=$SENTINEL_PORT/tcp --permanent --zone=public
firewall-cmd --reload

#Add Sentinel Service
cat > /usr/lib/systemd/system/redis-sentinel.service <<EOF
[Unit]
Description=Redis Sentinel Service
After=redis-sentinel.service

[Service]
Type=forking
User=redis
Group=redis
PIDFile=/opt/redis/redis-sentinel.pid
ExecStart=/opt/redis/bin/redis-sentinel /opt/redis/sentinel.conf
ExecStop=/opt/tomcat/bin/redis-cli -p 26379 shutdown
PrivateTmp=yes

[Install]
WantedBy=multi-user.target
EOF
chmod 644 /usr/lib/systemd/system/redis-sentinel.service
systemctl daemon-reload

#Start Redis Sentinel
systemctl start redis-sentinel

#Set Auto Start
systemctl enable redis-sentinel

#Show Redis Sentinel Status
systemctl status redis-sentinel
