#!/bin/bash
#Run this script under "root" account

SOURCE_PATH=./epel
EPEL_FILE=epel-release-latest-7.noarch.rpm

#Check Networking
ping mirrors.aliyun.com -c 2
if [ "$?" -ne 0 ];then
  echo "[`date '+%Y-%m-%d %H:%M:%S'`] Can't connect to Internet,please check."
  exit
fi

#Check Epel File Exist
if [ ! -f $SOURCE_PATH/$EPEL_FILE ];then
   echo "[`date '+%Y-%m-%d %H:%M:%S'`] Epel File doesn't exist,please check."
   exit
fi

yum localinstall -y $SOURCE_PATH/$EPEL_FILE
yum clean all
yum makecache
