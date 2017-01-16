#!/bin/bash
# script to push web files into place

SOURCE="${HOME}/store/www/"
DEST='/var/www/html'
DATESTAMP=`date +%Y%m%d-%H%M`

# clean tree
find $SOURCE -name "*~" -exec rm {} ";"

# copy tree
cd ${SOURCE}
sudo cp -rf . ${DEST}

# update push timestamp
sudo sed -i "s/DEP_DATE/${DATESTAMP}/" ${DEST}/inc/page_footer.php

