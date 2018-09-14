#!/bin/bash
# уже забыл что это -- что-то вроде разворачивания с нуля для Цента, надо освежить....

username=mailer

yum install epel-release -y
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm

yum -y update
yum -y install nano htop perl firewalld pwgen mailx httpd-itk mariadb-server php php-imap php-mysqli proftpd fail2ban

### IPV6 OFF
sed -i 's/net.ipv6.conf.all.disable_ipv6=0/net.ipv6.conf.all.disable_ipv6=1/' /etc/sysctl.conf
sysctl -p

### FIREWALL

service firewalld start

### USER
password=$(pwgen -Bc 10 1)
egrep "^$username" /etc/passwd >/dev/null
if [ $? -eq 0 ]; then
        echo "User $username exists!"
        exit 1
else
        pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
        useradd -s /bin/bash -m -p $pass $username
        usermod -aG wheel $username
        userhome=$(eval echo ~$username)
        mkdir -p $userhome/script
        chown $username:$username $userhome/script
        chmod 750 $userhome
        chmod 750 $userhome/script
        mkdir -p $userhome/logs
        chown $username:$username $userhome/logs
        chmod 750 $userhome/logs
        echo "$username created"
        echo
fi

### PROFTPD
egrep "^UseIPv6" /etc/proftpd.conf >/dev/null
if [ ! $? -eq 0 ]; then
echo "UseIPv6 off" >> /etc/proftpd.conf
fi

egrep "^PassivePorts" /etc/proftpd.conf >/dev/null
if [ ! $? -eq 0 ]; then
echo "PassivePorts 60000 61000" >> /etc/proftpd.conf
fi

systemctl enable proftpd
service proftpd restart
firewall-cmd --permanent --add-port=20-21/tcp
firewall-cmd --permanent --add-port=60000-61000/tcp

### SSH SERVER CONFIG PATCH
sshd_conf=/etc/ssh/sshd_config
sed -i 's/#Port 22/Port 22000/' $sshd_conf
sed -i '/#PermitRootLogin/ s/#PermitRootLogin yes/PermitRootLogin no/' $sshd_conf
sed -i '/PasswordAuthentication/ s/yes/no/' $sshd_conf
echo "SSHD CONFIG CHANGES:"
grep ^Port $sshd_conf
grep ^Permit $sshd_conf
grep ^Password $sshd_conf
echo
firewall-cmd --permanent --add-port=22000/tcp
service sshd reload

### SSH CLIENT KEYS
mkdir -m 700 $userhome/.ssh
ssh-keygen -t rsa -b 4096 -P$password -f $userhome/.ssh/id_rsa
cat $userhome/.ssh/id_rsa.pub > $userhome/.ssh/authorized_keys
chown -R $username:$username $userhome/.ssh
chmod 600 $userhome/.ssh/*

### PHP
echo "date.timezone = 'UTC'" >> /etc/php.ini
echo "session.save_path = /tmp" >> /etc/php.ini

### APACHE

echo "
<VirtualHost *:80>

    AssignUserID $username $username
    DocumentRoot $userhome/script
    <Directory $userhome/script>
        AllowOverride All
        Order Allow,Deny
        Allow from All
        Require all granted
    </Directory>

    ErrorLog $userhome/logs/error.log
    CustomLog $userhome/logs/access.log combined
</VirtualHost>
" > /etc/httpd/conf.d/welcome.conf

echo "
<?php phpinfo(); ?>
" > $userhome/script/index.php
chown $username:$username $userhome/script/index.php

echo "
LoadModule mpm_itk_module modules/mod_mpm_itk.so
" > /etc/httpd/conf.modules.d/00-mpm-itk.conf

systemctl enable httpd
service httpd restart

firewall-cmd --permanent --add-port=80/tcp

### MYSQL
passwordmysql=$(pwgen -Bc 10 1)
systemctl enable mariadb
service mariadb restart
passwordmysqlroot=$(pwgen -Bc 10 1)
mysql --silent -uroot -e "create database mailerdb; GRANT ALL PRIVILEGES ON mailerdb.* TO mailer@localhost IDENTIFIED BY '$passwordmysql'"
mysql --silent -uroot -e "use mysql;UPDATE user SET password=PASSWORD('$passwordmysqlroot') WHERE User='root' AND Host = 'localhost';flush privileges;"
mysql -umailer -p"$passwordmysql" mailerdb < ./checkmail.sql
### CONFIG
echo "
<?php
date_default_timezone_set('Europe/Berlin');
ini_set('display_errors',1);
ini_set('display_startup_errors',1);
error_reporting(E_ALL);
define('DIR', __DIR__);
define('DB_NAME', 'mailerdb'); // имя базы
define('DB_HOST', 'localhost'); // размещение базы
define('DB_USER_NAME', 'mailer'); // имя пользователя
define('DB_USER_PASSWORD', '$passwordmysql'); // пароль пользователя

define('MAIL_IMAP_HOST', '{imap.gmail.com:993/imap/ssl/novalidate-cert}Inbox'); // путь подключения к IMAP серверу
define('MAIL_SMTP_HOST', 'ssl://smtp.gmail.com');
define('MAIL_USER', '');
define('MAIL_PASSWORD', '');
" > $userhome/script/config.php
chown $username:$username $userhome/script/config.php

### CRONTAB
echo "
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

#каждые 10 сек
* * * * * php /home/$username/script/index.php home runcheck > /dev/null
* * * * * (sleep 10; php /home/$username/script/index.php home runcheck) > /dev/null
* * * * * (sleep 20; php /home/$username/script/index.php home runcheck) > /dev/null
* * * * * (sleep 30; php /home/$username/script/index.php home runcheck) > /dev/null
* * * * * (sleep 40; php /home/$username/script/index.php home runcheck) > /dev/null
* * * * * (sleep 50; php /home/$username/script/index.php home runcheck) > /dev/null

#каждые 30 сек
* * * * * php /home/$username/script/index.php home runtask > /dev/null
* * * * * (sleep 30; php /home/$username/script/index.php home runtask) > /dev/null
" > $userhome/crontab
crontab -u"$username" $userhome/crontab
rm $userhome/crontab

### CREDS

echo "
USER:   $username
PASS:   $password

DB:     mailerdb
DBPASS: $passwordmysql

MYSQL ROOT PASS: $passwordmysqlroot

FTPUSER:$username
FTPPASS:$password
" > $userhome/CREDS.TXT
chown $username:$username $userhome/CREDS.TXT

cp $userhome/CREDS.TXT /root

cat /root/CREDS.TXT

firewall-cmd --reload
