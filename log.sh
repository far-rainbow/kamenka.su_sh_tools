#!/bin/bash
find /var/log -name "*.log" | xargs tail -f
