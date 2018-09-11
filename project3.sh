#!/bin/sh
#########

wwwdir=/var/www

### ENTER

read -p "Enter PROJECT name : " projectname
read -p "Enter user name : " username

password=$(pwgen -Bc 8 1)

### PROJECT TEST

if [ ! -d "$wwwdir/$projectname" ]; then

### USER TEST

egrep "^$username" /etc/passwd >/dev/null
if [ $? -eq 0 ]; then

### MYSQL

mysql --silent -uroot -p"lcPRWvds0" -e "create database $projectname; GRANT ALL PRIVILEGES ON $projectname.* TO $projectname@localhost IDENTIFIED BY '$password'";

### PROJECT DIR SETUP

mkdir -p $wwwdir/$projectname/logs
mkdir -p $wwwdir/$projectname/dumps
mkdir -p $wwwdir/$projectname/web
chmod 750 $wwwdir/$projectname

### APACHE VHOST SETUP

echo "
<VirtualHost *:80>
    ServerName demo-$projectname.zimalab.com

    AssignUserID $username $username

    DocumentRoot $wwwdir/$projectname/web
    <Directory $wwwdir/$projectname/web>
        AllowOverride All
        Order Allow,Deny
        Allow from All
    </Directory>

    ErrorLog $wwwdir/$projectname/logs/error.log
    CustomLog $wwwdir/$projectname/logs/access.log combined
</VirtualHost>
" > /etc/apache2/sites-available/$projectname.conf

echo "<?php echo 'Hello, $username!';?>" > $wwwdir/$projectname/web/index.php
chown -R $username:$username $wwwdir/$projectname

a2ensite $projectname.conf
service apache2 reload

### SAVE PROJECT INFO INTO USER STAT FILE

echo "
Proj:	$projectname
db:	$projectname
dbpass: $password

" >> /root/stat/$username.txt

cat /root/stat/$username.txt

### ADD LINK TO WWW FOR USER

ln -s $wwwdir/$projectname /home/$username

### THE END

echo "Done."

### USER TEST FI
else
	echo "USER $username not found! STOP."
        exit 1
fi

### PROJECT TEST FI
else
	echo "PROJECT $projectname already exist! STOP."
fi
