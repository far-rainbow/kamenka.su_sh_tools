#!/bin/sh
# лист конфига -- номер машины задать аругментом
#

vzlist
cat /etc/vz/conf/$1.conf

