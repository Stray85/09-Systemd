#!/bin/bash
echo 'WORD=ALERT
LOG=/var/log/watchlog.log' > /etc/sysconfig/watchlog
echo ALERT > /var/log/watchlog.log

echo '#!/bin/bash
WORD=$1
LOG=$2
DATE=`date`
if grep $WORD $LOG &> /dev/null
then
logger "$DATE: I found word, Master!"
else
exit 0
fi' > /opt/watchlog.sh 

chmod +x /opt/watchlog.sh

echo '[Unit]
Description=My watchlog service
[Service]
Type=oneshot
EnvironmentFile=/etc/sysconfig/watchlog
ExecStart=/opt/watchlog.sh $WORD $LOG' > /usr/lib/systemd/system/watchlog.service

echo '[Unit]
Description=Run watchlog script every 30 second
[Timer]
# Run every 30 second
OnUnitActiveSec=30
Unit=watchlog.service
[Install]
WantedBy=multi-user.target' > /usr/lib/systemd/system/watchlog.timer

systemctl start watchlog.timer

yum -y install epel-release && yum -y install spawn-fcgi php php-cli nano

echo 'SOCKET=/var/run/php-fcgi.sock
OPTIONS="-u apache -g apache -s $SOCKET -S -M 0600 -C 32 -F 1 -- /usr/bin/php-cgi"' > /etc/sysconfig/spawn-fcgi

echo '[Unit]
Description=Spawn-fcgi startup service by Otus
After=network.target
[Service]
Type=simple
PIDFile=/var/run/spawn-fcgi.pid
EnvironmentFile=/etc/sysconfig/spawn-fcgi
ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS
KillMode=process
[Install]
WantedBy=multi-user.target' > /etc/systemd/system/spawn-fcgi.service
systemctl start spawn-fcgi

echo '[Unit]
Description=The Apache HTTP Server
Wants=httpd-init.service
After=network.target remote-fs.target nss-lookup.target httpdinit.service
Documentation=man:httpd.service(8)
[Service]
Type=notify
Environment=LANG=C
EnvironmentFile=/etc/sysconfig/httpd-%I
ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
# Send SIGWINCH for graceful stop
KillSignal=SIGWINCH
KillMode=mixed
PrivateTmp=true
[Install]
WantedBy=multi-user.target' > /usr/lib/systemd/system/httpd@first.service

echo '[Unit]
Description=The Apache HTTP Server
Wants=httpd-init.service
After=network.target remote-fs.target nss-lookup.target httpdinit.service
Documentation=man:httpd.service(8)
[Service]
Type=notify
Environment=LANG=C
EnvironmentFile=/etc/sysconfig/httpd-%I
ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
# Send SIGWINCH for graceful stop
KillSignal=SIGWINCH
KillMode=mixed
PrivateTmp=true
[Install]
WantedBy=multi-user.target' > /usr/lib/systemd/system/httpd@second.service

echo 'OPTIONS=-f conf/first.conf' > /etc/sysconfig/httpd-first
echo 'OPTIONS=-f conf/second.conf' > /etc/sysconfig/httpd-second

cp /vagrant/first.conf /etc/httpd/conf/first.conf
cp /vagrant/second.conf /etc/httpd/conf/second.conf


systemctl start httpd@first
systemctl start httpd@second