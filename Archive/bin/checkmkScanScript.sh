#!/bin/bash
#
# This script will scan the network and add machines to check_mk Monitoring
#   Original found at: http://lists.mathias-kettner.de/pipermail/checkmk-en/2013-June/009756.html
#
# the following 4 options need to be set by the end user
SITE=poc

# Location to the hosts.mk file
WATO=/omd/sites/$SITE/etc/check_mk/conf.d/wato/dev/hosts.mk

# network that you want to scan
NETWORK=192.168.100.0/24

# We only add machines that are in DNS  - eg <hostname>.domain.com
DOMAIN=test.com


RAWRESULTS=/tmp/list.txt
CLEANRESULTS=/tmp/scannfile.txt
WORKINGFILE1=/tmp/workingfile-a.txt
WORKINGFILE2=/tmp/workingfile-b.txt

# Scan the network and find new hosts.
# Clean up files
rm -rf $CLEANRESULTS $RAWRESULTS $WORKINGFILE1 $WORKINGFILE2

nmap -v -sP $NETWORK > $RAWRESULTS
#IFS=$'\r\n' RESULTS=($(cat $RAWRESULTS | grep $DOMAIN | cut -d " " -f 5))
IFS=$'\r\n' RESULTS=($(cat $RAWRESULTS | grep "Nmap scan report" | grep -v "host down" | cut -d " " -f 5 | sed "s/.gpihst.hst//g" | sed "s/.gpi.com//g"))
TOTAL=${#RESULTS[@]}


echo "" > /tmp/scannfile.txt
for (( i=0; i<${TOTAL}; i++ ));
do
        echo "${RESULTS[$i]}" >> $CLEANRESULTS
done

# Write out the list of hosts to a config file

cp $WATO $WORKINGFILE1

for (( i=0; i<${TOTAL}; i++ ));
do
        # Check for hosts that users had already added to the system - Can't have them listed twice!
        CHECK=`cat $WATO |grep ${RESULTS[$i]} | wc -l`
        if [ $CHECK -eq 0 ]
        then
                sed -e "/all_hosts/a \"${RESULTS[$i]}\","  $WORKINGFILE1 > $WORKINGFILE2 && mv $WORKINGFILE2 $WORKINGFILE1
        else
                echo already found, do nothing "\"${RESULTS[$i]}\"," > /dev/null
        fi
done

cp $WORKINGFILE1 $WATO

exit

# Clean up files
rm -rf $CLEANRESULTS $RAWRESULTS $WORKINGFILE1 $WORKINGFILE2

# Now to get Check_mk to know about the new hosts.
su - dev -c "cmk -IIu"
omd restart  dev
