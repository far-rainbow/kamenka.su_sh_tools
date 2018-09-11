#!/bin/sh

sed -i 's/#Port 22/Port 22000/' ./sshd_config
sed -i '/#PermitRootLogin/ s/#PermitRootLogin yes/PermitRootLogin no/' ./sshd_config
sed -i '/PasswordAuthentication/ s/yes/no/' ./sshd_config

