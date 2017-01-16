#!/usr/local/bin/perl -w
#
# This program is designed to do a "spot-check" on the local system in order
#   to determine if backups are functioning correctly.  The main body just
#   compiles the report, while the check is done by subroutines.
#
#    Date	History
# 01/27/2003	Initial dev version
#		Basic functionality
# 01/28/2003	Work on TSM checking
# 01/29/2003	Work on NSR checking
# 02/28/2003	Added -y option to search for files modified yesterday
#		Added limit to number of files find will return (shortens execution time)
#		Modified commands needing sudo so that root does not attempt to use sudo
#		Added some error checking and reporting
#
# Start Date: 	January 27, 2003
# Coder List: 	awmyhr
# e-mail to:	awmyhr@gmail.com

use lib "$ENV{HOME}/libs";		#Library in users libs dir
use strict;				#Turn on strict, good programing
use Getopt::Std;			#Parser for command line options
use File::Basename;			#Used to get name of program
use File::stat;				#used to get file stats
use POSIX qw(uname);			#Use UNIX commands

use vars qw($opt_h $opt_v $opt_V $opt_y);
					#Variables: Command line options used by Getopt
my(
	$Version,			#Const: Verison
	$MostRecentCoder,		#Const: Holds name of most recent coder
	$Modified,			#Const: Date last modified
	$Dev,				#Const: Development version?
	$ProgName,			#Const: Program Name
	$hostname,			#Const: hostname
	@FileSys,			#Var: filesystems to check
	$tFail,				#Var: check failure status of TSM check
	$nFail,				#Var: check failure status of NSR check
	$ChkFiles,			#Var: list of files (seperated by "|") for the backup programs to check
	$Stats,				#Obj: hold file statistics from File::stat
	$Report,			#Var: Report which will be printed in the end
);

#Defaults

#Program info (mostly created by RCS)
$Version	= substr('$Revision: 2.2 $', 10, -1);
$Modified	= substr('$Date: 2003/02/28 20:26:25 $', 6, -1);
$MostRecentCoder= substr('$Author: awmyhr $', 8, -1);
$ProgName	= basename("$0");
$Dev		= 0;
$hostname	= (uname)[1];
$Report		= "$hostname checked on " . localtime(time) . "\n";
@FileSys	= qw(/etc /usr /var /home);
						
if( '$State: Rel $' =~ /Exp/ ) {		#Check for Development version
	$Report .= "WARNING: This is a develpment version!\n";
	$Dev=1;
}

if(!getopts('hvVy')) {			#Check options and warn if errors
	print "Usage: $ProgName [options]\n";
	print "Try ' -h' for more information.\n";
	exit 1;				#Exit if incorrect options
}

if($opt_h){				#Display help if asked for
	print <<END_of_text;
	Usage:	$ProgName [options]
	-y		Look for files modified 24-48 hours ago
				(default is 12-24 hours ago)
        -h		Display this help and exit
	-v		Output version info and exit
	-V		Output verbose version info and exit

Report bugs to awmyhr\@gmail.com
END_of_text
	exit 0;
}

if($opt_v){				#Display Version information
	print <<END_of_text;
Version: $Version  By: $MostRecentCoder
Date Created: 2003/01/27  Last Modified: $Modified
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

if(!$opt_y) { $opt_y = 0; } else { $opt_y = 1; }

$Report .= TSMExist();
$tFail = chop($Report);

$Report .= NSRExist();
$nFail = chop($Report);

if(($tFail) && ($nFail)) {
	$Report .= "Warning: This system does not appear to have a backup client.\n";
} else {
	$ChkFiles = FindFiles(join("!", @FileSys), $opt_y);
	
	if(!$tFail) { 
		$Report .= TSMCheck($ChkFiles); 
		$tFail += chop($Report);
	}
	if(!$nFail) { 
		$Report .= NSRCheck($ChkFiles); 
		$nFail += chop($Report);
	}
}

print $Report;

exit 0;

sub TSMExist {				#Check if TSM is actually there...
	my ($TSMbin, $TSMvar, $Report, $Fail);
	$Fail = "0";
	$Report = "Is TSM installed?\n";
	
	#Files to look for
	$TSMbin		= "/usr/bin/dsmc";
	$TSMvar		= "/var/opt/tsm";
		
	$Report .= "\t$TSMbin: ";
	if (-e $TSMbin) {
		$Report .= "Y";
	} else {
		$Report .= "N";
		$Fail++;
	}
	
	$Report .= "\t$TSMvar: ";
	if (-e $TSMvar){
		$Report .= "Y\n";
	} else {
		$Report .= "N\n";
		$Fail++;
	}

	if($Fail) {
		return $Report . "$Fail";
	} else {
		return "${Report}0";
	}
}

sub NSRExist {				#Check if NSR is actually there...
	my ($NSRrec1, $NSRrec2, $Report, $Fail);
	$Fail = "0";
	$Report = "Is NSR installed?\n";
	
	#Files to look for
	$NSRrec1	= "/usr/bin/recover";
	$NSRrec2	= "/opt/networker/bin/recover";
		
	$Report .= "\t$NSRrec1: ";
	if (-e $NSRrec1) {
		$Report .= "Y\n";
	} elsif (-e $NSRrec2) {
		$Report .="N\t$NSRrec2: Y\n";
	} else {
		$Report .= "N\t$NSRrec2: N\n";
		$Fail++;
	}
	
	if($Fail) {
		return $Report . "$Fail";
	} else {
		return "${Report}0";
	}
}

sub TSMCheck {
	#Paramaters
	#$chkFiles	list of files to check, seperated by "!"
	my( $chkFiles ) = @_;
	
	#local Variables
	my ($DSMsched, $DSMerror, $Report, $Stats, $Fail, $TSMbin);
	my (@CheckList, $chkFile, $count, $missed, $tmpStr, $Sudo);
	$Fail 		= 0;
	$Report 	= "TSM Check...\n";
	$TSMbin		= "/usr/bin/dsmc";
	
	#Files to look for
	$DSMsched	= "/var/opt/tsm/dsmsched.log";
	$DSMerror	= "/var/opt/tsm/dsmerror.log";
	$missed		= 0;
	@CheckList	= split(/!/, $chkFiles);
	if($<) {
		$Sudo	= "sudo";
	} else {
		$Sudo	= "";
	}
					#Check if log files exist
	$Report .= "\t$DSMsched: ";
	if (-e $DSMsched){
		$Report .= "Y";
	} else {
		$Report .= "N";
		$Fail++;
	}
	
	$Report .= "\t$DSMerror: ";
	if (-e $DSMerror){
		$Report .= "Y\n";
	} else {
		$Report .= "N\n";
		$Fail++;
	}
	if($Fail) {			#Not much hope if log files do not exist
		$Report .= "DSM log files do not appear to be present.\n";
	} else {			#Do date check on DSM log files
		$Stats = stat("$DSMsched") or $Report .= "Cann't stat $DSMsched: $!\n";
		if( !($Stats->mtime > (time - (60*60*24))) ) {
			$Report .= "$DSMsched not modified in last 24 hours.\n";
			$Report .= "It is unlikely TSM backup was successful.\n";
			$Fail++;
		}
		
		$Stats = stat("$DSMerror") or $Report .= "Cann't stat $DSMerror: $!\n";
		if( !($Stats->mtime > (time - (60*60*24))) ) {
			$Report .= "$DSMerror not modified in last 24 hours.\n";
			$Report .= "It is unlikely TSM backup was successful.\n";
			$Fail++;
		}
	}
	
	foreach $chkFile (@CheckList) {	#find some recently modified files, and check if they were backed up
		if($chkFile !~ /^\//){
			$Report .= $chkFile;
		} else {
			$count = 0;
			$tmpStr = "";
			open(DSMC, "$Sudo $TSMbin q b $chkFile 2>&1|") or return "Could not run dsmc: $!\n";
			while(<DSMC>) {
				next if ( ($count++) <9);
				if($_ =~ /$chkFile/) {
					$tmpStr = substr("$_", 18, 19);
				}
			}
			close(DSMC);
			if($tmpStr) {
				$Report .= "$chkFile backed up at $tmpStr \n";
			} else {
				$Report .= "$chkFile does not appear to have been backed up.\n";
				$missed++;
			}
			
		}
				
	}
	
	if($missed == scalar(@FileSys)) {
		$Report .="Warning!! None of the test files appear to have been backed up!\n";
	}

	$Fail += $missed;

	return ($Report . $Fail);
}

sub NSRCheck {
	#Paramaters
	#$chkFiles	list of files to check, seperated by "!"
	my( $chkFiles ) = @_;
	
	#local Variables
	my ($Report, $Stats, $Fail, $NSRrec);
	my (@CheckList, $chkFile, $count, $missed, $tmpStr, $Sudo);
	$Fail = 0;
	$Report = "NSR Check...\n";
	$missed		= 0;
	@CheckList	= split(/!/, $chkFiles);
	if($<) {
		$Sudo	= "sudo";
	} else {
		$Sudo	= "";
	}
	if(-e "/usr/bin/recover"){
		$NSRrec	= "/usr/bin/recover";
	} elsif(-e "/opt/networker/bin/recover"){
		$NSRrec	= "/opt/networker/bin/recover";
	} else {			#This should never execute, as the main program should catch this...
		return "Sorry, I cann't seem to find the nsr recover binary.\n";
	}
	
	foreach $chkFile (@CheckList) {	#find some recently modified files, and check if they were backed up
		if($chkFile !~ /^\//){
			$Report .= $chkFile;
		} else {
			$count = 0;
			$tmpStr = "";
			open(RECO,"echo 'versions $chkFile' | $Sudo $NSRrec 2>&1| head -8|") or return "Could not run recover: $!\n";
			while(<RECO>) {
				if ($_ =~ /save time/) {
					$tmpStr = substr("$_", 17);
					chomp($tmpStr);
				}
				
			}
			close(RECO);
			if($tmpStr) {
				$Report .= "$chkFile backed up at $tmpStr \n";
			} else {
				$Report .= "$chkFile does not appear to have been backed up.\n";
				$missed++;
			}
			
		}
				
	}
	
	if($missed == scalar(@FileSys)) {
		$Report .="Warning!! None of the test files appear to have been backed up!\n";
	}

	$Fail += $missed;
	return ($Report . $Fail);
}

sub FindFiles {
	use File::stat;			#Needed to stat files
	#Paramater:
	#$FSlist	List of file systems seperated by "|"
	my($FSlist, $Day) = @_;
	#Local Varaiables
	my (@FileList, @ReturnList, $Stats, $filesys, $count);

	foreach $filesys (split(/!/, $FSlist)){
		open(FIND, "find $filesys -mtime $Day -print 2>/dev/null|") or push(@ReturnList, "Couldn't run find on $filesys: $!\n");
		$count = 0;
		while(<FIND>) {
			chomp;
			$Stats = stat("$_") or next;
			next if( ( $Stats->mtime > (time-(60*60*12)) ) && ( $Day == 0) );
			push(@FileList, $_);
			$count++;
			last if $count > 20;
		}
		close(FIND);

		if(@FileList == 0) {
			push(@ReturnList, "Sorry, couldn't find a file in $filesys.\n");
		} else {
			push(@ReturnList, $FileList[int(rand scalar(@FileList))]);
		}
		
		@FileList = qw();
	}
	
	return (join("!", @ReturnList));
}
# FUTURE IDEAS
# Add checks to see if dsmcad or nsrexecd are runnint
# Change installation check to do a package quarry
# Reimplement File::Find 


#**** Tivoli output when checking a file, first fail, then success...
#Tivoli Storage Manager
#Command Line Backup Client Interface - Version 4, Release 2, Level 2.1 
#(C) Copyright IBM Corporation, 1990, 2001, All Rights Reserved.
#
#Node Name: D_QUIRK
#Session established with server BUDDHA: Solaris 7/8 
#  Server Version 4, Release 2, Level 2.12
#  Server date/time: 01/28/03   10:55:48  Last access: 01/28/03   07:38:40
#
#ANS1092E No files matching search criteria were found
#**** ^- this line is not part of the programs stdout, I can't seem to capture it...

#Tivoli Storage Manager
#Command Line Backup Client Interface - Version 4, Release 2, Level 2.1 
#(C) Copyright IBM Corporation, 1990, 2001, All Rights Reserved.
#
#Node Name: D_QUIRK
#Session established with server BUDDHA: Solaris 7/8 
#  Server Version 4, Release 2, Level 2.12
#  Server date/time: 01/28/03   10:57:47  Last access: 01/28/03   10:57:30
#
#             Size      Backup Date        Mgmt Class A/I File
#             ----      -----------        ---------- --- ----
#            4,743  01/28/03   00:30:28    DEFAULT     A  /etc/mnttab

#**** NetWorker output when checking a file, first fail, then success...
#recover> recover: Current working directory is /home/myhra01/work/
#No versions of `/usr/local/bin/perl' found in index

#recover> recover> recover: Current working directory is /home/myhra01/work/
#Display more versions of `/var/log/samba/' [y]? 
#Versions of `/var/log/samba/':
#
#   8 drwx------ root     root         8192 Jan 28 15:59  samba/
#     save time:  Tue Jan 28 17:32:05 2003        
#      location:  2000115 at /dev/nst0
