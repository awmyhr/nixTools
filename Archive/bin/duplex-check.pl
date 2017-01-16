#!/usr/local/bin/perl -w
#
# This will check each interface in the @LanCards array for "Full-Duplex",
#   if it is not, then one attempt will be made to set it to 100fd.  A 
#   report will then be generated whether or not the attempt was successful.
#   No output will be produced if no changes are needed.
# So far support has been added for HP-UX and Solaris
# Note: I have included my MailError subroutine, which is normally held in
#   a library.  This is only of interest when I update the subroutine in the
#   future, this version will not be...
#
#    Date	History
# 01/30/2003	Initial dev version
#		Basic functionality
# 01/31/2003	Remove -i option (didn't seem to work anyway) in favor or
#		   automagically detecting network interfaces
#		Move detection and setting into subroutines
#		Modified to allow for multi-platform!!
# 06/05/2003	Continued development due to an actual need for the feature to
#		   auto-detect the lancards...
# 06/06/2003	Unleashed second release (v4.x) - world beware...
# 06/09/2003	This sliped by: the script attempts to change the interface to 100fd,
#		   which won't work for 1gb connections.  Let's fix that...
#
# Start Date: 	January 30, 2003
# Coder List: 	awmyhr
# e-mail to:	awmyhr@gmail.com

use lib "$ENV{HOME}/libs";		#Library in users libs dir
use strict;				#Turn on strict, good programing
use Getopt::Std;			#Parser for command line options
use File::Basename;			#Used to get name of program
use POSIX qw(uname);                    #Use UNIX commands

use vars qw($opt_h $opt_v $opt_V $opt_s $opt_m);
					#Variables: Command line options used by Getopt
my(
	$Version,			#Const: Verison
	$MostRecentCoder,		#Const: Holds name of most recent coder
	$Modified,			#Const: Date last modified
	$Dev,				#Const: Development version?
	$ProgName,			#Const: Program Name
        $hostname,                      #Const: hostname
	$Arch,				#Const: hold name of architecture
	@LanCards,			#Const: list of lan interfaces
	$lanCard,			#Var: Card being worked on
	$Report,			#Var: compiled report
	$Reset,				#Var: flag to set if an interface has been reset
);

#Defaults

#Program info (mostly created by RCS)
$Version	= substr('$Revision: 4.2 $', 10, -1);
$Modified	= substr('$Date: 2003/06/09 20:54:26 $', 6, -1);
$MostRecentCoder= substr('$Author: awmyhr $', 8, -1);
$ProgName	= basename("$0");
$Dev		= 0;
$Reset		= 0;
$Report		= "";
$hostname       = (uname)[1];
$Arch		= $^O;
				
if( '$State: Exp $' =~ /Exp/ ) {		#Check for Development version
	$Report .= "WARNING: This is a develpment version!\n";
	$Dev=1;
}

if(!getopts('hvVsm:')) {			#Check options and warn if errors
	print "Usage: $ProgName [options]\n";
	print "Try ' -h' for more information.\n";
	exit 1;				#Exit if incorrect options
}

if($opt_h){				#Display help if asked for
	print <<END_of_text;
	Usage:	$ProgName [options]
	-s		Report to syslogd
	-m e-mail	Send report to e-mail address
        -h		Display this help and exit
	-v		Output version info and exit
	-V		Output verbose version info and exit

This program will check if interfaces are running at full duplex
   and, if they are not, it will attempt to reset them.  A report
   will be generated only if an attempt was made, successful or
   not.  For multiple e-mail addresses, enclose this space seperated
   list in double quotes.
   
Warning: no error checking is done for -m option.
   If you provide a bad address for -m, you'll get no report.
    
You must be root to run this program.
This program is only designed to work on HP-UX and Solaris.

Report bugs to awmyhr\@gmail.com
END_of_text
	exit 0;
}

if($opt_v){				#Display Version information
	print <<END_of_text;
Version: $Version  By: $MostRecentCoder
Date Created: 2003/01/30 Last Modified: $Modified
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

if($< != 0) {				#Must be root to run
	print "           Who do you think you are?\n";
	die   "Sorry, but you must be root to run this program.\n";
}
if(($Arch ne "hpux") && ($Arch ne "solaris")) {
	print "          Danger! Danger Will Robinson!\n";
	die   "This program is only designed for HP-UX & Solaris.\n";
}

@LanCards = split(/!/, GetNICs());
chomp(@LanCards);

foreach $lanCard (@LanCards) {
	
	if(!(CheckNIC($lanCard, $Arch)) ) {
		$Reset++;
		ChangeNIC($lanCard, $Arch);
		
		if(!(CheckNIC($lanCard, $Arch)) ) {
			$Report .= "Warning!  Attempt to reset $lanCard unseccessful\n";
		} else {
			$Report .= "Successfully reset $lanCard\n";
		}
	}
	
}

if($Reset) {
	$Report = "I had to reset $Reset port(s):\n$Report";

	if( (!$opt_s) && (!$opt_m) ) {	#console output
		print $Report;
	}
	
	if($opt_s){			#Create syslog entry
		open(LOG, "|/usr/bin/logger -t $ProgName");
			print LOG $Report;
		close(LOG);
	}
	
	if($opt_m){			#Send email report
		MailError($opt_m, "${hostname}_${ProgName}_report", $Report);
	}
}

if($Dev) {
	print "\n--->\n$Report\n<---\n";
}

exit 0;

#####################################################################################
#Subroutine - Sending mail

sub MailError {
        
        #Parameters are:
        #       $TOADD - To Address
        #       $SUB - Subject
        #       $MESS - Message body
        #       $FATAL - is error fatal? (0=no, 1=yes)
        
        #Variables
        my($TOADD, $SUB, $MESS, $FATAL)=@_;  #parameter list
        
        open MAIL, "|mailx -s $SUB $TOADD" or die "$MESS\n and I can't open mailx $!";
                print MAIL "$MESS\n";   #these three lines send the mail
        close MAIL  or die "$MESS\n and I can't close mailx $!";
        
        if($FATAL){ die "$MESS"; }      #This will exit the program with error message
        
        return 0;
}

#####################################################################################

#####################################################################################
#Subroutine - return list of active network interfaces

sub GetNICs {
        my (@NicList);
	
	open(NIC, "netstat -in|") or die "Sorry, could not run 'netstat -in': $!\n";
		while(<NIC>) {
			next if( ($_ =~ /^Name/) || ($_ =~ /^lo0/ ) || ($_ =~ /:/) || ($_ =~ /^\n/) );
			push(@NicList, substr($_, 0, 4));
			if ($Dev) { print "Found NIC: " . substr($_, 0, 4) . "\n"; }
		}
	close(NIC);
	
	return join("!", @NicList);
}
#####################################################################################

#####################################################################################
#Subroutine - check nics for full duplex

sub CheckNIC {
	my($lanCard, $Arch) = @_;
	my ($lanadmin, $laninst, @LanAdmin, $ndd, $Fail);
	
	$lanadmin	= "/usr/sbin/lanadmin";	
	$ndd		= "/usr/sbin/ndd";
	$Fail		= 0;

	for($Arch) {
		/hpux/ and do {
			$laninst = substr($lanCard, 3,1);
			open(LAN, "$lanadmin -x $laninst 2>&1|") or die "Sorry, couldn't run '$lanadmin -x $laninst': $!\n"; 
				@LanAdmin = readline *LAN;
			close(LAN);
	
			if(($LanAdmin[0] =~ /Full-Duplex/) || ($LanAdmin[0] =~ /not supported/) || ($LanAdmin[0] =~ /link is down/) ) {
				return 1;
			} else {
				return 0;
			}
		};
		
		/solaris/ and do {
			$laninst = substr($lanCard, 3,1);
			$lanCard = substr($lanCard, 0,3);
			
			system("$ndd -set /dev/$lanCard instance $laninst");
			open(NDD, "$ndd /dev/$lanCard link_mode|");
				$Fail = readline *NDD;
			close(NDD);
			chomp $Fail;
			
			return $Fail;
		};
		
		#Default
		return 1;
	}
}
#####################################################################################

#####################################################################################
#Subroutine - change nics to full duplex

sub ChangeNIC {
	my($lanCard, $Arch) = @_;
	my ($lanadmin, @LanAdmin);
	
	$lanadmin	= "/usr/sbin/lanadmin";	

	for($Arch) {
		/hpux/ and do {
			$lanCard = substr($lanCard, 3,1);
					#Need to check speed first
			open(LAN, "$lanadmin -x $lanCard 2>&1|") or warn "Sorry, couldn't run '$lanadmin -x $lanCard': $!\n"; 
				@LanAdmin = readline *LAN;
			close(LAN);
	
			if( ($LanAdmin[0] =~ /1000/) || ($LanAdmin[1] =~ /Autonegotiation/) ) {
											# It seems these warnings print out no matter what.  Don't know why?
				system("$lanadmin -X auto_on $lanCard 2>/dev/null")	# or warn "Sorry, couldn't run '$lanadmin -X auto_on $lanCard': $!\n";
			} else {
				system("$lanadmin -X 100fd $lanCard 2>/dev/null")	# or warn "Sorry, couldn't run '$lanadmin -X 100fd $lanCard': $!\n";
			}
			sleep 15;
			last;
		};
		
		/solaris/ and do {
			#Can't set cards through script at this time...
		};

		#Default
	}
	return;
}
#####################################################################################

# FUTURE IDEAS
