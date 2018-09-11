#!/bin/bash
#
# Для работы exp требуется apt install expect
#
# Сам exp (лежать в /usr/bin):
#
#!/usr/bin/expect
#
#set timeout 20
#
#set cmd [lrange $argv 1 end]
#set password [lindex $argv 0]
#
#eval spawn $cmd
#expect "Enter passphrase to load key:"
#send "$password\r";
#interact
#
##############################################

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
chown -R $username:$username $userhome/.ssh
chmod 600 $userhome/.ssh/authorized_keys

### PUTTY CONVERT

exp $password puttygen $keysdir/$username.key -o $keysdir/$username.ppk

### THE END
echo "Done."

### USER FI
fi
