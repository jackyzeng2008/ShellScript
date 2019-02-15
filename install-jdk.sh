#!/bin/bash
#Run this script under "root" account

JAVA_VERSION=1.8.0

#Check Networking
ping mirrors.aliyun.com -c 2
if [ "$?" -ne 0 ];then
  echo "[`date '+%Y-%m-%d %H:%M:%S'`] Can't connect to Internet,please check."
  exit
fi

#Clean and Make Yum Cache
yum clean all
yum makecache

#Remove Old JDK/JRE
yum -y remove java*

#Remove rest files
rm -rf /usr/lib/java* /usr/lib/jvm*

#Remove JDK Env
if [[ `grep JAVA_HOME /etc/profile` ]];then
   read -p "[`date '+%Y-%m-%d %H:%M:%S'`] Java Env Exist,Please Remove Manually.[Done/Stop]" answer
   if [ `echo $answer|tr [:upper:] [:lower:]` == "done" ];then
      echo >/dev/null
   else
      exit
   fi
fi

#Install JDK
yum -y install "java-$JAVA_VERSION" "java-$JAVA_VERSION-devel"

#Set JDK Env
read -p "Enter JAVA_HOME:" java_home
cat >> /etc/profile <<EOF

export JAVA_HOME=$java_home
export PATH=\$JAVA_HOME/bin:\$JAVA_HOME/jre/bin:\$PATH
export CLASSPATH=.:\$JAVA_HOME/jre/lib/rt.jar:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar
EOF

#Make Env Effective
source /etc/profile
