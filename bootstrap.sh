#!/bin/bash
# vim:set tabstop=4 shiftwidth=4 softtabstop=4 foldmethod=marker:
#
# This boostraps the dev environment (port from TGIFramework
# <https://github.com/tychay/TGIFramework>).
#
# To use, start with a vanilla install of ubuntu server, drop this in and run
# $ ./install

SUDO='sudo'
HOSTNAME="terrychay-dev"
EMAIL="tychay@php.net"
DEV_DIR="/media/psf/terrychay-dev"
CONFIG_DIR="${DEV_DIR}/configs"
SSH_KEY="/media/psf/terrychay-dev/key.pem"
BITNAMI_ADDR="bitnami@terrychay.bitnamiapp.com"
BITNAMI_WORDPRESS_HTDOCS="/home/bitnami/apps/wordpress/htdocs"
BITNAMI_PHPMYADMIN_HTDOCS="/home/bitnami/apps/phpmyadmin/htdocs"
WORDPRESS_DIR="${DEV_DIR}/wordpress/htdocs"
PHPMYADMIN_DIR="${DEV_DIR}/phpmyadmin/htdocs"
BITNAMI_PHPMYADMIN_CONFIG="/home/bitnami/apps/phpmyadmin/htdocs/config.inc.php"
MYSQL_PORT="3306"

# functions {{{
check_dpkg() { dpkg -l $1 | grep ^ii | wc -l; }
is_eth0() { ifconfig | grep eth0 | wc -l; }
get_ip() { ifconfig | grep 'inet addr' |  awk -F: '{ print $2 }' | awk '{ print $1 }' | grep -v 127.0.0.1; }
pear_installed() { pear list -a | grep ^$1 | wc -l ; }
test_port() { netstat -pln | grep :$1 | wc -l;  }
PHP_EXT_TEST=./extension_installed.php
# {{{  pecl_update_or_install()
# $1 = package name
# $2 = package name in pecl (may have -beta or the like)
# $3 = if set, package name in ubuntu
pecl_update_or_install () {
	if [ `$PHP_EXT_TEST $1` ]; then
		if [ $DO_UPGRADE ]; then
			if [ "$3" != '' ]; then
				echo "### Updating $1...";
				$SUDO apt-get update $3
			else
				echo "### Upgrading $1...";
				$SUDO pecl upgrade $2
			fi
		fi
	else
		echo "### Installing $1...";
		if [ "$3" != '' ]; then
			$SUDO apt-get install $3
		else
			$SUDO pecl install $2
			if [ "$1" = 'xdebug' ]; then
				echo '### Be sure to add to your php.ini: zend_extension="<something>/xdebug.so" NOT! extension=xdebug.so'
			else
				echo "### Be sure to add to your php.ini: extension=$1.so"
				# Let's add config for stuff manually
				echo "extension=${1}.so" | $SUDO tee /etc/php5/conf.d/${1}.ini
				$SUDO cp /etc/php5/conf.d/${1}.ini /etc/php5/conf.d/${1}.ini
			fi
		fi
		PACKAGES_INSTALLED="$1 $PACKAGES_INSTALLED"
	fi
}
# }}}
# }}}
# Set up environment ($EDITOR) {{{
#DO_UPGRADE='1' #Set this to upgrade
if [ !$EDITOR ]; then
	echo -n "### Choose your preferred editor: "
	read EDITOR
	EDITOR=`which ${EDITOR}`
fi
if [ $EDITOR = '' ]; then
	EDITOR="/usr/bin/pico"
fi
# }}}
# $2 = CONFIG_DIR {{{
if [ $2 ]; then
	CONFIG_DIR=$2
fi
if [ ! $CONFIG_DIR ]; then
	echo -n "### Set directory to store configs: "
	read CONFIG_DIR
fi
# }}}
# Fix broken networking on clone {{{
if [ `is_eth0` = 0 ]; then
	echo "### Your networking is broken."
	echo "### Odds are because you have the parent image  MAC address."
	echo -n '### Delete the first PCI line, In second replace NAME="eth1" with NAME="eth0":'
	read IGNORE
	$SUDO $EDITOR  /etc/udev/rules.d/70-persistent-net.rules
	echo "### Rebooting in order to rebuild networking from startup rules..."
	$SUDO reboot
fi
# }}}
# Computer renaming (set $HOSTNAME) {{{
if [ $HOSTNAME ]; then
	if [ `cat /etc/hostname` != $HOSTNAME ]; then
		echo "$HOSTNAME" | $SUDO tee /etc/hostname
		echo "127.0.0.1   $HOSTNAME" | $SUDO tee -a /etc/hosts
		echo -n "### You may want to clean up this file to remove old hostnames:"
		read IGNORE
		$SUDO $EDITOR /etc/hosts
		echo -n "### Reboot for hostname to take effect: "
		read IGNORE
		# Reboot for hostname to take effect
		$SUDO reboot
	fi
fi
HOSTNAME=`cat /etc/hostname`
# }}}
IP_ADDRESS=`get_ip`
echo "### Your IP address is ${IP_ADDRESS}"
echo "### Updating apt-get (control-c to skip)..."
$SUDO apt-get update
# Install LAMP {{{
# http://www.howtoforge.com/ubuntu_lamp_for_newbies
if [ `check_dpkg apache2` = 0 ]; then
	echo "### Installing apache2..."
	$SUDO apt-get install apache2
	echo "### You may want to add the following line to your client's /etc/hosts"
	echo "$IP_ADDRESS   $HOSTNAME"
	echo -n "### Test out Apache by going to http://${IP_ADDRESS}/:"
	read IGNORE
fi
if [ `check_dpkg libapache2-mod-php5` = 0 ]; then
	echo "### Installing php..."
	$SUDO apt-get install php5 libapache2-mod-php5
	$SUDO service apache2 graceful
	echo "<?php phpinfo(); ?>" | $SUDO tee /var/www/phpinfo.php
	echo -n "### Test out Apache by going to http://${IP_ADDRESS}/phpinfo.php:"
	read IGNORE
fi
if [ `check_dpkg mysql-server` = 0 ]; then
	echo "### Installing mysql..."
	$SUDO apt-get install mysql-server
	echo "### (Optional) May want to add"
	echo "bind-address = ${IP_ADDRESS}"
	echo -n "### so outside IPs can bind:"
	read IGNORE
	if [ $EDITOR == '/usr/bin/vim' ]; then
		$SUDO $EDITOR /etc/mysql/my.cnf +53
	else
		$SUDO $EDITOR /etc/mysql/my.cnf
	fi
	sudo service mysql restart
fi
if [ `check_dpkg phpmyadmin` = 0 ]; then
	echo "### Installing phpmyadmin interfaces..."
	$SUDO apt-get install libapache2-mod-auth-mysql php5-mysql phpmyadmin
	$SUDO service apache2 graceful
	echo -n "### Test out PHPMyAdmin by going to http://${IP_ADDRESS}/phpmyadmin/:"
	read IGNORE
fi
echo "### LAMP installed"
# }}}
# Install PHP Compile environment {{{
# http://ubuntuforums.org/showthread.php?t=525257
if [ `check_dpkg php5-dev` = 0 ]; then
	echo "### Installing PHP dev libraries..."
	$SUDO apt-get install php5-dev
fi
if [ `check_dpkg php-pear` = 0 ]; then
	echo "### Installing PEAR libraries..."
	$SUDO apt-get install php-pear
fi
# }}}
PACKAGES_INSTALLED=""
if [ ! -d 'build' ]; then
	mkdir build
fi
# Install key packages {{{
# Install Git {{{
# Needed to generate version numbers and sync git repositories
if [ `check_dpkg git` ]; then
	echo "### Installing git..."
	$SUDO apt-get install git
fi
pecl_update_or_install curl curl php5-curl
# }}}
# Install Zip {{{
# Needed to unzip packages
if [ `check_dpkg zip` ]; then
	echo "### Installing zip..."
	$SUDO apt-get install zip
fi
pecl_update_or_install curl curl php5-curl
# }}}
# Install ack-grep {{{
# Assist in searching in developmetn
if [ `check_dpkg ack-grep` ]; then
	echo "### Installing ack-grep..."
	$SUDO apt-get install ack-grep
fi
# }}}
# Install curl {{{
# Need curl to grab downloads
if [ `check_dpkg curl` ]; then
	echo "### Installing curl..."
	$SUDO apt-get install curl
fi
pecl_update_or_install curl curl php5-curl
# }}}
# }}}
# Install PHP and Apache extensions {{{
# turn on mod_rewrite {{{
# http://troy.jdmz.net/rsync/index.html
echo "### Turning on mod_rewrite in apache (needed for wordpress MU domains)..."
$SUDO a2enmod rewrite
# }}}
# Install intl {{{
pecl_update_or_install intl intl php5-intl
# }}}
# Install APC {{{
pecl_update_or_install apc apc-beta php-apc
# }}}
# Install igbinary (used for libmemcached) {{{
pecl_update_or_install igbinary igbinary
# }}}
# Install memcached (with igbinary) {{{
# http://www.neanderthal-technology.com/2011/11/ubuntu-10-install-php-memcached-with-igbinary-support/
# TODO: -enable-memcached-igbinary (in php-pecl-memcached)
if [ `check_dpkg libmemcached6` = 0 ]; then
	echo "### Installing libmemcached libraries..."
	$SUDO apt-get install libmemcached6 libmemcached-dev
fi
if [ `$PHP_EXT_TEST memcached` ]; then
	# TODO: upgrade memcached?
	if [ $DO_UPGRADE ]; then
		echo '### Add upgrader for memcached here?'
	fi
else
	echo "### Installing memcached extension..."
	pushd build
	if [ ! -f memcached-*.tgz ]; then
		$SUDO pecl download memcached
	fi
	if [ ! -d memcached-* ]; then
		tar zxf memcached-*.tgz
		rm -f packet.xml channel.xml
	fi
	pushd memcached-*
		phpize
		chmod a+x configure
		./configure -enable-memcached-igbinary --with-libmemcached-dir=/usr
		make
		$SUDO make install
		echo "### Be sure to add to your php.ini: extension=memcached.so"
		echo "extension=memcached.so" | $SUDO tee /etc/php5/conf.d/memcached.ini
		$SUDO cp /etc/php5/conf.d/memcached.ini /etc/php5/conf.d/memcached.ini
		PACKAGES_INSTALLED="memcached $PACKAGES_INSTALLED"
	popd
	popd
fi
# }}}
# Install XDEBUG {{{
pecl_update_or_install xdebug xdebug php5-xdebug
# }}}
# Install Graphviz (used for showing callgraphs in inclued or xhprof) {{{
if [ `check_dpkg graphviz` = 0 ]; then
	echo "### Installing GraphViz...";
	$SUDO apt-get install graphviz
fi
# }}}
# Install inclued {{{
# No fedora package for inclued
INCLUED='inclued-beta' #2010-02-22 it went beta, see http://pecl.php.net/package/inclued
pecl_update_or_install inclued $INCLUED
# }}}
# Install xhprof (facebook) {{{
# http://stojg.se/notes/install-xhprof-for-php5-on-centos-ubuntu-and-debian/
# https://github.com/facebook/xhprof
XHPROF_URL="https://github.com/facebook/xhprof/zipball/master"
XHPROF_ZIP="facebook-xhprof.zip"
if [ `$PHP_EXT_TEST xhprof` ]; then
	if [ $DO_UPGRADE ]; then
		# TODO: upgrade xhprof?
		echo '### Add upgrader for xhprof here?'
	fi
else
	echo "### Installing xhprof extension..."
	pushd build
	if [ ! -f $XHPROF_ZIP ]; then
		echo "### Downloading xhprof from Facebook GitHub..."
		curl -L -o ${XHPROF_ZIP} ${XHPROF_URL}
	fi
	if [ ! -d 'facebook-xhprof-*' ]; then
		unzip $XHPROF_ZIP
	fi
	pushd facebook-xhprof-*/extension
		phpize
		chmod a+x configure
		./configure
		make
		$SUDO make install
		echo "### Be sure to add to your php.ini: extension=xhprof.so"
		echo "extension=xhprof.so" | $SUDO tee /etc/php5/conf.d/xhprof.ini
		$SUDO cp /etc/php5/conf.d/xhprof.ini /etc/php5/conf.d/xhprof.ini
		PACKAGES_INSTALLED="xhprof $PACKAGES_INSTALLED"
	popd
	popd
fi
# }}}
# Install XHGUI {{{
# http://blog.preinheimer.com/index.php?/archives/355-A-GUI-for-XHProf.html
# https://github.com/preinheimer/xhprof
# http://phpadvent.org/2010/profiling-with-xhgui-by-paul-reinheimer
XHPROF_GUI_GIT="git://github.com/preinheimer/xhprof.git"
XHPROF_GUI="xhprof_lib"
if [ ! -d build/${XHPROF_GUI} ]; then
	echo "### Downloading XHGui...."
	pushd build
		git clone $XHPROF_GUI_GIT
	popd
fi
# TODO: install xhprof gui (a la phpmyadmin)
# }}}
# TODO: Webgrind
# }}}
# Set up webserver with remote {{{
# sync wordpress htdocs over {{{
# http://troy.jdmz.net/rsync/index.html
if [ ! -d $WORDPRESS_DIR ]; then
	echo "### Syncing over wordpress htdocs..."
	rsync -az -e "ssh -i ${SSH_KEY}" ${BITNAMI_ADDR}:${BITNAMI_WORDPRESS_HTDOCS} ${DEV_DIR}/wordpress
fi
# symlinks break in parallels filesystem :-(
if [ ! -f $WORDPRESS_DIR/wordpress/htdocs/wp-content/sunrise.php ]; then
	echo "### Fixing broken symlink (sunrise.php for domain mapping)..."
	cp $WORDPRESS_DIR/wordpress/htdocs/wp-content/mu-plugins/wordpress-mu-domain-mapping/sunrise.php $WORDPRESS_DIR/wordpress/htdocs/wp-content/sunrise.php
fi
if [ ! -f $WORDPRESS_DIR/wordpress/htdocs/wp-content/mu-plugins/domain_mapping.php ]; then
	echo "### Fixing broken symlink (domain_mapping.php for domain mapping)..."
	cp $WORDPRESS_DIR/wordpress/htdocs/wp-content/mu-plugins/wordpress-mu-domain-mapping/domain_mapping.php $WORDPRESS_DIR/wordpress/htdocs/wp-content/mu-plugins/domain_mapping.php
fi
# }}}
# set up ssh tunnel to mysqld {{{
# turn off mysql: http://askubuntu.com/questions/40072/how-to-stop-apache2-mysql-from-starting-automatically-as-computer-starts
if [ ! -f /etc/init/mysql.override ]; then
	echo "### Turning off startup of mysqld..."
	echo "manual" | $SUDO tee /etc/init/mysql.override
fi
$SUDO /etc/init.d/mysql stop
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
echo -n "### Tunnel infomation above:"
read IGNORE
# }}}
# phpmyadmin  {{{
# http://sourceforge.net/projects/phpmyadmin/forums/forum/72909/topic/3697310
#cp /etc/phpmyadmin/apache.conf ${CONFIG_DIR}/apache2.d/phpmyadmin.conf
#$SUDO mv /etc/phpmyadmin/config-db.php /etc/phpmyadmin/config-db.php.local
#$SUDO ln -s /etc/phpmyadmin
if [ ! -d $PHPMYADMIN_DIR ]; then
	echo "### Syncing over phpmyadmin htdocs..."
	rsync -az -e "ssh -i ${SSH_KEY}" ${BITNAMI_ADDR}:${BITNAMI_PHPMYADMIN_HTDOCS} ${DEV_DIR}/phpmyadmin
fi
if [ `grep localhost ${PHPMYADMIN_DIR}/config.inc.php` ]; then
	echo "### repairing the config file for phpmyadmin..."
	$SUDO cat ${PHPMYADMIN_DIR}/config.inc.php | sed "s|localhost|127.0.0.1|" > ${PHPMYADMIN_DIR}/config.inc.php
fi
# }}}
# }}}
# Move and set up configs {{{
if [ ! -d $CONFIG_DIR ]; then
	echo -n "### If you wish to change the hostname (cloned an instance), please type in subdomain name: "
	mkdir $CONFIG_DIR
fi
# php config directory {{{
echo "### Binding PHP configuration directory..."
pushd /etc/php5
	if [ ! -d $CONFIG_DIR/phpconf.d ]; then
		cp -r conf.d $CONFIG_DIR/phpconf.d
	fi
	pushd cli
		$SUDO rm conf.d
		$SUDO ln -s $CONFIG_DIR/phpconf.d conf.d
	popd
	pushd apache2
		$SUDO rm conf.d
		$SUDO ln -s $CONFIG_DIR/phpconf.d conf.d
	popd
popd
# }}}
# apache config directory {{{
echo "### Binding Apache configuration directory..."
pushd /etc/apache2
	if [ ! -d $CONFIG_DIR/apache2.d ]; then
		cp -r sites-enabled $CONFIG_DIR/apache2.d
	fi
	if [ ! -h post-load ]; then
		ln -s 
		$SUDO ln -s $CONFIG_DIR/apache2.d post-load
	fi
	if [ ! -f apache2.conf.orig ]; then
		echo "### Reconfiguring apache to use new directory..."
		$SUDO mv apache2.conf apache2.conf.orig
		$SUDO cat apache2.conf.orig | sed "s|sites-enabled|post-load|" | $SUDO tee apache2.conf
	fi
popd
# }}}
# populate apache config {{{
pwd
if [ ! -f $CONFIG_DIR/apache2.d/wordpress.conf ]; then
	echo "### Adding wordpress apache config..."
	cat conf/wordpress.conf | sed "s|{{{HTDOCS_DIR}}}|${WORDPRESS_DIR}|" | sed "s|{{{EMAIL}}}|${EMAIL}|" > ${CONFIG_DIR}/apache2.d/wordpress.conf
fi
if [ ! -f $CONFIG_DIR/apache2.d/phpmyadmin.conf ]; then
	echo "### Adding phpmyadmin apache config..."
	cat conf/phpmyadmin.conf | sed "s|{{{HTDOCS_DIR}}}|${PHPMYADMIN_DIR}|" | sed "s|{{{EMAIL}}}|${EMAIL}|" > ${CONFIG_DIR}/apache2.d/phpmyadmin.conf
fi
# }}}
# }}}

if [ "$PACKAGES_INSTALLED" ]; then
	echo '### You may need to add stuff to your $PHP_INI (or /etc/php.d/) and restart'
	echo "###  $PACKAGES_INSTALLED"
fi
$SUDO service apache2 graceful
exit
