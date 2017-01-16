#!/usr/local/bin/perl -w
#
# This program will take a list of users, quary a remote system
#   for their /etc/passwd entry, then create the user on the 
#   local system and set the password.
#
# Version History 
#   0.1   Initial dev version
#         Basic functionality
#   1.0   Will retrieve entries and run useradd and passwd
#   1.1   Add:
#            -A for listing usernames on commandline
#            -D for changing base homedir
#            pragma in $UserList file for setting base homedir
#   1.2   Successful implementation of new options
#   1.3   bug 1: If group doesn't exist, then user doesn't get added
#            we will now check for group before adding user.  if 
#            GID does not exist on local system, assign it a default
#         bug 2: the check for errors from system() calls does not work
#         bug 3: Need to check if username already exists
#   1.4   implemented fixes for bugs #1 & #3, partial workaround for bug #2
#         minor formatting changes
#         removed check for hp-ux version (this should work on all versions)
#         added checks for alternate passwd programs for both solaris and hp-ux
#
#    Date	History 
# 01/07/2003	Reformated to conform with template Rel2.x
#		create release version
# 01/08/2003	Start work on new version.  Features to include:
#			Create the list of users on a list of systems
#			If the user does not exist on the server, create it
#			Start modulrization by moving functions into subroutines
# 01/10/2003	Fix minor bug in ssh call which broke under Perl 5.004_5
# 10/25/2004	added (much needed) linux support
#
# Start Date: December 23, 2002
# Coder: awmyhr
# e-mail to: awmyhr@gmail.com

use lib "$ENV{HOME}/libs";		#Library in users libs dir
use strict;				#Turn on strict, good programing
use Getopt::Std;			#Parser for command line options
use File::Basename;			#Used to get name of program
use POSIX qw(uname);                    #Use UNIX commands
use Shell qw(ssh);			#use shell commands

use vars qw($opt_h $opt_v $opt_V $opt_u $opt_A $opt_D);
					#Variables: Command line options used by Getopt
my(
	$Version,			#Const: Verison
	$MostRecentCoder,		#Const: Holds name of most recent coder
	$Modified,			#Const: Date last modified
	$Dev,				#Const: Development version?
	$ProgName,			#Const: Program Name
	$Arch,				#Const: System Architecture
	$Server,			#Const: System with correct /etc/passwd info
	$ServerGrep,			#Const: grep command for the server
	$UserAdd,			#Var: full path to user add command
	$UserID,			#Variable: User ID
	$PWmod,				#Var: full path to password mod command
	@NewUsers,			#Var: list of users to be added
	$UserList,			#Var: file with list of users to be added
	$GrepList,			#Var: list of users in grep format
	@PWEnt,				#Var: /etc/passwd entries from remote system
	$FinalReport,			#Var: compile report to output at end
	$DefGID,			#Var: default GID
	$Entry,				#Var: one line from @PWEnt
	@Entry,				#Var: as above, but split into eomponents
	$HomeBase,			#Var: Base directory for home directories
		
);

#Defaults

#Constants
$Server		= "quirk";
$ServerGrep	= "/usr/bin/grep";
$UserList	= "$ENV{HOME}/new_users.list";
$GrepList	= "-e ";
$FinalReport	= "User Add done at: " . localtime(time) . ".\n\n";
$HomeBase	= "/home";
$UserID 	= getpwuid($<);

#Set work variables for different architectures
$Arch           = $^O;                  #We do this just for easier readability later on
                                        #Some possible values: solaris, hpux, cygwin
#Program info (mostly created by RCS)
$Version	= substr('$Revision: 3.2 $', 10, -1);
$Modified	= substr('$Date: 2004/10/25 16:08:43 $', 6, -1);
$MostRecentCoder= substr('$Author: awmyhr $', 8, -1);
$ProgName	= basename("$0");
						
if( '$State: Exp $' =~ /Exp/ ) {		#Check for Development version
	print "WARNING: This is a develpment version!\n";
	$Dev=1;
}

if(!getopts('hvVu:A:D:')) {		#Check options and warn if errors
	print "Usage: $ProgName [options]\n";
	print "Try ' -h' for more information.\n";
	exit 1;				#Exit if incorrect options
}

if($opt_h){				#Display help if asked for
	print <<END_of_text;
Usage:	$ProgName [options]
	-A username	Provide list of user names instead of file
				(See below for more info)
	-D directory	Set base home directory
				(Default: $HomeBase)
	-u UID		Set user ID for remote system
				(Default: $UserID )
        -h		Display this help and exit
	-v		Output version infromaiton and exit
	-V		Output verbose version info and exit

    This program makes it easier to add a list of users to a system.  It will
take a list of usernames, either from the command line or a file ($UserList).
Then, a server ($Server) is queried for the /etc/passwd string for each user
name.  The system command to add a user is then invoked and passed the 
appropriate parameters.  The user home directory is set to $HomeBase/username,
but that may be changed on the command line with the -D option, or in the
user name file.

    The user name file ($UserList) is a simple text file with a list of user 
names to be added, one per line.  The base home directory may be changed by 
adding a line with the full directory path.  The list of user names may be
provided on the command line instead with the -A option.  The list should
be comma seperated and enclosed in double quotes.

Report bugs and comments to awmyhr\@gmail.com
END_of_text
	exit 0;
}

if($opt_v){				#Display Version information
	print <<END_of_text;
Version: $Version  By: $MostRecentCoder
Date Created: December 23, 2002  Last Modified: $Modified
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

if($opt_u){ $UserID = $opt_u; }

if($opt_D){ $HomeBase = $opt_D; }

for($Arch){                             #Set Architecture specific variables
        /solaris/ and do{
		$UserAdd	= "/usr/local/bin/sudo /usr/sbin/useradd";
		if(-e "/usr/local/bin/mkpasswd") {
			$PWmod	= "/usr/local/bin/sudo /usr/local/bin/mkpasswd";
		} else {
			$PWmod	="/usr/local/bin/sudo /usr/bin/passwd";
		}
                $DefGID		= 10;
		
		last;
        };

        /linux/ and do{
		$UserAdd	= "/usr/bin/sudo /usr/sbin/useradd";
		if(-e "/usr/bin/mkpasswd") {
			$PWmod	= "/usr/bin/sudo /usr/bin/mkpasswd";
		} else {
			$PWmod	="/usr/bin/sudo /usr/bin/passwd";
		}
                $DefGID		= 10;
		
		last;
        };

        /hpux/ and do{
		$UserAdd	= "/usr/local/bin/sudo /usr/sbin/useradd";
		if(-e "/usr/lbin/modprpw") {
			$PWmod	= "/usr/local/bin/sudo /usr/lbin/modprpw -x";
		} else {
			$PWmod	="/usr/local/bin/sudo /usr/bin/passwd";
		}
		$DefGID		= 20;
		
                last;
        };

        /cygwin/ and do{                #Test case
		$UserAdd	= "echo useradd";
		$PWmod		= "echo passwd";
		$DefGID		= 546;
		
                last;
        };

        #default
        die "Sorry, I'm not programed for $Arch.\n";
};

#Get list of users to add
if($opt_A) {
	@NewUsers = split(",", $opt_A);
} else {
	open(USER, $UserList) or die "Cann't find list of users ($UserList): $!\n";
	while(<USER>) {
		if(/^\//) {			#Alternative home dir specified in file
			chomp;
			$HomeBase = $_;
			next;
		}
		next if(/^#/ || $_ eq "\n");	#If comment or new line, skip
		chomp;				#Remove trailing \n
		push @NewUsers, $_;	
	}
	close(USER) or warn "Problem closing user list file ($UserList): $!\n";
}
$GrepList .= join " -e ", @NewUsers;	#Prepare list for grep
$FinalReport .= "I will attempt to add the following users: " . (join ", ", @NewUsers) .  "\n\n";

#Check validity of $HomeBase
if(substr($HomeBase, -1) ne "/") { $HomeBase .= "/"; }
if (!( -d $HomeBase)) { die "$HomeBase is not a valid directory.\n"; }

#Get /etc/passwd entries from $Server
if($Dev) { print "-> ssh -l$UserID $Server $ServerGrep $GrepList /etc/passwd\n\n";}
@PWEnt =  ssh("-l$UserID", "$Server", "$ServerGrep  $GrepList /etc/passwd");	#retrieve pw file entries
if($Dev) { print "@PWEnt\n"; }
chomp @PWEnt;

#Process each line of @PWEnt
foreach $Entry (@PWEnt) {
	@Entry = split(":", $Entry);
	if(getpwuid($Entry[2])) {	#Check if UID already exists
		if($Entry[0] eq getpwuid($Entry[2])) {
			$FinalReport .= "$Entry[0] -> User appears to already exist.\n";
		} else {		#Check if UID and username are the same as user being added
			$FinalReport .= "$Entry[0] -> UID $Entry[2] already belongs to: " . getpwuid($Entry[2]) . "\n";
		}
		next;
	}
	if(getpwnam($Entry[0])) {	#Check if username already exists
		if($Entry[2] eq getpwnam($Entry[0])) {
			$FinalReport .= "$Entry[0] -> User appears to already exist.\n";
		} else {		#Check if UID and username are the same as user being added
			$FinalReport .= "$Entry[0] -> Username exists with UID " . getpwnam($Entry[0]) . ".\n";
		}
		next;
	}
	if(!(getgrgid $Entry[3])) {	#Check if GID exists, if not, use default
		$FinalReport .= "$Entry[0] -> GID $Entry[3] does not exist on this system.  Assigning GID: $DefGID.  Please investigate.\n";
		$Entry[3] = $DefGID;
	}

	if($Dev) { print "-> $UserAdd -u $Entry[2] -g $Entry[3] -c '$Entry[4]' -d $HomeBase$Entry[0] -s $Entry[6] -m $Entry[0]\n"; }
	system( "$UserAdd -u $Entry[2] -g $Entry[3] -c '$Entry[4]' -d $HomeBase$Entry[0] -s $Entry[6] -m $Entry[0]" );
	if(!getpwuid($Entry[2])) {	#Need to find better way to determine if system() failed
		$FinalReport .= "$Entry[0] -> Unable to add: $!\n";
		next;
	} else {
		$FinalReport .= "$Entry[0] -> Added successfully!\n";
	}
	
	if($Dev) { print "-> $PWmod $Entry[0]\n"; }
	print "$Entry[0] -> Set Password: \n";
	system( "$PWmod $Entry[0]" );
	if($!) {
		$FinalReport .= "$Entry[0] -> Unable to set password: $!\n";
		next;
	} else {
		$FinalReport .= "$Entry[0] -> Password set successfully!\n";
	}
}

print "\n----------------------------------------\n";
print $FinalReport . "\n";

exit 0;


# FUTURE IDEAS
# add options to change file for the username list
# perhaps add option to change server, but this could cause problems
#   with the program knowing which grep to use on the remote system.
#   It could also be a security risk.
# add mechanism to track and report the difference between what usernames
#   were input, and which usernames where actually found on the remote system
#   without invoking ssh more than one time.  .
