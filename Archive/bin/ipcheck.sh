#!/bin/sh

function testip() {
    local c=$1
    local a=$2

    if ping -c $c -w $c $a >/dev/null; then
        echo "${a} all good"
    else
        echo "${a} no joy"
    fi
    dig +short -x $a 
}

count=2
nwnum=192.168.128
hostid=34

while getopts "c:n:h:" opt; do
    case $opt in
        (c)
            count="$OPTARG"
        ;;
        (n)
            nwnum="$OPTARG"
        ;;
        (h)
            hostid="$OPTARG"
        ;;
        (*)
            echo "Usage: $0 [-c count] [-n networknumber] [-h hostid]"
            exit 2
        ;;
    esac
done

testip $count "${nwnum}.${hostid}"

exit 0



