#!/bin/bash
#
# Number of Files Open Per PID
#   Display top 10 usage of open files by PID

touch /tmp/fo

for i in `ls -d /proc/[0-9]*` ; do 
	echo -n "$i  " >>/tmp/fo
	find $i/fd 2>>/dev/null| wc -l >>/tmp/fo
done
 
sort -k2n /tmp/fo | tail
rm -f /tmp/fo

