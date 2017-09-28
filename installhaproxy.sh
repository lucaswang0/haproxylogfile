#!/bin/sh
IP=`ip addr|awk '/inet / {print $2}'|awk -F'/' '! /127.0.0.1/ {print $1}'|head -n1`
version=`uname -r|cut -d'.' -f4`

yum -y install openssl-devel readline-devel gcc gcc-c++ zlib-devel pcre-devel

tar xf lua-5.3.3.tar.gz
cd lua-5.3.3
make linux install
cd -

groupadd -g 188 haproxy
useradd -g 188 haproxy
mkdir -p /etc/haproxy /var/lib/haproxy
chown -R haproxy:haproxy /var/lib/haproxy

tar xf haproxy-1.6.9.tar.gz
cd haproxy-1.6.9
make TARGET=linux2628 USE_PCRE=1 USE_OPENSSL=1 USE_ZLIB=1 USE_LUA=1 ARCH=x86-64
make TARGET=linux2628 USE_PCRE=1 USE_OPENSSL=1 USE_ZLIB=1 USE_LUA=1 ARCH=x86-64 install
cd -


sed "s/bind 10.24.3.51:10080/bind $IP:10080/g" haproxy.cfg >/etc/haproxy/haproxy.cfg
touch /etc/sysconfig/haproxy

#Include all config files in /etc/rsyslog.d/
#$IncludeConfig /etc/rsyslog.d/*.conf
echo '
$ModLoad imudp
$UDPServerRun 514
local2.*           /data/ubank/logs/haproxy/haproxy.log' >/etc/rsyslog.d/haproxy.conf
echo '
# Options for rsyslogd
# Syslogd options are deprecated since rsyslog v3.
# If you want to use them, switch to compatibility mode 2 by "-c 2"
# See rsyslogd(8) for more details
SYSLOGD_OPTIONS="-c 2 -r -m 0" ' >/etc/sysconfig/rsyslog


case $version in
el6)
service rsyslog restart
/bin/cp -vp init.d/haproxy /etc/init.d/
chkconfig --add haproxy
chkconfig haproxy on
service haproxy restart
;;
el7)
systemctl restart rsyslog
/bin/cp -vp systemd/haproxy.service /usr/lib/systemd/system/
systemctl enable haproxy.service
systemctl restart haproxy.service
;;
*)
echo not el6 or el7
;;
esac
