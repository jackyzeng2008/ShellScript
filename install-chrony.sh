#!/bin/bash
#Run this script under "root" account

TIMEZONE=Asia/Shanghai
#TIMEZONE=Europe/Berlin

#Check Networking
ping mirrors.aliyun.com -c 2
if [ "$?" -ne 0 ];then
  echo "[`date '+%Y-%m-%d %H:%M:%S'`] Can't connect to Internet,please check."
  exit
fi

#Clean and Make Yum Cache
yum clean all
yum makecache

#Install Chrony
yum install chrony -y

#Comment out default NTP servers
sed -i 's/^server/#server/g' /etc/chrony.conf

#Add new NTP servers
sed -i '/#server 3/a\server ntp1.aliyun.com iburst' /etc/chrony.conf
sed -i '/^server ntp1/a\server ntp2.aliyun.com iburst' /etc/chrony.conf

#Set TimeZone
timedatectl set-timezone $TIMEZONE

#Start Chrony Service
systemctl start chronyd

#Set Auto Start
systemctl enable chronyd

#Show Time Info
timedatectl
