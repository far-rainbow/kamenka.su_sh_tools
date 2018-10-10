#!/bin/bash
# DEBIAN/UBUNTU VERSION !!!

rsdir=/root
keysdir=$rsdir/keys
statdir=$rsdir/stat

### KEY DIR TEST

if [ ! -d "$keysdir" ]; then
	mkdir -p $keysdir
	chmod -R 700 $rsdir
fi

if [ ! -d "$statdir" ]; then
        mkdir -p $statdir
        chmod -R 700 $statdir
fi

### ENTER

read -p "Enter username : " username
read -p "Enter password : " password

### USER

egrep "^$username" /etc/passwd >/dev/null
if [ $? -eq 0 ]; then
        echo "$username уже есть в системе!"
        exit 1
else

### GEN PASS & CREATE USER

pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
useradd -s /bin/bash -m -p $pass $username
userhome=$(eval echo ~$username)

chmod 750 $userhome

echo "
User: $username
Pass: $password
===============
" > $statdir/$username.txt

### SSH

ssh-keygen -t rsa -b 4096 -P$password -f $keysdir/$username.key
mkdir -m 700 $userhome/.ssh
cat $keysdir/$username.key.pub > $userhome/.ssh/authorized_keys
cat $keysdir/$username.key > $userhome/.ssh/id_rsa
chown -R $username:$username $userhome/.ssh
chmod 600 $userhome/.ssh/authorized_keys
chmod 600 $userhome/.ssh/id_rsa

usermod -aG www-data $username

### THE END
echo "Done."

### USER FI
fi
