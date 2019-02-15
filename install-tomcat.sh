#!/bin/bash
#Run this script under "root" account

USER=tomcat
SOURCE_PATH=./tomcat
INSTALL_PATH=/opt/tomcat
TOMCAT_VERSION=8.5.34
CONFIG_FILE_1=conf/server.xml
CONFIG_FILE_2=conf/tomcat-users.xml
CONFIG_FILE_3=conf/web.xml
CONFIG_FILE_4=webapps/manager/META-INF/context.xml
CONFIG_FILE_5=webapps/manager/WEB-INF/web.xml
PORT=8080

#Check Source File
if [ ! -f $SOURCE_PATH/apache-tomcat-$TOMCAT_VERSION.tar.gz ];then
   echo "[`date '+%Y-%m-%d %H:%M:%S'`] Tomcat tar file doesn't exist,please check."
   exit
fi

#Check Tomcat Config File
if [ ! -f $SOURCE_PATH/$CONFIG_FILE_1 ] || [ ! -f $SOURCE_PATH/$CONFIG_FILE_2 ] || [ ! -f $SOURCE_PATH/$CONFIG_FILE_3 ] || [ ! -f $SOURCE_PATH/$CONFIG_FILE_4 ];then
   echo "[`date '+%Y-%m-%d %H:%M:%S'`] Tomcat config file doesn't exist,please check."
   exit
fi

#Delete Old Tomcat file
rm -rf $SOURCE_PATH/apache-tomcat-$TOMCAT_VERSION

#Extract Tomcat tar file
tar -zxvf $SOURCE_PATH/apache-tomcat-$TOMCAT_VERSION.tar.gz -C $SOURCE_PATH

#Check Whether Tomcat Exist Under $INSTALL_PATH
if [ -f $INSTALL_PATH/bin/shutdown.sh ];then
   bash $INSTALL_PATH/bin/shutdown.sh
fi

if [ -d $INSTALL_PATH ];then
   rm -rf $INSTALL_PATH
fi 

#Copy new file to $INSTALL_PATH
mv $SOURCE_PATH/apache-tomcat-$TOMCAT_VERSION $INSTALL_PATH

#Check $USER Exist
id $USER >& /dev/null 
if [ $? -ne 0 ];then
   groupadd $USER
   useradd -r -g $USER -s /bin/false $USER
fi

#Copy Config File to $INSTALL_PATH
\cp $SOURCE_PATH/$CONFIG_FILE_1 $INSTALL_PATH/$CONFIG_FILE_1
\cp $SOURCE_PATH/$CONFIG_FILE_2 $INSTALL_PATH/$CONFIG_FILE_2
\cp $SOURCE_PATH/$CONFIG_FILE_3 $INSTALL_PATH/$CONFIG_FILE_3
\cp $SOURCE_PATH/$CONFIG_FILE_4 $INSTALL_PATH/$CONFIG_FILE_4
\cp $SOURCE_PATH/$CONFIG_FILE_5 $INSTALL_PATH/$CONFIG_FILE_5

#Set PID ENV
echo "CATALINA_PID=/opt/tomcat/tomcat.pid" > $INSTALL_PATH/bin/setenv.sh
echo "JAVA_OPTS=\"-Xms1024m -Xmx1024m -Xss1024K -XX:NewSize=100m -Xmn100m -XX:SurvivorRatio=8 -XX:OldSize=60m -XX:PermSize=50m -XX:MaxPermSize=50m\"" >> $INSTALL_PATH/bin/setenv.sh
chmod 750 $INSTALL_PATH/bin/setenv.sh

#Create Tomcat Status File for Keepalived
echo '#!/bin/bash' > $INSTALL_PATH/bin/chk_tomcat.sh
echo "[[ \`systemctl is-active tomcat\` != active ]] && exit 1 || exit 0" >> $INSTALL_PATH/bin/chk_tomcat.sh
chmod +x $INSTALL_PATH/bin/chk_tomcat.sh

#Change Tomcat Owner
chown -R $USER:$USER $INSTALL_PATH

#Set Tomcat Env
cat >> /etc/profile <<EOF

#Set Tomcat Env
export TOMCAT_HOME=$INSTALL_PATH
export CATALINA_HOME=$INSTALL_PATH
export PATH="\$TOMCAT_HOME/bin:\$PATH"
EOF
source /etc/profile

#Add Port to Firewall
systemctl status firewalld
if [ $? -ne 0 ];then
   systemctl start firewalld
fi
firewall-cmd --add-port=$PORT/tcp --permanent --zone=public
firewall-cmd --reload

#Add Tomcat Service
cat > /usr/lib/systemd/system/tomcat.service <<EOF
[Unit]
Description=Tomcat Service
After=tomcat.service

[Service]
Type=forking
User=tomcat
Group=tomcat
PIDFile=/opt/tomcat/tomcat.pid
ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh
PrivateTmp=yes

[Install]
WantedBy=multi-user.target
EOF
chmod 644 /usr/lib/systemd/system/tomcat.service
systemctl daemon-reload

#Start Tomcat
systemctl start tomcat


#Set Auto Start
systemctl enable tomcat

#Show Tomcat Process
systemctl status tomcat
