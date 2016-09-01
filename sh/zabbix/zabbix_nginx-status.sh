#!/bin/bash
# 2016/01/25 pdd

HOST=127.0.0.1
PORT=80
URI="/statusx35"

case "$1" in
    Active_connections)
        curl -s -m 5 --no-keepalive "http://${HOST}:${PORT}${URI}" | awk 'NR==1 {print $3}'
        ;;
    server_accepts)
        curl -s -m 5 --no-keepalive "http://${HOST}:${PORT}${URI}" | awk 'NR==3 {print $1}'
        ;;
    server_handled)
        curl -s -m 5 --no-keepalive "http://${HOST}:${PORT}${URI}" | awk 'NR==3 {print $2}'
        ;;
    server_requests)
        curl -s -m 5 --no-keepalive "http://${HOST}:${PORT}${URI}" | awk 'NR==3 {print $3}'
        ;;
    Reading)
        curl -s -m 5 --no-keepalive "http://${HOST}:${PORT}${URI}" | awk 'NR==4 {print $2}'
        ;;
    Writing)
        curl -s -m 5 --no-keepalive "http://${HOST}:${PORT}${URI}" | awk 'NR==4 {print $4}'
        ;;
    Waiting)
        curl -s -m 5 --no-keepalive "http://${HOST}:${PORT}${URI}" | awk 'NR==4 {print $6}'
        ;;
    *)
        echo "Usage: $0 Active_connections|server_accepts|server_handled|server_requests|Reading|Writing|Waiting"
esac
