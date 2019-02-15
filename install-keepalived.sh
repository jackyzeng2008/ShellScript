#!/bin/bash
#Run this script under "root" account

SOURCE_PATH=./keepalived
CONFIG_FILE=keepalived.conf

read -p "Install for Nginx or Tomcat?[n/t]" answer
if [[ $answer != t ]] && [[ $answer != T ]];then
   CONFIG_FILE_MASTER=keepalived_nginx_m.conf
   CONFIG_FILE_SLAVE=keepalived_nginx_s.conf
else
   CONFIG_FILE_MASTER=keepalived_tomcat_m.conf
   CONFIG_FILE_SLAVE=keepalived_tomcat_s.conf
fi

#Check Networking
ping mirrors.aliyun.com -c 2
if [ "$?" -ne 0 ];then
   echo "[`date '+%Y-%m-%d %H:%M:%S'`] Can't connect to Internet,please check."
   exit
fi

#Check Config File Exist
if [ ! -f $SOURCE_PATH/$CONFIG_FILE_MASTER ] || [ ! -f $SOURCE_PATH/$CONFIG_FILE_SLAVE ];then
   echo "[`date '+%Y-%m-%d %H:%M:%S'`] Config File doesn't exist,please check."
   exit
fi

#Clean and Make Yum Cache
yum clean all
yum makecache

#Install keepalived
yum install keepalived -y

#Copy Config File
read -p "Enter Install as Master/Slave:[m/s]" answer
if [ $answer == "m" ] || [ $answer == "M" ];then
   \cp $SOURCE_PATH/$CONFIG_FILE_MASTER /etc/keepalived/keepalived.conf
else
   \cp $SOURCE_PATH/$CONFIG_FILE_SLAVE /etc/keepalived/keepalived.conf
fi

#Enter Local IP
read -p "Enter Local IP:" answer
SERVER_ID=`echo $answer|awk -F'.' '{print $4}'`

#Change Router_ID
sed -i "s/LVS_DEVEL/LVS_$SERVER_ID/g" /etc/keepalived/keepalived.conf 

#Enter Master IP
read -p "Enter Master IP:" answer
MASTER_ID=`echo $answer|awk -F'.' '{print $4}'`

#Change Virtual Router ID
sed -i "s/virtual_router_id 0/virtual_router_id $MASTER_ID/g" /etc/keepalived/keepalived.conf


#Enter Interface Name
read -p "Enter Interface Name[ens160]:" answer
if [ ! -z $answer ];then
   INTERFACE=`echo $answer|awk -F'.' '{print $4}'`
   sed -i "s/interface ens160/interface $INTERFACE/g" /etc/keepalived/keepalived.conf
else
   INTERFACE=ens160
fi

#Enter Virtual IP
read -p "Enter Virtual IP:" answer
sed -i "s/vip_192.168.0.1/$answer/g" /etc/keepalived/keepalived.conf

#Add Port to Firewall
systemctl status firewalld
if [ $? -ne 0 ];then
   systemctl start firewalld
fi
firewall-cmd --direct --permanent --add-rule ipv4 filter OUTPUT 0 --out-interface $INTERFACE --destination 224.0.0.18 --protocol vrrp -j ACCEPT

firewall-cmd --direct --permanent --add-rule ipv4 filter INPUT 0 --in-interface $INTERFACE --destination 224.0.0.18 --protocol vrrp -j ACCEPT
firewall-cmd --reload

#Set Sysctl Param
cat >> /etc/sysctl.conf <<EOF
net.ipv4.ip_forward = 1
EOF
sysctl -p

#Start Service
systemctl start keepalived

#Set Auto Start
systemctl enable keepalived
 
#Show Status
systemctl status keepalived
