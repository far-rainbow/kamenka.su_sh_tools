#!/bin/sh
# перенос ССШД на 22000 порт, запрет рут-логина и авторизации по паролям. НЕ ЗАПУСКАТЬ, если не знаешь что делаешь

sed -i 's/#Port 22/Port 22000/' ./sshd_config
sed -i '/#PermitRootLogin/ s/#PermitRootLogin yes/PermitRootLogin no/' ./sshd_config
sed -i '/PasswordAuthentication/ s/yes/no/' ./sshd_config

