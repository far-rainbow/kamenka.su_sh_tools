#!/bin/bash
# наблюдаем за логами
find /var/log -name "*.log" | xargs tail -f
