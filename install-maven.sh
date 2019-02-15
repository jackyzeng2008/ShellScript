#!/bin/bash
#Run this script under "root" account

MAVEN_VERSION=3.6.0
SOURCE_PATH=./maven
SOURCE_FILE_PATH="apache-maven-$MAVEN_VERSION-bin.tar.gz"
SOURCE_FOLDER="apache-maven-$MAVEN_VERSION"
INSTALL_PATH=/opt/maven

#Check Maven File Exist
if [ ! -f $SOURCE_PATH/$SOURCE_FILE_PATH ];then
   echo "[`date '+%Y-%m-%d %H:%M:%S'`] Maven File doesn't exist,please check."
   exit
fi

#Delete Old Maven
rm -rf $INSTALL_PATH

#Remove Maven Env
if [[ `grep M2_HOME /etc/profile` ]];then
   read -p "[`date '+%Y-%m-%d %H:%M:%S'`] Maven Env Exist,Please Remove Manually.[Done/Stop]" answer
   if [ `echo $answer|tr [:upper:] [:lower:]` == "done" ];then
      echo >/dev/null
   else
      echo "[`date '+%Y-%m-%d %H:%M:%S'`] ByeBye..."
      exit
   fi
fi

#Extract Maven File
tar -zxvf $SOURCE_PATH/$SOURCE_FILE_PATH -C $SOURCE_PATH

#Copy new file to $INSTALL_PATH
mv $SOURCE_PATH/$SOURCE_FOLDER $INSTALL_PATH

#Set Maven Env
read -p "Enter MAVEN_HOME:" maven_home
cat >> /etc/profile <<EOF

export M2_HOME=$maven_home
export PATH=\$M2_HOME/bin:\$PATH
EOF

#Make Env Effective
source /etc/profile

echo "[`date '+%Y-%m-%d %H:%M:%S'`] Maven has installed,ByeBye.."
