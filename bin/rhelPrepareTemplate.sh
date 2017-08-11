#!/bin/sh
# Steps to clean a VM template before deploying
# Based on the document "Preparing Linux Template VMs"
#  by Bob Plankers on 20130326

# Remove template yum files
/usr/bin/yum clean all

# Remove template logs
/usr/sbin/logrotate -f /etc/logrotate.conf
/bin/rm -f /var/log/*-???????? /var/log/*.gz

# Clear template audit files
/usr/sbin/service auditd stop
/bin/cat /dev/null > /var/log/audit/audit.log
/bin/cat /dev/null > /var/log/wtmp

# Remove template udev files
/bin/rm -f /etc/udev/rules.d/70*

# Remove template MAC/UUID
/bin/sed -i '/^\(HWADDR\|UUID\)=/d' /etc/sysconfig/network-scripts/ifcfg-eth0

# Remove temp files from template install
/bin/rm -rf /tmp/*
/bin/rm -rf /var/tmp/*

# Remove template ssh keys
/bin/rm -f /etc/ssh/*key*

# Remove template history
/bin/rm -f ~root/.bash_history
unset HISTFILE

#This section will provide additional cleanup after using the postinstall script on a template

/bin/sed -i '/-template/d' /etc/hosts
chkconfig network off
