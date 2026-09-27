#!/usr/bin/env bash

# Configuration
THRESHOLD=80
ALERT_EMAIL="admin@example.com"
HOSTNAME=$(hostname)

# Check disk usage (exclude virtual filesystems)
df -hP | grep -vE 'tmpfs|devtmpfs|loop|cdrom|squashfs' |\
while read -r line; do
    USAGE=$(echo $line | awk '{print $5}' | sed 's/%//')
    MOUNT=$(echo $line | awk '{print $6}')

    if [ "$USAGE" -ge "$THRESHOLD" ]; then
        SUBJECT="Disk Usage Alert on $HOSTNAME"
        MESSAGE="Disk usage is ${USAGE}% on mount point
        $MOUNT\n\nPlease check and take action immediately."

        echo -e "$MESSAGE" | mail -s "$SUBJECT" "$ALERT_EMAIL"
        echo "Alert sent: $MOUNT is ${USAGE}%"
    fi
done
