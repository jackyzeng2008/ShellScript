#!/bin/bash
#Run this script under "root" account

#Check Networking
ping mirrors.aliyun.com -c 2
if [ "$?" -ne 0 ];then
  echo "[`date '+%Y-%m-%d %H:%M:%S'`] Can't connect to Internet,please check."
  exit
fi

#Clean and Make Yum Cache
yum clean all
yum makecache

#Check Git Exist
if [[ `git --version` ]];then
   echo "[`date '+%Y-%m-%d %H:%M:%S'`] Git has already installed,ByeBye..."   
   exit
else
   echo >/dev/null 
fi

#Install Git
yum -y install git

#Config Git
read -p "Do you want to config Git?[Yes/No]" answer
if [ `echo $answer|tr [:upper:] [:lower:]` == "yes" ];then
   echo >/dev/null
else
   echo "[`date '+%Y-%m-%d %H:%M:%S'`] ByeBye..."
fi

read -p "Enter username:" username
read -p "Enter email:" email

git config --global user.name $username
git config --global user.email $email

#Init Git Folder
read -p "Do you want to Git folder?[Yes/No]" answer
if [ `echo $answer|tr [:upper:] [:lower:]` == "yes" ];then
   echo >/dev/null
else
   echo "[`date '+%Y-%m-%d %H:%M:%S'`] ByeBye..."
fi

read -p "Enter init folder:" initpath
cd $initpath
git init

#Generate SSH Key
read -p "Do you want to generate ssh-key?[Yes/No]" answer
if [ `echo $answer|tr [:upper:] [:lower:]` == "yes" ];then
   echo >/dev/null
else
   echo "[`date '+%Y-%m-%d %H:%M:%S'`] ByeBye..."
fi

ssh-keygen -t rsa -C $email
cat ~/.ssh/id_rsa.pub
