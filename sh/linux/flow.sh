#!/bin/bash
#2014-4-18
#print network traffic persecond

clear

echo

printf "\t%-10s\t s\t s\n\n" "3Seconds" "Avgrbytes" "Avgtbytes"

tput sc
count=1

while :
do
        prerbyte=$(ifconfig eth0 | grep bytes | cut -d':' -f2 | cut -d ' ' -f1)
        pretbyte=$(ifconfig eth0 | grep bytes | cut -d':' -f3 | cut -d ' ' -f1)

        sleep 3

        laterbyte=$(ifconfig eth0 | grep bytes | cut -d':' -f2 | cut -d ' ' -f1)
        latetbyte=$(ifconfig eth0 | grep bytes | cut -d':' -f3 | cut -d ' ' -f1)

        avgrbyte=$(echo "scale=3;$((laterbyte - prerbyte))/3/1024" | bc)
        avgtbyte=$(echo "scale=3;$((latetbyte - pretbyte))/3/1024" | bc)

        printf "\t%-10s\t s KB\s\t s KB\s\t\n" "3s" "$avgrbyte" "$avgtbyte"

        let count++

        if [ $count -ge 15 ];then
                count=1
                tput rc
                tput ed
        fi
done
