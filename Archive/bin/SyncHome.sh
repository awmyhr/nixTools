#!/bin/bash
#
# A light-weight, shell-based version of my old SyncHome.pl program
#
# This version does little error/sanity checking
#
# Start Date: 2014-04-01
# Coder: awmyhr
# e-mail to: awmyhr@gmail.com

# Settings
SOURCEDIR=`echo ~`
FILELIST="$SOURCEDIR/etc/syncfile.lst"
HOSTLIST="$SOURCEDIR/etc/allservers.lst"

# Make sure files exist, else exit
fileck() {
	if [[ -f $1 ]]; then
		echo "Found $1"
	else
		echo "$1 missing!"
		exit 1
	fi
}

fileck $FILELIST
fileck $HOSTLIST

echo "Found files."

for host in `cat $HOSTLIST`; do
    echo "Rsyncing files to: $host"
    rsync -az --files-from $FILELIST $SOURCEDIR $host:
done

exit $?


