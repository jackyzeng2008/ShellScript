#!/bin/bash
#Run this script under "root" account

#Change SELINUX to Disabled
sed -i 's/^SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

#Set SELINUX disabled temp
setenforce 0

#Start Firewall
systemctl restart firewalld

#Set Firewall Auto Start
systemctl enable firewalld

#Update Linux Limits
cat >> /etc/security/limits.conf <<EOF

#Set Limits
*  soft core unlimit
*  hard core unlimit
*  soft fsize unlimit
*  hard fsize unlimit
*  soft data unlimit
*  hard data unlimit
*  soft nproc 65535
*  hard nproc 65535
*  soft stack unlimited
*  hard stack unlimited
*  soft nofile 409600
*  hard nofile 409600
EOF

