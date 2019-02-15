#!/bin/bash
#Run this script under "root" account

#Check Networking
ping mirrors.aliyun.com -c 2
if [ "$?" -ne 0 ];then
  echo "[`date '+%Y-%m-%d %H:%M:%S'`] Can't connect to Internet,please check."
  exit
fi

#Download Aliyun Yum Repo
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
if [ "$?" -ne 0 ];then
  echo "[`date '+%Y-%m-%d %H:%M:%S'`] Download Aliyun Yum Repo failed,please check Internet connection."
  exit
fi

#Clean and Make Yum Cache
yum clean all
yum makecache
