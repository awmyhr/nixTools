#!/usr/local/bin/perl -w
#
# Program to execute a single command
#   on all servers listed in a data file
# The data file has a new (tab delimited) format  
#   as of version 1.5, and is in the form of:
#     hostname1	env	proj
#     hostname2	env	proj
#       .
#       .
#       .
#     hostnameN	env	proj
# Where hostnameX is the name of the host, env
#   is the environment (i.e., dev for development,
#   prod for production), and proj is project
#   (i.e., css for CSS, sieble for Sieble).
#   Standard comments are supported (v 1.7+)
# The data file defaults to allservers.list in
#   current directory, but may be set in the
#   variable $ServerList
#
# The sensitive commands file (new in version
#   1.7 and higher) defaults to allservers.scom
#   in the current directory, but can be set in 
#   the variable $SCom.  It supports standard
#   comments, and has the format:
#     command1
#     command2
#       .
#       .
#       .
#     commandN
#
# This is based on a shell script done
#   by Gary Voigt on 04/24/98
#
#   1.0   This version is direct port to Perl
#         No added functionality at this point
#   1.1   Development version
#         "Flesh" out the Perl, conform to good
#           programming practices
#         Added Future Ideas List
#   1.3   Development version
#         Add Command line option
#           -c for command
#           -h for help
#           -v/-V for version info
#         Add Help and Version
#   1.4   Second Release
#   1.5   Add Environment support
#           -e for environment
#           -p for project
#         New data file format (backward compatible)
#         Added Check for Dev version with warning
#   1.5.1 Now checks for paramaters within the field 
#           instead of against the whole field
#   1.6   Third Release
#   1.6.1 Minor revision release
#   1.7   Added support for comments in data file
#         Check secondary file for sensitive commands
#         Added CLO for server list file
#   1.8   Fourth Release
#   1.9   Fix options to look more like GNU
#         must be root to use sensitive commands
#   2.0   Final (?) Release
#   2.1   Code clean-up/restructure
#   2.3   Feature add:
#           faster time-out for down systems
#           better reporting for unresponsive systems
#   2.4   Release with above new features
#   2.9   Revision to add support for ssh
#
# Start Date: May 01, 2001
# Coder: awmyhr
# e-mail to: awmyhr@gmail.com

use strict;				#Turn on strict, good programing
use Shell qw(rsh ssh);			#use rsh & ssh command in Perl
use Getopt::Std;			#Parser for command line options
use Net::Ping;				#To check for server response

use vars qw($opt_h $opt_v $opt_c $opt_e $opt_p $opt_f $opt_R $opt_s $opt_u);
					#Variables: Command line options
					#  used by Getopt
my(
	$Version,			#Variable: Verison
	$Dev,				#Variable: Flag for Development version
	$Modified,			#Variable: Date last modified
	$command,			#Variable: hold command string
	$confirm,			#Variable: Confirm command
	$cloError,			#Variable: Command Line Option Error
	$HostReport,			#Variable: Report output
	$ServerList,			#Variable: Server List File
	$SCom,				#Variable: Sensitive commands list
	$UserID,			#Variable: User ID
	@HostInfo,			#Variable: Expected host information
);					#  $HostInfo[0] = Hostname
					#  $HostInfo[1] = Environment
					#  $HostInfo[2] = Project
#Defaults
$Version=3.0;
$Modified="December 4, 2002";
$ServerList="$ENV{HOME}/etc/allservers.list";
$SCom="$ENV{HOME}/etc/allservers.scom";
$HostReport = "";
$Dev=0;
						
if( ($Version * 10) % 2 ) {		#Check for Development version
	print "WARNING: This is a develpment version!\n";
	$Dev=1;
}

if(!getopts('hvc:e:p:f:Rsu:')) {	#Check options and warn if errors
	print  <<END_OF_TEXT;
Usage: allservers [-c commands] [-e env] [-p proj] [-f file] [-R] [-s] [-u UID]
Try 'allservers -h' for more information.
END_OF_TEXT
	exit 1;				#Exit if incorrect options
}

if($opt_h){				#Display help if asked for
	print <<END_OF_TEXT;
Usage:\tallservers [OPTIONS]...
Execute commands on multiple servers.

	-c command	Command to execute (in quotes)
			ex: -c "uname -a"
	-f filename	Server list file
	-e env		Environment to execute in
			ex: -e dev
	-p proj		Project to execute on
			ex: -p css
	-h		Display this help and exit
	-v		Output version infromaiton and exit
	-R		Repress report output
	-s		Use secure connection (ssh)
	-u UID		User ID to use for secure connection

No -c enters "interactive" mode.
Only commands can be entered interactively.
Everything else must be done on command line.

Report bugs to awmyhr\@gmail.com

END_OF_TEXT
	exit 0;
}

if($opt_v){				#Display Version information
	print "allservers $Version  \nBy: awmyhr\n";
	print "Date Created: May 01, 2001  Last Modified: $Modified\n";
	exit 0;
}

if(!$opt_c){				# Prompt for input
	print "\n";
	print "Enter command you wish to execute on each server\n";
	print "Please use extreme CAUTION\n";
	print "\n";
	print "Enter Command ==> ";
	$command = <STDIN>;		#Get command
	print "\n";
} else{
	$command = $opt_c;
}

if($opt_s) {				#Set up user id for ssh
	if($opt_u){
		$UserID = $opt_u;
	} else {
		$UserID = getpwuid($<);
	}
}

# Open sensitive commands, or warn
open(SCOM, $SCom) || warn " No commands list: $! ";

while (<SCOM>){				#Check sensitive commands list
	next if(/^#/ || $_ eq "\n");	#If comment or new line, skip
	chomp;				#Remove Trailing \n
	next if(!($command=~/$_/));	#If text not in command, skip
	print "This command is marked sensitive: \n";
	print $_ . "\n";		#Show offending statement and prompt
	if($< != 0) {			#Only root can execute sensitive commands
		print "You do not have permision to execute this command.\n";
		exit 1;
	}
	print "Do you really want to execute: ";
	print "[rs]sh HOST " . $command . " ? ";
	$confirm = substr(<STDIN>,0,1);
	exit 1 if !($confirm eq "Y" || $confirm eq "y");
					#continue only if response starts with y or Y
}					#We could exit the loop after the first match,
					#  but we don't in case there is another

# Close sensitive commands file, or warn
close(SCOM) || warn " Problem closing commands file: $! ";

if($opt_f) { $ServerList=$opt_f; }	#Allow alternate server list

# Open server list, or die
open(HOSTLIST, $ServerList) || die " No server list: $! ";

$opt_e=lc($opt_e) if($opt_e);		#convert params to lower case
$opt_p=lc($opt_p) if($opt_p);

while (<HOSTLIST>){			#This is where all the work is done
	next if(/^#/ || $_ eq "\n");	#If comment or new line, skip
	chomp;				#Remove trailing \n
	@HostInfo=split(/\t/);		#Create array for host info

	if( (!$opt_e || lc($HostInfo[1])=~/$opt_e/) && (!$opt_p || lc($HostInfo[2])=~/$opt_p/)){
					#Test for paramaters
					#Here we will test for resonse from remote system
#		if(pingecho($HostInfo[0], 5)) {
			print $HostInfo[0] . " .. \n";	#Display host ID
			if($opt_s) {
				if($Dev) { print "ssh -l $UserID $HostInfo[0] $command\n";}
				print ssh("-l $UserID", "$HostInfo[0]", "$command");	#Send command securely
			} else {
				if($Dev) { print "rsh -l $UserID $HostInfo[0] $command\n";}
				print rsh("$HostInfo[0]", "$command");	#Send command to hosts
			}
			print "\n";	#Spacing
#		} else {		#Create report of unresponsive hosts
#			$HostReport .= "$HostInfo[0] did not respond.\n";
#		}
	}


}

# Close File, or die
close(HOSTLIST) || die " Can't close server file: $! ";

if (!$opt_R) {print $HostReport;}

#This is the end of the program....
exit 0;

# FUTURE IDEAS
#  Error logging 
#  Usage logging 
#  Output file (-o option)
#  Strengthen what little security is built-in


# We are done, you are free to go...
