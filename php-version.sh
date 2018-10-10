#!/bin/bash
# этот скрипт позновляет выводить и менять версии пыха -- модуль, фпм,
# но работать будет только в проектах, созданных при помощи скрипта project.sh
# т.к. анализирует конфиги на освное спец. созданных каментов (см. ниже)
# DEBIAN/UBUNTU VERSION !!!
#############################

clear
echo "== Выбор версии PHP =="
echo "ВЫХОД: CTRL+C"
echo

### VARS
declare -A version
num=1

### PUT WHOLE DIR (!!!DEBIAN STYLE CONF!!!)
files=(/etc/apache2/sites-enabled/*)

### GREP VERSIONS
for confname in ${files[*]}
do
if grep -q "###VERSION 7.1" $confname; then
	version[$confname]="7.1"
elif grep -q "###VERSION 7.2" $confname; then
	version[$confname]="7.2"
elif grep -q "###VERSION 5.6" $confname; then
        version[$confname]="5.6"
elif grep -q "###VERSION 7.0MOD" $confname; then
	version[$confname]="7.0MOD"
fi
done

### PRINT ENABLED CONFS
for confname in ${files[*]}
do
printf "%d - %s - %s\n" $num $confname "${version[$confname]}"
((num++))
done

echo

### SELECT CONF
confnum=""
while [[ ! ${confnum} =~ ^[0-9]+$ ]]; do
	echo "Select conf:"
	read confnum
	if ! [[ confnum -ge 1 && confnum -le ${#files[@]} ]]
	then
		unset confnum
		echo "no such a conf. select another one"
		echo
	fi
done

echo

### SELECT PHP VERSION
versnum=""
while [[ ! ${versnum} =~ ^[1-4]+$ ]]; do
        echo "Select version:"
	echo "1. apache module 7.0"
	echo "2. php-fpm 5.6"
	echo "3. php-fpm 7.1"
	echo "4. php-fpm 7.2"
	echo
	echo "Enter version number (1-4]):"
        read versnum
        if ! [[ versnum -ge 1 && versnum -le 4 ]]
        then
                unset versnum
                echo "select another one (1-4)"
        fi
done

### MAKE CHANGES
if [ $versnum -eq 4 ]; then
	vers_set="7.2"
elif [ $versnum -eq 3 ]; then
	vers_set="7.1"
elif [ $versnum -eq 2 ]; then
	vers_set="5.6"
elif [ $versnum -eq 1 ]; then
	vers_set="7.0MOD"
fi

### GREP OLD CONFIG
confname=${files[confnum-1]}
if grep -q "###VERSION 7.1" $confname; then
        vers="7.1"
elif grep -q "###VERSION 7.2" $confname; then
        vers="7.2"
elif grep -q "###VERSION 5.6" $confname; then
        vers="5.6"
elif grep -q "###VERSION 7.0MOD" $confname; then
        vers="7.0MOD"
fi

if [ $vers_set = "7.0MOD" ]; then
version_replace="###VERSION "$vers_set"
######VERSION END"
else
version_replace="###VERSION "$vers_set"
<FilesMatch \"\.+\\\.ph(p[3457]?|t|tml)\$\">
<If \"-f %{REQUEST_FILENAME}\">
SetHandler \"proxy:unix:/run/php/php"$vers_set"-fpm.sock|fcgi://localhost\"
</If>
</FilesMatch>
######VERSION END"
fi

mark1="###VERSION "$vers
mark2="######VERSION END"

awk -v st="$mark1" -v et="$mark2" -v repl="$version_replace" '$0 == st{del=1} $0 == et{$0 = repl; del=0} !del' ${files[confnum-1]} > /tmp/temp.conf 2> /dev/null
mv /tmp/temp.conf ${files[confnum-1]}

echo

echo "service apache2 reload..."
service apache2 reload
