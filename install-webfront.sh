#!/bin/bash
#Run this script under "root" account

USER=nginx
SOURCE_PATH=./webfrontpkg
INSTALL_PATH=/webroot/x1288

#Check Source File
if [ ! -d $SOURCE_PATH/dist ];then
   echo "[`date '+%Y-%m-%d %H:%M:%S'`] File doesn't exist,please check."
   exit
fi

#Create Project Folder
mkdir -p $INSTALL_PATH

#Delete Old File
rm -rf $INSTALL_PATH/*

#Copy new file to $INSTALL_PATH
\cp -r $SOURCE_PATH/dist/* $INSTALL_PATH

#Change Owner
chown -R $USER:$USER $INSTALL_PATH

#Restart nginx
systemctl restart nginx
