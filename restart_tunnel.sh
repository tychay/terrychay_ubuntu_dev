#!/bin/bash
# vim:set tabstop=4 shiftwidth=4 softtabstop=4 foldmethod=marker:
#
# This boostraps the dev environment (port from TGIFramework
# <https://github.com/tychay/TGIFramework>).
#
# To use, start with a vanilla install of ubuntu server, drop this in and run
# $ ./install

SUDO='sudo'
SSH_KEY="{{SSH_KEY}}"
BITNAMI_ADDR="{{BITNAMI_ADDR}}"
BITNAMI_PHPMYADMIN_CONFIG="{{BITNAMI_PHPMYADMIN_CONFIG}}"
MYSQL_PORT="{{MYSQL_PORT}}"
test_port() { netstat -pln | grep :$1 | wc -l;  }

# set up ssh tunnel to mysqld {{{
if [ test_port 3306 != '0' ]; then
	echo "### Turning on port forwarding for mysql"
	ssh -N -L ${MYSQL_PORT}:127.0.0.1:${MYSQL_PORT} -i ${SSH_KEY} ${BITNAMI_ADDR} &
fi
#echo "### Turning on stunnel for mysql"
#if [ `check_dpkg stunnel` ]; then
#	echo "### Installing stunnel..."
#	$SUDO apt-get install stunnel
#fi
# http://www.kutukupret.com/2009/09/20/securing-mysql-traffic-with-stunnel/
# https://www.siamnet.org/Wiki/Ubuntu-SettingUpStunnel
# http://www.edna.narrabilis.com/2006/06/01/stunnel-for-mysql-server-and-client/
#cp ... /etc/stunnel/stunnel.conf
#vim /etc/default/stunnel4 (sed /ENABLED=0/ENABLED=1/)
# /etc/init.d/stunnel4 restart
netstat -pln | grep :3306
# }}}
