#!/bin/bash
# что это? забыл... полная очистка почты, а ФТП нахрена останавливается? может быть там postfix должен был быть? надо освежить
#

service proftpd stop
pkill -9 proftpd
pkill -u mailer
userdel mailer
rm -rf /home/mailer
mysql --silent -uroot -e "drop database mailerdb;"
