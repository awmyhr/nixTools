#!/usr/local/bin/perl -w
#
# This is the client side of the System Inventory program.  This will use the
#	SysInfo.pm library to collect data about the host system, then send
#	it to the server side (a cgi program) via http POST.  Due to the fact
#	that we cannot know what's on the host systems (other then perl),
#	we cannot depend on mysql client, DBI/DBD, or even LWP, so we must us
#	old-fashioned socket programming...
#
#    Date	History
# 2004-12-28	Initial dev version
#		Basic functionality
# 2004-12-29	Initial feature complete
#		Does what needs doing...
#
# Start Date: 	2004-12-28
# Coder List: 	awmyhr
# e-mail to:	awmyhr@gmail.com

=pod

=head1 NAME

=head1 DESCRIPTION

=head1 OPTIONS

=over

=item

=back

=head1 ERRORS

=head1 FILES

=head1 RESTRICTIONS

=head1 AUTHOR

=head1 HISTORY


=cut

use lib "$ENV{HOME}/lib";		#Library in users libs dir
use lib "/usr/local/lib/perl";		#Library in local lib dir
use strict;				#Turn on strict, good programing
use Getopt::Std;			#Parser for command line options
use File::Basename;			#Used to get name of program
use IO::Socket;				#used for tcp operations
use SysInfo;				#library for getting system information

use vars qw($opt_h $opt_v $opt_V);
					#Variables: Command line options used by Getopt
my(
	$Version,			#Const: Verison
	$MostRecentCoder,		#Const: Holds name of most recent coder
	$Modified,			#Const: Date last modified
	$Dev,				#Const: Development version?
	$ProgName,			#Const: Program Name
	$URLpath,			#Const: url to post to (path part)
	$URLserver,			#const: url to post to (server part)
	$data,				#Var: data to send
	$info,				#Var: the info to send
	$return,			#Var: response from server
	$sock,				#Var: socket for connection to server
	%sysinfo,			#var: output from sysinfo call
	$key,				#var: track sysinfo keys
);

#Defaults
$URLpath = "/perl/SysInv_server.pl";
$URLserver = "test.test.com";
#Program info (mostly created by RCS)
$Version	= '1.0';
$Modified	= '2004-12-28 10:30';
$MostRecentCoder= 'awmyhr';
$ProgName	= basename("$0");
$Dev		= 0;

if( $Dev ) {		#Check for Development version
	$URLpath = "~/TestSysAdmin/perl/SysInv_server.pl";
	print "WARNING: This is a develpment version!\n";
}

if(!getopts('hvV')) {			#Check options and warn if errors
	print "Usage: $ProgName [options]\n";
	print "Try ' -h' for more information.\n";
	exit 1;				#Exit if incorrect options
}

if($opt_h){				#Display help if asked for
	print <<END_of_text;
	Usage:	$ProgName [options]
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
Date Created:   Last Modified: $Modified
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
$info = "";

#First, get the info, and ready it for sending
%sysinfo = ( get_sysinfo() );
$sysinfo{"user"} = getlogin();
foreach $key (sort keys %sysinfo) {
        $sysinfo{$key} = URL_Encode($sysinfo{$key});
	#need to url-encode
	$info .= "$key=$sysinfo{$key}\n";
}

$info =~ tr/\n/&/;

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

exit 0;

# FUTURE IDEAS
# move different sections into sub-routines
# parse results, if fail try to help (i.e., if fail due to host
#	not currently in database, ask needed info to add it...

#######################################
# found this through google, should do the trick...
sub URL_Encode {
  my($text)  = $_[0];					# text to URL encode
  $text =~ tr/ /+/;					# replace " " with "+"
  $text =~ s/[^A-Za-z0-9\+\*\.\@\_\-]/			# replace odd chars
             uc sprintf("%%%02x",ord($&))/egx;		#   with %hex value
  return $text;						# return URL encoded text
  }
