#!/usr/local/bin/perl -w
#
# SysInfo.pl - This will report detailed system information
#
# This project takes a much older version of SysInfo and cuts out
#    parts/reformats it/ and repurposes it. The SysInv client takes care of
#    basic system reporting, so that'll be removed. Now we'll focus more on
#    large data dumps (messages, sulog, lastroot, lastboot, etc) that don't
#    work well in the SysInv project. We'll retain the multiple output format,
#    as we have a goal of making partial pages for the sysr site which can be
#    called up. This will necessitate a server side program, as well as a bit
#    of glue (or an option) for sending the output there...
#
# Version History
#   0.1   Initial dev version
#
# Start Date: May 27, 2004
# Coder: awmyhr
# e-mail to: awmyhr@gmail.com

use lib "$ENV{HOME}/lib";		#Library in users libs dir
use lib "/usr/local/lib/perl";		#Library in local lib dir
use strict;				#Turn on strict, good programing
use Getopt::Std;			#Parser for command line options
use File::Basename;			#Used to get name of program
use IO::Socket;				#used for tcp operations
use POSIX qw(uname);                    #use UNIX commands
require "perl_subs.pl";			#need custom perl subs...

if(!(leastPerlsubsVersion("1.12")))
	{die "Must have version 1.12 or later of perl_subs.pl.\n";}

use vars qw($opt_h $opt_v $opt_f $opt_d $opt_i $opt_b $opt_V);
					#Variables: Command line options used by Getopt
my(
	$Version,			#Const: Verison
	$MostRecentCoder,		#Const: Holds name of most recent coder
	$Modified,			#Const: Date last modified
	$Dev,				#Const: Development version?
	$ProgName,			#Const: Program Name
	$hostname,			#const: system hostname
	$output,			#Variable: collect output before printing
	$URLpath,			#Const: url to post to (path part)
	$URLserver,			#const: url to post to (server part)
	@info,				#Array:	   List of types of information
	@format,			#Array:    List of types of formats
	$Verb,				#Const: verbosity enabled/disabled
	$LogFile,			#Var: logfile to put report if format is email
	$MailTo,			#Var: space seperated list of email recipients
);

#Defaults
$output		= "";
@info 		= qw(all mess sulog lroot lboot df acpu acct aset prtd proc);
@format 	= qw(console email html phtml sysr);
$Verb		= 0;
$hostname	= (uname)[1];
$MailTo		= "test\@test.com";
$URLpath 	= "/perl/SysRep_server.pl";
$URLserver 	= "test.test.com";

if($^O =~ /linux/) {
	$LogFile	= "/var/log/SysInfo.txt";
} else {
	$LogFile	= "/var/adm/SysInfo.txt";
}

$Version	= "0.1";
$Modified	= "2005-05-27";
$MostRecentCoder= "awmyhr";
$ProgName	= basename("$0");
$Dev		= 0;

if( $Dev ) {		#Check for Development version
	$URLpath = "~/TestSysAdmin/perl/SysRep_server.pl";
	$output .= "WARNING: This is a develpment version!\n";
	$output .= "\tPlease let me (Andy MyHR) know what you think of the contents of this report.\n";
	$output .= "======================================================================\n\n\n";
	$Dev=1;
}

if(!getopts('hvVf:d:i:b:')) {		#Check options and warn if errors
	print "Usage: $ProgName [OPTIONS]\n";
	print "Try ' -h' for more information.\n";
	exit 1;				#Exit if incorrect options
}

if($opt_h){				#Display help if asked for
	print <<END_of_text;
	Usage:	SysInfo [OPTIONS]
	-f format	Output format.  Default: console
	-d number	Number of days previous to today.  Default: 0
	-i type of info	Type of info to display.  Default: all
        -h		Display this help and exit.
	-v		Output version infromaiton and exit.
Output format can be console, html, phtml, or text.  Number of days is
reletive to current day, and can be 0-7.  Types of info avialable are
messages, sulog, lastroot, lastboot, and all.
Report bugs to awmyhr\@gmail.com
END_of_text
	exit 0;
}

if($opt_v){				#Display Version information
	print <<END_of_text;
Version: $Version  By: $MostRecentCoder
Date Created: 2005-05-27  Last Modified: $Modified
END_of_text
	print "perl_subs.pl:\n" . perl_subs_version();
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

if($opt_d) {				#Check number of days, max 14
	if($opt_d < 0 || $opt_d > 14 || $opt_d =~ /\D/) {
		print "Option d is invalid.\n";
		print "-d should be a number from 0 - 14.\n";
		exit 1;
	}
} else {				#Default to today
	$opt_d=0;
}

if(!$opt_i or $opt_i eq "all") {	#default to display all data
	$opt_i = "all";
} elsif(!InArray($opt_i, \@info)) {
	print <<END_of_text;
Option i is invalid. $opt_i
Currently provided information is:
	mess	/var/adm/messages
	sulog	su log
	lroot	last root
	lboot	last boot
	bui	backup info
	df	disk full (disks over 90%)
	proc	list top ten processes
	acpu	acct cpu report
	acct	acct general report
	aset	aset reports (not yet implemented)
	prtd	prtdiag report (not yet implemented)
END_of_text
	exit 1;
}

if(!$opt_b) {				#give baseurl a default
	$opt_b="http://localhost/sysinfo/";
}					#need to add more I think
					#Actually, I may dump this
if(!$opt_f) {
	$opt_f = "console";		#default to console display
}

$output .= "System Health Report for $hostname ($^O " . (uname)[2] . " [" . (uname)[3] . "]).\n";
$output .= "\tDone on " . DateStamp("5") . " for date " . DateStamp("2", -$opt_d) . " by version $Version\n";

#do the work
if( ($opt_f eq "console") or ($opt_f eq "email") ) {
	$output .= CreateConsole($opt_d, $opt_i, $Verb);
} elsif( ($opt_f eq "html") or ($opt_f eq "phtml") or ($opt_f eq "sysr") ) {
	$output = CreateHTML($opt_d, $opt_i, $opt_f, $opt_b, $Verb, $output);
} else {
	print <<END_of_text;
Option f is invalid
Currnetly supported formats are:
	console	console display (default)
	email	send output of console to email
	html	html file
	phtml	phtml file (for page.pl - DocIt)
END_of_text
	exit 1;
}


#print the output
if($opt_f eq "email") {
	if(-e $LogFile){
		unlink $LogFile;
	}
	open(LOG, ">$LogFile") or warn "can't open $LogFile: $!";
		print LOG $output;
	close(LOG);
	chown 0, 0, $LogFile;
	chmod 0644, $LogFile;
	MailError($MailTo, "'(new) System Health Report for $hostname'", $output);
} elsif ($opt_f eq "sysr") {  #This will eventually post data to an URL
	my(
		%sysinfo,	#hash: created hash to send via post
		$key,		#var: hold hash keys
		$info,		#var: hold message to post
		$data,		#var: more message building variables
		$sock,		#var: hold sock handler
		$return,	#var: print return info
	);
	$info="";
	($hostname) = split(/\./, $hostname);
	#First, get the info, and ready it for sending
	$sysinfo{"host"} = $hostname;
	$sysinfo{"data"} = $output;
	$sysinfo{"user"} = getlogin();
	foreach $key (sort keys %sysinfo) {
	        $sysinfo{$key} = URL_Encode($sysinfo{$key});
		#need to url-encode
		$info .= "$key=$sysinfo{$key}&";
	}

	chop($info);

	#now, create the message
	$data  = "POST $URLpath HTTP/1.0\n";
	$data .= "Content-length: " . length($info) . "\n";
	$data .= "content-type: application/x-www-form-urlencoded\n\n";
	$data .= $info;

	#next, create tcp socket
	$sock = new IO::Socket::INET (PeerAddr => "$URLserver",
					PeerPort => 80,
					Proto    => 'tcp',
					Type     => SOCK_STREAM);
	die "Unable to establish connection: $!\n" unless $sock;

	#send the message
	$sock->send($data);

	#get results
	$sock->recv($return,4096);

	print $return;
} else {
	print $output;
}

#End of Program
exit 0;

#####################################################################################
#Subroutine - Create console display

sub CreateConsole {
	#Parameters are:
	#	$dayo - day offset
	#	$info - what info to get
	#	$Verb - verbosity
	my($dayo, $info, $Verb)=@_;

	#Local variables
	my($data, $div, $date);
	$data = "";
	$div = "\n======================================================================\n";
	$date = DateStamp("3", $dayo);

	for($info){			#Get and build output
		/all/ and do {
			$data .= "${div}System last booted: \n" . GetLBoot();
			$data .= "${div}Disk Usage:\n" . GetDF($Verb);
			$data .= "${div}Swap and Memory:\n" . GetSwap();
			$data .= "${div}Lan Info:\n" . GetLan();
			$data .= "${div}Check Backup systems:\n" . GetBUinfo();
			$data .= "${div}Top Ten Processes:\n" . GetProc();
			$data .= "${div}Users Still Logged In:\n" . GetLogIn();
			$data .= "${div}su log for $date: \n" . GetSuLog($dayo);
			$data .= "${div}Root logins for $date: \n" . GetLRoot($dayo);
			$data .= "${div}System Messages for $date: \n" . GetMess($dayo);
			$data .= "${div}Hardware Info: \n" . GetHWinfo();
			$data .= "${div}Patch Info:\n" . GetPatch();
			last;
		};
		/mess/ and do {
			$data .= "/var/adm/messages: \n" . GetMess($dayo);
			last;
		};
		/sulog/ and do {
			$data .= "su log:\n" . GetSuLog($dayo);
			last;
		};
		/lroot/ and do {
			$data .= "Last root logins:\n" . GetLRoot($dayo);
			last;
		};
		/lboot/ and do {
			$data .= "System last booted: " . GetLBoot();
			last;
		};
		/df/  and do {
			$data .= "Full disks:\n" . GetDF($Verb);
			last;
		};
		/bui/ and do {
			$data .= "Check Backup systems:\n" . GetBUinfo();
			last;
		};
		/proc/ and do {
			$data .= "Top Ten Processes:\n" . GetProc();
			last;
		};
		#acpu, acct, aset, prtd

		#Default response - This should never execute
		$data .= "Invalid information request for console output.\n";
	}

	return $data;
}


#####################################################################################
#Subroutine - Create html/phtml display

sub CreateHTML {
	#Parameters are:
	#	$dayo - day offset
	#	$info - What info to get
	#	$format - What format to send
	#	$baseurl - base url for MoreFiles links
	#	$Verb - verbosity
	#	$input - data collected before this function call
	my($dayo, $info, $format, $baseurl, $Verb, $input)=@_;

	#Local variables
	my($data, $sub);
	$data = "";

	if($format eq "html") {		#Very Simple html header
		$data .= <<END_of_text;
<!DOCTYPE HTML PUBLIC "-W3C//DTD HTML 4.0 Transitional//EN">
<html>
<head>
	<title>System Information</title>

	<meta http-equiv="Content-Type" content="text/html; charset=windows-1252">
	<meta name="Generator" content="$ProgName, Version: $Version">
</head>
<body>
END_of_text
	}

	$input =~ s/\n/<br>/g;
	$input =~ s/\t/&nbsp;&nbsp;&nbsp;&nbsp;/g;

	$data .= "$input<br>";
	$data .= "<table border=\"2\">\n";

	for($info) {		#do all
		/all/ and do {
			$sub = GetMess($dayo); $sub =~ s/\n/<br>/g; $sub =~ s/\t/&nbsp;&nbsp;&nbsp;&nbsp;/g;
			#$data .= "<tr><td align=\"center\"><b>System Messages</b></td></tr>\n<tr><td><pre>\n" . $sub . "\n</pre>" . MoreFiles("/var/adm/messages", "mess", "$baseurl"). "</td></tr>\n";
			$data .= "<tr><td align=\"center\"><b>System Messages</b></td></tr>\n<tr><td><pre>\n" . $sub . "\n</pre></td></tr>\n";
			$sub = GetSuLog($dayo); $sub =~ s/\n/<br>/g; $sub =~ s/\t/&nbsp;&nbsp;&nbsp;&nbsp;/g;
			#$data .= "<tr><td align=\"center\"><b>su log</b></td></tr>\n<tr><td><pre>\n" . $sub . "\n</pre>" . MoreFiles("/var/adm/sulog", "sulog", "$baseurl"). "</td></tr>\n";
			$data .= "<tr><td align=\"center\"><b>su log</b></td></tr>\n<tr><td><pre>\n" . $sub . "\n</pre></td></tr>\n";
			$sub = GetLRoot($dayo); $sub =~ s/\n/<br>/g; $sub =~ s/\t/&nbsp;&nbsp;&nbsp;&nbsp;/g;
			$data .= "<tr><td align=\"center\"><b>Last root logins</b></td></tr>\n<tr><td><pre>\n" . $sub . "\n</pre></td></tr>\n";
			$sub = GetDF($Verb); $sub =~ s/\n/<br>/g; $sub =~ s/\t/&nbsp;&nbsp;&nbsp;&nbsp;/g;
			$data .= "<tr><td align=\"center\"><b>Full disks</b></td></tr>\n<tr><td><pre>\n" . $sub . "\n</pre></td></tr>\n";
			$sub = GetLBoot(); $sub =~ s/\n/<br>/g; $sub =~ s/\t/&nbsp;&nbsp;&nbsp;&nbsp;/g;
			$data .= "<tr><td align=\"center\"><b>System last booted:</b> " . $sub . "\n</td></tr>\n";
			$sub = GetSwap(); $sub =~ s/\n/<br>/g; $sub =~ s/\t/&nbsp;&nbsp;&nbsp;&nbsp;/g;
			$data .= "<tr><td align=\"center\"><b>Swap and Memory:</b>\n" . $sub . "\n</td></tr>\n";
			$sub = GetLan(); $sub =~ s/\n/<br>/g; $sub =~ s/\t/&nbsp;&nbsp;&nbsp;&nbsp;/g;
			$data .= "<tr><td align=\"center\"><b>Lan Info:</b>\n" . $sub . "\n</td></tr>\n";
			$sub = GetBUinfo(); $sub =~ s/\n/<br>/g; $sub =~ s/\t/&nbsp;&nbsp;&nbsp;&nbsp;/g;
			$data .= "<tr><td align=\"center\"><b>Check Backup systems:</b>\n" . $sub . "\n</td></tr>\n";
			$sub = GetProc(); $sub =~ s/\n/<br>/g; $sub =~ s/\t/&nbsp;&nbsp;&nbsp;&nbsp;/g;
			$data .= "<tr><td align=\"center\"><b>Top Ten Processes:</b>\n" . $sub . "\n</td></tr>\n";
			$sub = GetLogIn(); $sub =~ s/\n/<br>/g; $sub =~ s/\t/&nbsp;&nbsp;&nbsp;&nbsp;/g;
			$data .= "<tr><td align=\"center\"><b>Users Still Logged In:</b>\n" . $sub . "\n</td></tr>\n";
			$sub = GetHWinfo(); $sub =~ s/\n/<br>/g; $sub =~ s/\t/&nbsp;&nbsp;&nbsp;&nbsp;/g;
			$data .= "<tr><td align=\"center\"><b>Hardware Info:</b> \n" . $sub . "\n</td></tr>\n";
			$sub = GetPatch(); $sub =~ s/\n/<br>/g; $sub =~ s/\t/&nbsp;&nbsp;&nbsp;&nbsp;/g;
			$data .= "<tr><td align=\"center\"><b>Patch Info:</b>\n" . $sub . "\n</td></tr>\n";
			last;
		};
		/mess/ and do {
			$data .= "<tr><td align=\"center\">/var/adm/messages</td></tr>\n<tr><td><pre>\n" . GetMess($dayo) . "\n</pre></td></tr>\n";
			last;
		};
		/sulog/ and do {
			$data .= "<tr><td align=\"center\">su log</td></tr>\n<tr><td><pre>\n" . GetSuLog($dayo) . "\n</pre></td></tr>\n";
			last;
		};
		/lroot/ and do {
			$data .= "<tr><td align=\"center\">Last root logins</td></tr>\n<tr><td><pre>\n" . GetLRoot($dayo) . "\n</pre></td></tr>\n";
			last;
		};
		/lboot/ and do {
			$data .= "<tr><td align=\"center\">System last booted: " . GetLBoot() . "\n</td></tr>\n";
			last;
		};
		/df/ and do {
			$data .= "<tr><td align=\"center\">Full disks</td></tr>\n<tr><td><pre>\n" . GetDF($Verb) . "\n</pre></td></tr>\n";
			last;
		};
		/acpu/ and do {
			$data .= "<tr><td align=\"center\">acct CPU report</td></tr>\n<tr><td><pre>\n" . GetAcpu() . "\n</pre></td></tr>\n";
			last;
		};
		/acct/ and do {
			$data .= "<tr><td align=\"center\">acct CPU report</td></tr>\n<tr><td><pre>\n" . GetAcct() . "\n</pre></td></tr>\n";
			last;
		};
		#aset, prtd


		#Default response - This should never execute
		$data .= "$info: Invalid information request for web output.\n";
	}

	$data .="</table>\n";

	if($format eq "html") {		#Very simple html footer
		$data .= <<END_of_text;
</body>
</html>
END_of_text
	}

	return $data;
}

#####################################################################################
#Subroutine - Get /var/adm/messages

sub GetMess {
	#Parameters are:
	#	$dayo - day offset
	my($dayo)=@_;

	#Local variables
	my($date, $data, $messfile);
	$date = DateStamp("2", -$dayo);
	$data ="";

	for($^O) {
		/solaris/ and do {
			$messfile = "/var/adm/messages";
			last;
		};

		/hpux/ and do {
			$messfile = "/var/adm/syslog/syslog.log";
			last;
		};

		/linux/ and do {
			$messfile = "/var/log/messages";
			last;
		};

		/cygwin/ and do {
			return "System messages not valid under cygwin.\n";
			last;
		};

		#default
		return "Sorry, I don't know where system messages are for $^O \n";
	}

	$data .= ReadFile($messfile, "Unable to read $messfile", $date);

	return "$data\n";
}

#####################################################################################
#Subroutine - Get su log info

sub GetSuLog {
	#Parameters are:
	#	$dayo - day offset
	my( $dayo)=@_;

	#Local variables
	my($date, $data, $sulog);
	$date = DateStamp("3", -$dayo);
	$data="";

	for($^O) {
		/solaris/ and do {
			$sulog = "/bin/cat /var/adm/sulog";
			last;
		};

		/hpux/ and do {
			$sulog = "/bin/cat /var/adm/sulog";
			last;
		};

		/linux/ and do {
			$sulog = "/bin/grep 'su(pam_unix)' /var/log/messages";
			last;
		};

		/cygwin/ and do {
			return "Su Log not valid under cygwin.\n";
			last;
		};

		#default
		return "Sorry, I don't know how to obtain su log info for $^O \n";
	}

	$data .= GetOutput($sulog, "Could not get sulog", $date);

	return "$data";
}

#####################################################################################
#Subroutine - Get disk full info

sub GetDF {
	#Paramater
	#$verb	verbosity enabled
	my($verb) = @_;

	#Local variables
	my($data, $dfprog, $thresh, @dfdata);
	$data	= "";

	for($^O) {
		/solaris/ and do {
			$dfprog = "df -kl";
			last;
		};

		/hpux/ and do {
			$dfprog = "bdf -l";
			last;
		};

		/linux/ and do {
			$dfprog = "df -hl";
			last;
		};

		/cygwin/ and do {
			$dfprog = "df -h";
			last;
		};

		#default
		return "Sorry, I don't know how to obtain disk info on $^O \n";
	}

	if($verb) {
		$thresh = 80;
	} else {
		$thresh = 90;
	}

	open(DF, "$dfprog |") or return "Could not run df: $!\n";

	while(<DF>) {			#we do not want home dirs or the cdrom
		next if( ($_ =~ /Filesystem/) || ($_ =~ /home/) || ($_ =~ /cdrom/) || ($_ =~ /CDROM/) || ($_ =~ /net/));
		next if( ($_ =~ /proc/) || ($_ =~ /^fd/) || ($_ =~ /^mnttab/) || ($_ =~ /^swap/));
		@dfdata = split;
		next if(!$dfdata[4]);
		chop($dfdata[4]);
		next if ($dfdata[4] =~ /\D/);

		if($dfdata[4] > $thresh) {
			$data .= "-->>\t$dfdata[4]\t$dfdata[5]\t$dfdata[0]\t<<--\n";
		} else {
			$data .= "$dfdata[4]\t$dfdata[5]\t$dfdata[0]\n";
		}
	}

	close(DF);

	return "$data";
}

#####################################################################################
#Subroutine - Get Last Root info

sub GetLRoot {
	#This routine requires perl_subs.pl
	#Parameters are:
	#	$dayo - day offset
	my($dayo)=@_;

	#Local variables
	my($data, $date, $line, $getroot);
	$data	= "";

	for($^O) {
		/solaris/ and do {
			$getroot = "last root";
			last;
		};

		/hpux/ and do {
			$getroot = "last root";
			last;
		};

		/linux/ and do {
			$getroot = "last root";
			last;
		};

		/cygwin/ and do {
			return "Last Root not valid under cygwin.\n";
			last;
		};

		#default
		return "Sorry, I don't know how to get last root on $^O \n";
	}

	$date = DateStamp("2", -$dayo);

	open(LROOT, "$getroot|") or $data = "Coud not run last root: $!";

	while(<LROOT>) {
		if($_ =~ /$date/) {
			$data .= $_;
		} else {
			last;		#This works becouse of the way last displays it's otuput
		}
	}

	close(LROOT);# or $data .= "Could not close last root: $!";

	return "$data\n";
}

#####################################################################################
#Subroutine - Get Last Boot info

sub GetLBoot {
	use Shell qw(who uptime);	#Going to use the who command
	#Parameters are:

	#Local variables
	my($data, @uptime);
	$data	= "";

	if( ($^O =~ /cygwin/) || ($^O =~ /linux/) ) {
		$data = "Last Boot not valid under $^O.\n";
	} else {
		$data = who("-b");
		chomp($data = substr($data, index($data, "ot") + 4));
	}

	@uptime = split(/,/, uptime());
	$data .= "\tSystem " . substr($uptime[0], index($uptime[0], "up")) . " $uptime[1]\n";

	return "$data";
}

#####################################################################################
#Subroutine - Get acct cpu info

sub GetAcpu {
	#This routine requires perl_subs.pl
	#Parameters are:

	#Local variables
	my($data, $acpufile);
	$data ="";

	for($^O) {
		/solaris/ and do {
			$acpufile = "/var/adm/acct/sum/cpu" . DateStamp(4);
			last;
		};

		#default
		return "Sorry, I don't know where to find CPU accounting on $^O \n";
	}

	$data .= ReadFile($acpufile, "Could not get CPU accounting info");

	return "$data";
}


#####################################################################################
#Subroutine - Get acct report

sub GetAcct {
	#This routine requires perl_subs.pl
	#Parameters are:

	#Local variables
	my($data, $acctfile);
	$data	= "";

	for($^O) {
		/solaris/ and do {
			$acctfile = "/var/adm/acct/sum/rprt" . DateStamp(4);
			last;
		};

		#default
		return "Sorry, I don't know where to find accounting on $^O \n";
	}

	$data .= ReadFile($acctfile, "Could not get accounting info");

	return "$data";
}

#####################################################################################
#Subroutine - Do a backup check

sub GetBUinfo {
	#This routine requires bucheck.pl
	#Parameters are:

	#Local variables
	my($data, $bucheck);
	$data	= "";
	$bucheck = "/usr/local/bin/bucheck.pl";

	if(!(-e "$bucheck")) {
		return "Sorry, I could not find $bucheck\n";
	} else {
		open(FILE, "$bucheck -y 2>&1|") or $data = "Could not run $bucheck: $!\n";

		while(<FILE>) {			#This is where to process the file
			next if( ($_ =~ /readline/) or ($_ =~ /stat/) );
			$data .= $_;
		}

		close(FILE);

		return "$data\n";
	}
}

#####################################################################################
#Subroutine - Get list of users still logged in

sub GetLogIn {
	#Parameters are:

	#Local variables
	my($data, $line, $getli);
	$data	= "";
	$getli = "last";

	$data .= GetOutput($getli, "Could not get list of users still logged in", "still");

	return "$data";
}

#####################################################################################
#Subroutine - Get proccess info

sub GetProc {
	#Paramater

	#Local variables
	my($data, $psprog, @psout, %psdata, $count, $time);
	$data="";
	$count=0;

	for($^O) {
		/solaris/ and do {
			$psprog = "ps -ed";
			last;
		};

		/hpux/ and do {
			$psprog = "ps -ed";
			last;
		};

		/linux/ and do {
			$psprog = "ps -ed";
			last;
		};

		/cygwin/ and do {
			$psprog = "ps -esW";
			$data .= "cygwin returns time process started, not running time.\n";
			last;
		};

		#default
		return "Sorry, I don't know how to obtain process info on $^O \n";
	}

	open(PS, "$psprog |") or return "Could not run ps: $!\n";

	while(<PS>) {
		next if( ($_ =~ /COMMAND/) );
		chomp;
		@psout = split;
		$psdata{$psout[2]} = $psout[3]
	}

	close(PS);

	foreach $time (reverse sort { SortTime($a, $b) } keys %psdata) {
		last if( ($count > 10) );
		$data .= "\t$time\t$psdata{$time}\n";
		$count++;
	}

	return "$data";
}

#####################################################################################
#Subroutine - Get Hardware info

sub GetHWinfo {
	#Paramater

	#Local variables
	my($data, $hwiprog);
	$data="";

	for($^O) {
		/solaris/ and do {
			$hwiprog = "/usr/platform/sun4u/sbin/prtdiag -v";
			# ^^ we need to make this 'usr/platform/uname -m|/usr/bin/arch -k/sbin/prtdiag
			last;
		};

		/hpux/ and do {
			$hwiprog = "/usr/sbin/ioscan -fun";
			last;
		};

		/cygwin/ and do {
			$hwiprog = "cat /proc/cpuinfo";
			last;
		};

		/linux/ and do {
			$hwiprog = "cat /proc/cpuinfo;cat /proc/pci";
			last;
		};

		#default
		return "Sorry, I don't know how to obtain hardware info on $^O \n";
	}

	$data .= GetOutput($hwiprog, "Could not get hardware info");

	return "$data";
}

#####################################################################################
#Subroutine - Get swap & memory info

sub GetSwap {
	#Paramater

	#Local variables
	my($data, $swapprog);
	$data="";

	for($^O) {
		/solaris/ and do {
			$swapprog = "/usr/sbin/swap -l;/usr/sbin/swap -s";
			last;
		};

		/hpux/ and do {
			$swapprog = "grep Physical /usr/adm/syslog/syslog.log;/usr/sbin/swapinfo";
			last;
		};

		/cygwin/ and do {
			$swapprog = "cat /proc/meminfo";
			last;
		};

		/linux/ and do {
			$swapprog = "cat /proc/meminfo";
			last;
		};

		#default
		return "Sorry, I don't know how to obtain swap info on $^O \n";
	}

	$data .= GetOutput($swapprog, "Could not get swap info");

	return "$data";
}

#####################################################################################
#Subroutine - Get active lans

sub GetLan {
	#Paramater

	#Local variables
	my($data, $lanprog);
	$data="";

	for($^O) {
		/solaris/ and do {
			$lanprog = "ifconfig -a";
			last;
		};

		/hpux/ and do {
			$lanprog = "lanscan";
			last;
		};

		/cygwin/ and do {
			$lanprog = "ipconfig /all";
			last;
		};

		/linux/ and do {
			$lanprog = "ifconfig -a";
			last;
		};

		#default
		return "Sorry, I don't know how to obtain LAN info on $^O \n";
	}

	$data .= GetOutput($lanprog, "Could not get LAN info");

	return "$data";
}

#####################################################################################
#Subroutine - Get patch info

sub GetPatch {
	#Paramater

	#Local variables
	my($data, $patchprog);
	$data="";

	for($^O) {
		/solaris/ and do {
			$patchprog = "showrev -p";
			last;
		};

		/hpux/ and do {
			$patchprog = "ls /var/adm/sw/save";
			last;
		};

		/cygwin/ and do {
			$data .= "cygcheck -c would be more appropriate, but we use cygcheck -s cuz it's much faster.\n";
			$patchprog = "cygcheck -s";
			last;
		};

		/linux/ and do {
			$patchprog = "rpm  -q -a";
			last;
		};

		#default
		return "Sorry, I don't know how to obtain patch info on $^O \n";
	}

	$data .= GetOutput($patchprog, "Could not get patch info");

	return "$data";
}

#######################################
# found this through google, should do the trick...
sub URL_Encode {
  my($text)  = $_[0];					# text to URL encode
  $text =~ tr/ /+/;					# replace " " with "+"
  $text =~ s/[^A-Za-z0-9\+\*\.\@\_\-]/			# replace odd chars
             uc sprintf("%%%02x",ord($&))/egx;		#   with %hex value
  return $text;						# return URL encoded text
  }

# FUTURE IDEAS
# if it's friday, send the whole report no matter what. if it's
#    another day, only alert if over the threshold
# implement log file in DelTMP()
# break this into modular files instead of one behemouth file
# make SortTime handle dates better, move it to perl_subs.pl
# combine options where the command is the same for various architectures

