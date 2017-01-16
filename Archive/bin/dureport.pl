#!/usr/local/bin/perl -w
#
# Program to create a file with disk usage info
#   for users home directories.
#
# Version History (Update Version & Modified variable also)
#   0.1   Initial dev version
#         Basic functionality
#   0.3   Start sending e-mail
#         build list of size offenders
#   1.0   Initial Release
#   1.1   Development Version
#         Add command line switch for:
#           non-email (immediate) use
#           Sort order (by user/dir or size)
#           alternate size limit
#           alternate directory root
#   1.2   Second Release
#   1.3   Clean up stuff
#   1.4   Better looking release...
#   1.5   Implement external subroutine file
#   1.5.1 Updated for new job location
#
# Start Date: May 03, 2001
# Coder: awmyhr
# e-mail to: awmyhr@gmail.com

use strict;				#Turn on strict, good programing
use Getopt::Std;			#Parser for command line options
use POSIX qw(uname);			#Use UNIX commands
require "$ENV{HOME}/libs/perl_subs.pl";  #Custom perl subroutines

use vars qw($opt_h $opt_v $opt_i $opt_s $opt_l $opt_d);
					#Variables: Command line options used by Getopt
my(
	$Version,			#Variable: Verison
	$Modified,			#Variable: Date last modified
	$Dev,				#Variable: Development version?
	$ProgName,			#Variable: Program Name
	$emErr,				#Variable: E-Mail to on Error
	$emUsr,				#Variable: E-Mail to user
	$emSub,				#Variable: E-Mail subject
	$emMess,			#Variable: E-Mail message
	@emMess,			#Variable: E-Mail big message
	$emFatal,			#Variable: E-Mail fatal?
	$dir,				#Variable: Hold directory name
	%Dirsize,			#Variable: Hold directory size and names
	$dudir,				#Variable: The directory to du
	$hostname			#Variable: Hostname
);

#Defaults
$Version=1.5;
$Modified="December 05, 2002";
$Dev=0;
$ProgName="dureport.pl";
$emErr="error\@test.com";
$emMess="Output from dureport.pl:\n";
$dudir="/home/";
$hostname=(uname)[1];
						
if( ($Version * 10) % 2 ) {		#Check for Development version
	print "WARNING: This is a develpment version!\n";
	$Dev=1;
	$emErr="error\@test.com";
}

if(!getopts('hvis:l:d:')) {			#Check options and warn if errors
	print "Usage: $ProgName\n";
	print "Try ' -h' for more information.\n";
	exit 1;				#Exit if incorrect options
}

if($opt_l) {
	if($opt_l <= 0 || $opt_l > 10000 || $opt_l =~ /\D/) {
		print "Option l is invalid\n";
		print "-l should be a number from 1 - 10000\n";
		exit 1;
	}
} else {
	$opt_l=100;
}
		
if (!$opt_s) {$opt_s = "d";}		#Default to sort by user
					#Check flag for option s
if (lc($opt_s) ne "d" && lc($opt_s) ne "s"){
	print "$opt_s invalid flag for s!\n";
	$opt_h=1;			#If invalid flag for s, show help
}

if($opt_h){				#Display help if asked for
	print "Usage:\t$ProgName [OPTIONS]\n";
	print "This program will generate a disk usage report\n";
	print "for a set of subdirectories in a specific directory.\n";
	print "It currently defaults to the home directories on\n";
	print "the system, looking for any user with more than\n";
	print "100 MB and sending a report to sys admins via e-mail.\n";
	print "\t-s d|D|s|S\tSort by directory (d, D) or size (s, S) default: $opt_s\n";
	print "\t-l limit\tLower limit in MB  default: $opt_l\n";
	print "\t-d dir\tAlternate base directory  default: $dudir\n";
	print "\t-i\t\tImmediate output, do not send e-mail\n";
        print "\t-h\t\tDisplay this help and exit\n";
        print "\t-v\t\tOutput version infromaiton and exit\n";
	print "\nReport bugs to awmyhr\@gmail.com\n";
	exit 0;
}

if($opt_v){				#Display Version information
	print "$ProgName $Version  \nBy: awmyhr\n";
	print "Date Created: May 03, 2001  Last Modified: $Modified\n";
	exit 0;
}

if($opt_d){				#change default directory
	if(!(-d "$opt_d")) {
		print "Invalid directory: $opt_d \n";
		exit 1;
	}
	$dudir=$opt_d;
	if(substr($dudir, -1, 1) ne "/") {$dudir = $dudir . "/";}
					#if no trailing slash, add it
}

$emMess=$emMess . "Base directory: $dudir\n";

DirList();				#Get directory info (name and size)

CreateMess();				#Create Message

if($opt_i) {print $emMess;}		#print message to screen

if(!$opt_i){
	foreach $dir (sort { $Dirsize{$b} <=> $Dirsize{$a} } keys %Dirsize){  #build sys admin e-mail
		$emMess = $emMess . "$dir => $Dirsize{$dir} MB\n";
	}
	MailError($emErr, "${hostname}-${ProgName}-Report", "$emMess\n\tEnd of report\n", 0);
}

if(!$Dev && !$opt_i){			#Send e-mail to users
}

if($Dev) {Output();}			#Display debugging output if dev version

#This is the end of the program....
exit 0;

######################################################################################
#Subroutine - Getting directory size info

sub DirList {				#based on input from dutree in Perl Cookbook

	my($size, $name, @dirlist);  	#Directory size, (long) name (not used yet), (short) name, and directory list

	opendir DUDIR, "$dudir" or MailError($emErr, "${hostname}-${ProgName}-FatalError", "$emMess\n Can't open $dudir dir: $! ", 1);
		@dirlist= grep /^[A-Za-z]/, readdir DUDIR;
	closedir DUDIR;

	foreach $dir (@dirlist){	#do du on each dir
		($size, $name) = split(/\t/,`du -ks $dudir$dir`);
		$size = int($size / 1024);	#We want size in MB
		next if ($size < $opt_l);	#We don't need all listings
		$Dirsize{$dir} = $size;		#Create hash table
	}
	
	return $dir;
}


######################################################################################
#Subroutine - display dir list - for debuging only
sub Output {

	print "Start debug output **********\n";
					#Sort by user name
	foreach $dir (sort keys %Dirsize){
		print "$dir is $Dirsize{$dir}\n";
	}
	print "***\n";
					#sort by size (largest first)
	foreach $dir (sort { $Dirsize{$b} <=> $Dirsize{$a} } keys %Dirsize) {
		print "$dir is $Dirsize{$dir} MB.\n";
	}
	
	print "End debug output ************\n";	
	return;
}

######################################################################################
#Subroutine - Create message (or output) body
sub CreateMess {

	if($opt_s eq "s") {		#Sort by size
		foreach $dir (sort { $Dirsize{$b} <=> $Dirsize{$a} } keys %Dirsize){
			$emMess = $emMess . "$dir => $Dirsize{$dir} MB\n";
		}
	} else {			#Sort by directory name
		foreach $dir (sort keys %Dirsize){
			$emMess = $emMess . "$dir => $Dirsize{$dir} MB\n";
		}
	}
	
	return;
}
	
# FUTURE IDEAS
# Send individual "NastyGrams" to abusers
#    (or choose a cut off point)

# We are done, you are free to go...
