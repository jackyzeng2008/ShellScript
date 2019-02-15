#!/bin/bash
#Run this script under "root" account

#Check Networking
ping mirrors.aliyun.com -c 2
if [ "$?" -ne 0 ];then
  echo "[`date '+%Y-%m-%d %H:%M:%S'`] Can't connect to Internet,please check."
  exit
fi

#Install JAVA
yum install java java-devel -y

#Set JAVA ENV
read -p "Enter JAVA Home:" answer
if ! grep JAVA_HOME /etc/profile;then
   cat >> /etc/profile <<EOF

#Set JAVA ENV
export JAVA_HOME=$answer
export PATH=\$JAVA_HOME/bin:\$JAVA_HOME/jre/bin:\$PATH
export CLASSPATH=.:\$JAVA_HOME/jre/lib/rt.jar:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar
EOF
fi
