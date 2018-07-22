#!/usr/bin/perl -w
#
# Program to emulate "yum install" on AIX
#
#       Date    History
# 2014-09-12    Initial dev version
#               Basic functionality
#
# Start Date:   2014-09-11
# Coder List:   awmyhr
# e-mail to:    awmyhr@gmail.com

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

use lib "$ENV{HOME}/lib";   #Library in users libs dir
use strict;                 #Turn on strict, good programing
use POSIX;                  #standard POSIX functions
use Getopt::Std;            #Parser for command line options
use File::Basename;         #Used to get name of program
use LWP::Simple;            #getprint() & getstore()

use vars qw($opt_p $opt_l $opt_h $opt_v $opt_V $opt_y $opt_q);
					#Variables: Command line options used by Getopt
my(
    $Version,           #Const: Verison
    $MostRecentCoder,   #Const: Holds name of most recent coder
    $Modified,          #Const: Date last modified
    $DEV,               #Const: Development version?
    $ProgName,          #Const: Program Name
    $Server,            #Const: Server where repo is located
    $Bundles,           #Const: URL for bundles directory
    $RPMS,              #Const: URL for RPM directory
    $OSrelease,         #Const: OS Release, in form of [567].[0-9]
    $TmpDir,            #Const: place to hold downloaded RPMs
);

#Defaults
$Server             = 'example.com';
$Bundles            = "http://$Server/aix/bundles";
$RPMS               = "http://$Server/aix/RPMS";
$OSrelease          = 'aix' . (POSIX::uname())[3] . (POSIX::uname())[2];
$TmpDir             = '/var/tmp/RPM';

#Program info
$Version            = '1.0.2';
$Modified           = '2014-09-16';
$MostRecentCoder    = 'awmyhr';
$ProgName           = basename("$0");
$DEV                = 0;

if( $DEV ) {		#Check for Development version
    print "WARNING: This is a develpment version!\n";
}

if(!getopts('p:hlvVyq')) {			#Check options and warn if errors
    print "Usage: $ProgName [options]\n";
    print "Try '$ProgName -h' for more information.\n";
    exit 1;				#Exit if incorrect options
}

if($opt_v){				#Display Version information
    print "$ProgName  --  Version: $Version  By: $MostRecentCoder\n";
    print "Date Created: 2014-09-11  Last Modified: $Modified\n";
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
    print "Current Version: $Version  Last Modified: $Modified\n";
    exit 0;
}

if($opt_l){
    getprint("${Bundles}/LIST")
        or die "ERROR: Cannot find ${Bundles}/LIST\n";
    exit 0;
}

if($opt_p){
    my @newrpms;    #List of rpms to install
    my @updrpms;    #list of rpms to update
    my @rpmlist = split /\n/, get ("${Bundles}/${opt_p}.${OSrelease}.bundle")
        or die "ERROR: Cannot find ${Bundles}/${opt_p}.${OSrelease}.bundle\n" ;
    my @rpminstalled = split /\n/, `/usr/bin/rpm -qa`
        or die "ERROR: Could not get list of installed RPMS\n";

    foreach my $rpm (@rpmlist) {
        my %rpmvh = release_to_version_hash($rpm);
        $rpmvh{'pkg'} =~ s/\+/\\\+/g;
        my @is_installed = grep(/^$rpmvh{'pkg'}-\d+/, @rpminstalled);

        if (@is_installed) {
            my %installed = release_to_version_hash($is_installed[0]);
            if (is_newer(\%rpmvh, \%installed)) {
                push (@updrpms, $rpm);
            } else {
                print "$installed{'pkg'} is current.\n" if !$opt_q;
            }
        } else {
            push (@newrpms, $rpm);
        }
    }

    mkdir $TmpDir if !(-d $TmpDir);
    if ((@updrpms) && !$opt_q) { print "Marked for upgrade: " . join("\n\t\t\t ", @updrpms)  . "\n"; }
    if ((@newrpms) && !$opt_q) { print "Marked for install: " . join("\n\t\t\t ", @newrpms) . "\n"; }

    if (@updrpms || @newrpms) {
        print "$opt_p needs to: \n";
        print "\tUpgrade " . @updrpms . " package(s)\n" if @updrpms;
        print "\tInstall " . @newrpms . " package(s)\n" if @newrpms;
        if (!$opt_y) {
            print 'Is this ok [y/N]: ';
            my $response = <>;
            if (!(lc($response) eq "y\n")) { exit 0; }
        }

        if (@updrpms) {
            foreach my $file (@updrpms) {
                getstore("$RPMS/$file", "$TmpDir/$file");
            }
        }
        if (@newrpms) {
            foreach my $file (@newrpms) {
                getstore("$RPMS/$file", "$TmpDir/$file");
            }
        }

        `rpm -Uvh $TmpDir/*`;
    } else {
        print "$opt_p all up-to-date, nothing to do.\n";
    }
    exit 0;
}

print <<END_of_text;
Usage:  $ProgName [options]
    -p <pkgname>    Install <pkgname>
    -l              List of available primary packages
    -h              Display this help and exit
    -q              Quiet(er) output
    -v              Output version info and exit
    -V              Output verbose version info and exit
    -y              Answer 'yes' to prompts

Emulates 'yum install' functionality on AIX.
Either -l or -p  should be passed. You may pass '-p ALL'
to install all available RPMs in the repo.

Report bugs to awmyhr\@gmail.com
END_of_text

exit 0;

# FUTURE IDEAS

## These two subs based on code found at:
#       http://www.ralf-lang.de/2014/07/17/perl-semantic-version-sorting-via-callback-puts-betas-before-releases-empty-string-after-text/
sub release_to_version_hash {
    my $release = shift;

    my ($package, $major, $minor, $patch, $dev) = ($release =~ /^(\w+-?\w+\+*)-(\d+)\.?(\d+\w*)-?\.?(\d+\w*)(.*)/);
    #{print "==>$package<==\n";}
    if ($dev) {
        $dev =~ s/\.aix.*rpm//;
        $dev =~ s/[-\.]//g;
    }

    if (!$major) {$major = 0;}
    if (!$minor) {$minor = 0;}
    if (!$patch) {$patch = 0;}
    if (!$dev)   {$dev   = 0;}

    my %hash = (
        major  => $major,
        minor  => $minor,
        patch  => $patch,
        dev    => $dev,
        pkg    => $package,
        url    => $release,
        string => sprintf("%s.%s.%s.%s", $major, $minor, $patch, $dev)
    );
    $release =~ s/\.aix.*rpm//;
    $hash{'release'} = $release;

    return %hash;
}

sub is_newer {
    my $a = shift;
    my $b = shift;
    if ($DEV) {
        print "$a->{pkg} <=> $b->{pkg} :: $a->{major} <=> $b->{major}\n";
        print "$a->{pkg} <=> $b->{pkg} :: $a->{minor} <=> $b->{minor}\n";
        print "$a->{pkg} <=> $b->{pkg} :: $a->{patch} <=> $b->{patch}\n";
        print "$a->{pkg} <=> $b->{pkg} :: $a->{dev}   <=> $b->{dev}\n";
        print "\n";
    }

    if ($a->{major} =~ /[a-zA-Z]/) {
        return 1 if $a->{major} gt  $b->{major};
        return 0 if $a->{major} lt  $b->{major};
    } else {
        return 1 if $a->{major}  >  $b->{major};
        return 0 if $a->{major}  <  $b->{major};
    }

    if ($a->{minor} =~ /[a-zA-Z]/) {
        return 1 if $a->{minor} gt  $b->{minor};
        return 0 if $a->{minor} lt  $b->{minor};
    } else {
        return 1 if $a->{minor}  >  $b->{minor};
        return 0 if $a->{minor}  <  $b->{minor};
    }

    if ($a->{patch} =~ /[a-zA-Z]/) {
        return 1 if $a->{patch} gt $b->{patch};
        return 0 if $a->{patch} lt $b->{patch};
    } else {
        return 1 if $a->{patch}  > $b->{patch};
        return 0 if $a->{patch}  < $b->{patch};
    }

    if ($a->{dev} =~ /[a-zA-Z]/) {
        return 1 if $a->{dev}   gt $b->{dev};
        return 0 if $a->{dev}   lt $b->{dev};
    } else {
        return 1 if $a->{dev}    > $b->{dev};
        return 0 if $a->{dev}    < $b->{dev};
    }

    return 0;
}
