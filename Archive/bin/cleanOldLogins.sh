#!/bin/ksh
# 
# The following script cleans up all the logins which have been
# marked as "old"
# 
rm -f /tmp/clean.list
who -u | grep old | awk '{print $7}' > /tmp/clean.list
LIST=`cat /tmp/clean.list`
kill -KILL $LIST
