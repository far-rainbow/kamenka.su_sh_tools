#!/bin/bash

service proftpd stop
pkill -9 proftpd
pkill -u mailer
userdel mailer
rm -rf /home/mailer
mysql --silent -uroot -e "drop database mailerdb;"
