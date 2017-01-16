#!/usr/local/bin/perl -w
#
# DelOld.pl - short program to delete file 6 hours old in /tmp
#
# Version History (Update Version & Modified variable also)
#   0.1   Initial dev version
#         Basic functionality
#   1.0   Does what it was designed to do.
#
# Start Date: December 11, 2001
# Coder: awmyhr
# e-mail to: awmyhr@gmail.com

use strict;				#Turn on strict, good programing
use Getopt::Std;			#Parser for command line options

use vars qw($opt_h $opt_v);
					#Variables: Command line options used by Getopt
my(
	$Version,			#Variable: Verison
	$Modified,			#Variable: Date last modified
	$Dev,				#Variable: Development version?
	$ProgName,			#Variable: Program Name
	$dir,				#Variable: Directory to work in
	$numDay,			#Variable: number of days (can be decimal)
	$file,				#Variable: filename
);

#Defaults
$Version=1.0;
$Modified="December 11, 2001";
$Dev=1;
$ProgName="DelOld";
$dir="/tmp/";
$numDay=7;

if( ($Version * 10) % 2 ) {		#Check for Development version
	print "WARNING: This is a develpment version!\n";
	$Dev=1;
}

if(!getopts('hv')) {			#Check options and warn if errors
	print "Usage: $ProgName\n";
	print "Try ' -h' for more information.\n";
	exit 1;				#Exit if incorrect options
}

if($opt_h){				#Display help if asked for
	print <<END_of_text;
	Usage:	$ProgName
        -h		Display this help and exit
	-v		Output version infromaiton and exit
Report bugs to awmyhr\@gmail.com
END_of_text
	exit 0;
}

if($opt_v){				#Display Version information
	print " $Version  \nBy: awmyhr\n";
	print "Date Created: December 11, 2001  Last Modified: $Modified\n";
	exit 0;
}

opendir(DIR, "$dir") or die "Could not open $dir: $!\n";

foreach $file (readdir(DIR)) {
	next if($file eq "." or $file eq "..");
	if(-A "$dir$file" > $numDay) {
		if($Dev) {
			print "$dir$file is old\n";
		} else {
			unlink "$dir$file";
		}
	}
}

closedir(DIR);

exit 0;

# FUTURE IDEAS
