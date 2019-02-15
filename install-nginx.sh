#!/bin/bash
#Run this script under "root" account

PORT=80

#Check Networking
ping mirrors.aliyun.com -c 2
if [ "$?" -ne 0 ];then
  echo "[`date '+%Y-%m-%d %H:%M:%S'`] Can't connect to Internet,please check."
  exit
fi

#Clean and Make Yum Cache
yum clean all
yum makecache

#Install Nginx
yum install nginx -y

#copy_nginx_config_file= [ `\cp -f ./nginx/nginx.conf /etc/nginx` ] && `\cp -f ./nginx/default.conf /etc/nginx/conf.d`
\cp -f ./nginx/nginx.conf /etc/nginx
\cp -f ./nginx/default.conf /etc/nginx/conf.d

#Create Nginx Status File for Keepalived
mkdir -p /opt/nginx
echo '#!/bin/bash' > /opt/nginx/chk_nginx.sh
echo "[[ \`systemctl is-active nginx\` != active ]] && exit 1 || exit 0" >> /opt/nginx/chk_nginx.sh
chmod +x /opt/nginx/chk_nginx.sh

#Add Port to Firewall
systemctl status firewalld
if [ $? -ne 0 ];then
   systemctl start firewalld
fi
firewall-cmd --add-port=$PORT/tcp --permanent --zone=public
firewall-cmd --reload

#Start Nginx
systemctl start nginx

#Set Auto Start
systemctl enable nginx
