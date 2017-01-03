#!/bin/bash
#
# Fork of SyncHome.sh to copy files from git repo to home dir
#
# This version does little error/sanity checking
#
# Start Date: 2014-04-01
# Coder: awmyhr
# e-mail to: awmyhr@gmail.com

# Settings
SOURCEDIR="$HOME/work/SATools"
FILELIST="$SOURCEDIR/etc/deployfile.lst"

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

echo "Found files."

echo "Removing tempfiles..."
find $SOURCEDIR -name "*~" -exec rm {} ";"

echo "Putting files in place..."
rsync -az --files-from $FILELIST $SOURCEDIR $HOME

exit $?


