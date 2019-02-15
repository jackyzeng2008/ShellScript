#!/bin/bash
#Run this script under "root" account

LOGROTATE_DIR=/etc/logrotate.d/
TOMCAT_LOGROTATE_DIR=$LOGROTATE_DIR/tomcat
TOMCAT_LOG_DIR=/opt/tomcat/logs/catalina.out

#Create Nginx File
cat > $TOMCAT_LOGROTATE_DIR <<EOF
$TOMCAT_LOG_DIR {
   copytruncate
   daily  
   rotate 7
   compress
   missingok
   size 5M
}
EOF

#Add to Crontab

