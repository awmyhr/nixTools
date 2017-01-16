#!/usr/local/bin/perl -w
#
# This program will take a list of systems (allservers.list, 
#   see allservers.pl for info) and a list of files, and will
#   update all the files on all the systems over a secure 
#   connection (ssh/scp/sftp).  This will use rsync to do the work.
# The structure/code is based on allservers.pl, think of it as a 
#   specialized version of that program.
#
# This program requires the Perl mod File::Rsync, as well as rsync
#   itself set up properly.
#
# Version History (Update Version & Modified variable also)
#   0.1   Initial dev version
#         Basic functionality
#   1.0   Functions as expected
#
# Start Date: December 17, 2002
# Coder: awmyhr
# e-mail to: awmyhr@gmail.com

use lib "$ENV{HOME}/libs";		#Library in users libs dir
use strict;				#Turn on strict, good programing
use Getopt::Std;			#Parser for command line options
use File::Basename;			#Used to get name of program
use File::Rsync;			#For easy interface to rsync

use vars qw($opt_h $opt_v $opt_u $opt_f $opt_F $opt_R $opt_e $opt_p);
					#Variables: Command line options used by Getopt
my(
	$Version,			#Const: Verison
	$Modified,			#Const: Date last modified
	$Dev,				#Const: Development version?
	$ProgName,			#Const: Program Name
	$rsync,				#Obj: Object for rsync
	$ServerList,			#Var: Server List File
	$FileList,			#Var: Files to sync list file
	@Files,				#Var: holds contents of $FileList
	$File,				#Var: current file being worked with
	$UserID,			#Var: User ID
	@ref,				#Var: holds a reference for dereferencing
	$HostReport,			#Var: Report output
	$Pass,				#Var: User password for ssh
	@HostInfo,			#Var: Expected host information
);					#  $HostInfo[0] = Hostname
					#  $HostInfo[1] = Environment
					#  $HostInfo[2] = Project


#Defaults

#Constants
$Version	= 1.0;
$Modified	= "December 18, 2002";
$ProgName	= basename("$0");
$Dev		= 0;
$ServerList	= "$ENV{HOME}/etc/allservers.list";
$FileList	= "$ENV{HOME}/etc/syncfile.list";
$HostReport	= "This rsync done at: " . localtime(time) . ".\n\n";
						
if( ($Version * 10) % 2 ) {		#Check for Development version
	print "WARNING: This is a develpment version!\n";
	$Dev=1;
}

if(!getopts('hvu:f:F:e:p:R')) {		#Check options and warn if errors
	print "Usage: $ProgName [options]\n";
	print "Try '$ProgName -h' for more information.\n";
	exit 1;				#Exit if incorrect options
}

if($opt_h){				#Display help if asked for
	print <<END_of_text;
	Usage:	$ProgName [options]
	-f filename	Server list file 
				(default $ServerList)
	-F filename	Files to Sync list file 
				(default $FileList)
	-e env		Environment to execute in
			ex: -e dev
	-p proj		Project to execute on
			ex: -p css
	-u UID		User ID to use for secure connection
	-R		Repress report output
        -h		Display this help and exit
	-v		Output version infromaiton and exit

Report bugs to awmyhr\@gmail.com
END_of_text
	exit 0;
}

if($opt_v){				#Display Version information
	print <<END_of_text;
$Version  
By: awmyhr
Date Created: December 17, 2002  Last Modified: $Modified
END_of_text
	exit 0;
}

if($opt_u){
	$UserID = $opt_u;
} else {
	$UserID = getpwuid($<);
}

if($opt_f) { $ServerList=$opt_f; }	#Allow alternate server list
if($opt_F) { $FileList=$opt_F; }	#Allow alternate sync file list
$opt_e=lc($opt_e) if($opt_e);		#convert params to lower case
$opt_p=lc($opt_p) if($opt_p);
					#Work from the home directory
chdir "$ENV{HOME}" or die "Cann't change to $ENV{HOME}: $! \n";	

# Read file list
open (FILELIST, $FileList) or die " No file list $FileList: $! \n";
while (<FILELIST>) {
	next if(/^#/ || $_ eq "\n");	#If comment or new line, skip
	chomp($_);
	$HostReport .= $_ . " will be synced.\n";
	push @Files, $_;		#build file list
}

					#Set up the rsync object
$rsync = File::Rsync->new( { 'rsync-path'=>'~/bin/rsync' } );

# Open server list, or die
open(HOSTLIST, $ServerList) or die " No server list $ServerList: $! \n";

while (<HOSTLIST>){			#This is where all the work is done
	next if(/^#/ || $_ eq "\n");	#If comment or new line, skip
	chomp;				#Remove trailing \n
	@HostInfo=split(/\t/);		#Create array for host info

	if( (!$opt_e || lc($HostInfo[1])=~/$opt_e/) && (!$opt_p || lc($HostInfo[2])=~/$opt_p/)){
					#Test for paramaters
			#Now do rsync stuff: open command for input/output, process, close
		foreach $File (@Files) {
			if($Dev) { 
				print "rsync $File $UserID\@$HostInfo[0]:$File\n"; 
			}
			$rsync->exec( { src=>$File, dest=>$UserID."\@".$HostInfo[0].":".$File } ) or $HostReport .= "$File failed for $HostInfo[0]: $!\n";
			if($rsync->status) {
				$HostReport .= "exec returned: " . $rsync->status . ":" . $rsync->realstatus . "\n";
				@ref = $rsync->err;
				$HostReport .= $rsync->lastcmd . "\n" . $ref[0] . $ref[1] . "\n";
			} 
		};	
		
	}


}

# Close File, or die
close(HOSTLIST) or die " Can't close server file: $! ";

if (!$opt_R) {print $HostReport;}

exit 0;

# FUTURE IDEAS
# Big One - track last modified date of files in $FileList,
#    if it hasn't changed, then don't sync it.  This would 
#    save lots of time in execution.
# Allow command line specification of servers and/or files
