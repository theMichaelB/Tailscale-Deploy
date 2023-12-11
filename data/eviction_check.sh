#!/bin/bash

EVENTJSON=$(curl -s -H Metadata:true http://169.254.169.254/metadata/scheduledevents?api-version=2019-08-01)

# check for /tmp/eviction file
if [ -f /tmp/eviction ]; then
    echo "Eviction file exists. Exiting."
    exit 0
fi


echo $EVENTJSON
if [[ $EVENTJSON == *"Preempt"* ]]; then
    echo "VM is scheduled for maintenance. Initiating shutdown."
    curl -X POST https://api.pushcut.io/KlEgXKvxHw4z5pZy0-BeJ/notifications/VM%20eviction
    hostname=${cat /etc/hostname}
    curl -X POST -d "{\"title\":\"${hostname} Eviction\", \"devices\":[\"iPhone Yellow\"],\"text\":\"VM is evicted\"}" -H "Content-Type: application/json" https://api.pushcut.io/KlEgXKvxHw4z5pZy0-BeJ/notifications/VM%20eviction
    touch /tmp/eviction
    sudo tailscale logout 

fi
