#!/bin/sh
# BusyBox in curlimages/curl

sleep 10

t=0
while ! curl -s --fail http://zendserver/ready.html ; do
    sleep 2
    if [ $t -gt 60 ]; then
        echo "The test should take less than 2 minutes. Exiting..."
        exit 1
    fi
    let t=t+1
done
login="$(curl -sLH 'Host: instant.moodle.lcl' 'http://zendserver/login/')"
markers="$(echo "$login" | grep 'Instant Moodle' | grep -i 'log in')"
if [ -z "$login"  ]; then
    echo "$login"
    echo "--- ERROR: Can't see markers of a login page. Test failed :("
    echo "$markers"
    exit 1
fi
echo "Looks like we got our login page:"
echo "$markers" | grep title
echo "Happy now!"
