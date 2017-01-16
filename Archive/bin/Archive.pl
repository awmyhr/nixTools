#!/usr/local/bin/perl -w
#
# Program to make and distribute backups of users 
#   home directory, or specific sets of files therein.
#   It will take a list of files, tar them, compress,
#   and then copy it to a set of remote systems.
#   There will be options for no distribution, and
#   the tar will be an update to make things go faster.
# Originally conceived to keep a backup which I control
#   of my RCS and work directories.
# This program originally required the Perl mods Archive::Tar
#   and Compress::Zlib (which in turn requires zlib to be
#   installed).  However, that module seems to not work
#   properly.  Now, the common commands tar and gzip must
#   be in the path.  Also, scp should be in the path, and 
#   @INC should have the custom library perl_subs.pl in it.
#
# Version History 
#   0.1   Initial dev version
#         Basic functionality
# 01/23/2003	Update to conform with v2.2 of template.pl
#		Commence further work, maybe drop Archive::Tar
# 01/24/2003	Implement distribution
#		Implement -N, -F, -D
#		Add Distribution list file
#
# Start Date: December 19, 2002
# Coder: awmyhr
# e-mail to: awmyhr@gmail.com

use lib "$ENV{HOME}/libs";		#Library in users libs dir
use strict;				#Turn on strict, good programing
use Getopt::Std;			#Parser for command line options
use File::Basename;			#Used to get name of program
use Shell qw(tar gzip scp);		#use shell commands
require "perl_subs.pl";			#Custom routines

use vars qw($opt_h $opt_v $opt_N $opt_f $opt_F $opt_D $opt_V);
					#Variables: Command line options used by Getopt
my(
	$Version,			#Const: Verison
	$MostRecentCoder,		#Const: Holds name of most recent coder
	$Modified,			#Const: Date last modified
	$Dev,				#Const: Development version?
	$ProgName,			#Const: Program Name
	$FileList,			#Var: file with list of files to backup
	@Files,				#Var: list of files to backup
	$TarFile,			#Var: file to create
	$WorkDir,			#Const: work directory to build archive
	$BaseDir,			#Const: base directory to get files from
	$GZFile,			#Var: tar file with added .gz
	@Destinations,			#Var: list of destinations for archive file
	$Dest,				#Var: hold one destination for loop
	$DestFile,			#Const: File containing list of destinations
);

#Defaults

#Constants
$Version	= substr('$Revision: 2.1 $', 10, -1);
$Modified	= substr('$Date: 2003/01/24 17:11:07 $', 6, -1);
$MostRecentCoder= substr('$Author: awmyhr $', 8, -1);
$ProgName	= basename("$0");
$Dev		= 0;
$WorkDir	= "/tmp/";
$BaseDir	= "$ENV{HOME}";
$TarFile	= "Archive" . DateStamp() . ".tar";
$FileList	= "$ENV{HOME}/etc/Archive.lst";
$DestFile	= "$ENV{HOME}/etc/Archive.dest";	
				
if( '$State: Rel $' =~ /Exp/ ) {		#Check for Development version
	print "WARNING: This is a develpment version!\n";
	$Dev=1;
}

if(!getopts('hvVNf:F:D:')) {		#Check options and warn if errors
	print "Usage: $ProgName [options]\n";
	print "Try ' -h' for more information.\n";
	exit 1;				#Exit if incorrect options
}

if($opt_h){				#Display help if asked for
	print <<END_of_text;
	Usage:	$ProgName [options]
	-f		File to create [NOT YET IMPLEMENTED]
				(Default: $TarFile.gz)
	-F		File with list of files to backup
				(Defualt: $FileList)
	-D		File with list of destinations
				(Default: $DestFile)
	-N		Create tar only, do not distribute
        -h		Display this help and exit
	-v		Output version infromaiton and exit
	-V		Output verbose version info and exit

This program will take a list of files and directories, tar them,
gzip them, and distribute them (over a secure connection) to a 
list of destinations.
This initial version is not very intelligent, and requires exact
formating in both the file list and destination list.

Report bugs to awmyhr\@gmail.com
END_of_text
	exit 0;
}

if($opt_v){				#Display Version information
	print <<END_of_text;
Version: $Version  By: $MostRecentCoder
Date Created: 2002/12/19  Last Modified: $Modified
END_of_text
	exit 0;
}

if($opt_V){				#Display Verbose Version Info from comments above
open(PROG, $0) or die "Sorry, could not read $ProgName: $!\n";
	while(<PROG>)  {
		next if((/^#!/));
		last if(!/^#/);
		print substr($_, 1);
	}
close(PROG);
	print "Current Version: $Version\n";
	exit 0;
}

if($opt_f) {
	print "Sorry, option -f not implemented at this time.\n";
	print "\tWill use default of: $TarFile.gz\n";
}

if($opt_F) {
	if(-e $opt_F) {
		$FileList = $opt_F;
	} else {
		die "Could not find $opt_F!\n";
	}
}

if($opt_D) {
	if(-e $opt_D) {
		$DestFile = $opt_D;
	} else {
		die "Could not find $opt_D!\n";
	}
}

chdir($BaseDir) or die "Unable to chdir to $BaseDir: $!\n";
$GZFile = $TarFile . ".gz";
if(-e "$WorkDir$GZFile") { die "$WorkDir$GZFile already exists!\n"; }

open(FLIST, $FileList) or die "Unable to open $FileList: $!\n";
	while(<FLIST>){
		next if(/^#/ || $_ eq "\n");	#If comment or new line, skip
		chomp($_);
		
		push @Files, $_;
	}
close(FLIST);

open(DLIST, $DestFile) or die "Unable to open $DestFile: $!\n";
	while(<DLIST>){
		next if(/^#/ || $_ eq "\n");	#If comment or new line, skip
		chomp($_);
		
		push @Destinations, $_;
	}
close(DLIST);

if ($Dev) { 
	print "Will archive these files:\n\t@Files\n"; 
	print "To these destinations:\n\t" . join("\n\t", @Destinations) . "\n";
}

tar("-cf", "$WorkDir$TarFile", "@Files");
gzip("$WorkDir$TarFile");

if($opt_N){
	print "Created: $WorkDir$GZFile\n";
} else {
	foreach $Dest (@Destinations){
		if ($Dev) { print "--> scp $WorkDir$GZFile $Dest$GZFile\n"; }
		scp("$WorkDir$GZFile", "$Dest$GZFile");
	}
	
	unlink("$WorkDir$GZFile");
}

exit 0;

# FUTURE IDEAS
# Re-implement Archive::Tar when it is improved, or find another module which
#   does something similar...
# modify -f option to automagically create the date.  For instance, allow:
#     -f somefile{DATE}.tar.gz
#   then replace {DATE} with DateStamp()
# add -b option to specify base directory, and option to set $BaseDir in 
#   $FileList
# more intelligent handling of existing archive file

