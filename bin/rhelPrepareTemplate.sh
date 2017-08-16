#!/bin/sh
#==============================================================================
#:"""
#: .. program:: rhelPrepareTemplate.sh
#:    :synopsis: Prepare a RHEL 6/7 VM for use as a template.
#:
#:    :copyright: 2017 awmyhr
#:    :license: Apache-2.0
#:
#: .. codeauthor:: awmyhr <awmyhr@gmail.com>
#:"""
#==============================================================================
#-- Variables which are meta for the script should be dunders (__varname__)
__version__='2.4.2' #: current version
__revised__='2017-08-16' #: date of most recent revision
__contact__='awmyhr <awmyhr@gmail.com>' #: primary contact for support/?'s

#-- The following few variables should be relatively static over life of script
__author__='awmyhr <awmyhr@gmail.com>' #: coder(s) of script
__created__='2015-xx-xx'               #: date script originlly created
__copyright__='2017 awmyhr' #: Copyright short name
__license__='Apache-2.0'
__cononical_name__='rhelPrepareTemplate.sh' #: static name
__project_name__='nixTools from *NIXLand'  #: name of overall project
__project_home__='https://github.com/awmyhr/nixTools'  #: where to find src/doc
__template_version__='1.3.1'             #: version of template file used
__docformat__='reStructuredText en'      #: attempted style for documentation
__basename__="${0}" #: name script run as
__synopsis__='TODO: CHANGEME'
read -r -d '' __description__ <<EOF
TODO: CHANGEME
EOF

#-- The following are string formats (prepended with strfmt_)
#-- NOTE: (ignore ShellCheck [SC2059] errors in lines where these are used)
strfmt_error="${__cononical_name__}: %s\n"

#==============================================================================
_usage_options() {
    #:"""
    #: .. function:: _usage_options()
    #:
    #: Lists options usign format passed to it.
    #:
    #: :param str strfmt_option: The format to use.
    #:"""
    #-- TODO: UPDATE option list.
    strfmt_option="${1}"
    printf "${strfmt_option}" '--help, -h' 'Dislay this help'
    printf "${strfmt_option}" '--version ' 'Display version'
}

#==============================================================================
_usage() {
    #:"""
    #: .. function:: _usage()
    #:
    #: Provides usage information
    #:
    #: .. note::
    #:     GNU does not recommend short options for help/version.
    #:     I do not recommend short option for, nor display of, debug option.
    #:     but I do recommend short option for help.
    #:"""
    printf 'Usage: %s [options]\n\n' "${__basename__}"
    printf '%s\n\n' "${__synopsis__}"
    printf 'Options:\n'
    _usage_options '  %s     %s\n'
    printf '\n%s\n\n' "${__description__}"
    printf 'Created: %s  Contact: %s\n' "${__created__}" "${__contact__}"
    printf 'Revised: %s  Version: %s\n' "${__revised__}" "${__version__}"
    printf '%s, part of %s. Project home: %s\n' "${__cononical_name__}" \
                                                "${__project_name__}" \
                                                "${__project_home__}"
}

#==============================================================================
_usage_rest() {
    #:"""
    #: .. function:: _usage_rest()
    #:
    #: Provides usage information in Sphinx/ReST format.
    #:
    #:"""
    # 
    char="%${#__cononical_name__}s" # 
    printf "${char}\n" | tr " " "="
    printf '%s\n' "${__cononical_name__}"
    printf "${char}\n" | tr " " "="
    printf '\n'
    printf 'Synopsis\n'
    printf '%s\n\n' '--------'
    printf '**%s** [*options*]\n\n' "${__cononical_name__}"
    printf 'Description\n'
    printf '%s\n\n' '-----------'
    printf '%s\n\n' "${__description__}"
    printf 'Options\n'
    printf '%s\n\n' '-------'
    _usage_options '.. option:: %s\n\n    %s\n\n'
    printf 'Author\n'
    printf '%s\n\n' '------'
    printf '%s\n\n' "${__author__}"
}

#==============================================================================
_version() {
    #:"""
    #: .. function:: _version()
    #:
    #: Provides version information
    #:
    #: .. note::
    #:     GNU guidelines dictate adding copyright and license info
    #:     (see commented code.)
    #:
    #: .. warning::
    #:     HOWEVER, this may not always be desierable.
    #:     If not, REMOVE these lines -- do NOT leave them commented!
    #:"""
    printf '%s (%s) %s\n' "${__cononical_name__}" "${__project_name__}" "${__version__}"
    #-- TODO: UPDATE license - a boilerplate notice should go here as well
    # printf '%s\n' "${__copyright__}"
    # printf '%s\n' "${__license__}"
}

#==============================================================================
_debug_info() {
    #:"""
    #: .. function:: _debug_info()
    #:
    #: Provides meta info for debug-level output
    #:
    #: .. note::
    #:     We set script_path here to avoid calling cd/dirname/pwd when
    #:     not really needed
    #:"""
    # shellcheck disable=SC1007
    script_path="$(CDPATH= cd -- "$(dirname -- "${0}")" && pwd )"

    printf 'DEBUG    Cononical: %s\n' "${__cononical_name__}"
    printf 'DEBUG    Abs Path:  %s\n' "${script_path}/${__basename__}"
    printf 'DEBUG    Args List: %s\n' "$@"
    printf 'DEBUG    Version:   %s\n' "${__version__}"
    printf 'DEBUG    Created:   %s\n' "${__created__}"
    printf 'DEBUG    Revised:   %s\n' "${__revised__}"
    printf 'DEBUG    Coder(s):  %s\n' "${__author__}"
    printf 'DEBUG    Contact:   %s\n' "${__contact__}"
    printf 'DEBUG    Project:   %s\n' "${__project_name__}"
    printf 'DEBUG    Project Home: %s\n' "${__project_home__}"
    printf 'DEBUG    Template Version: %s\n' "${__template_version__}"
    printf 'DEBUG    System:    %s\n' "$(uname -orv)"
    printf 'DEBUG    Hostname:  %s\n' "$(hostname)"
    printf 'DEBUG    [re]uid:   %s/%s\n' "${UID}", "${EUID}"
    printf 'DEBUG    PID/PPID:  %s/%s\n' "", "${PPID}"
    printf '\n%s\n' '----- start -----'
}

#==============================================================================
exit_error() {
    #:"""
    #: .. function:: exit_error()
    #:
    #: Report error and exit
    #:
    #: :param int error_number:  Number to use for Exit Code
    #: :param str error_string:  Short description of error
    #: .. note::
    #:     You may want to use ${LINENO} in the string this is called with.
    #: .. warning::
    #:     This function exits the script
    #:"""
    # shellcheck disable=SC2059
    printf "${strfmt_error}" "${2}" 1>&2
    exit "${1}"
}

#==============================================================================
_exit_trap() {
    #:"""
    #: .. function:: exit_trap()
    #:
    #: On terminal traps, run this before exit_error
    #:
    #: :param int trap_line: Line number trap caught on
    #: :param str trap_name: Short name of trap
    #:"""
    exit_error "${?}" "caught trap ${2} at line ${1}; exiting"
}

#==============================================================================
exit_clean() {
    #:"""
    #: .. function:: exit_clean()
    #:
    #: Clean up everything and exit gracefully
    #:"""
    [ "${script_debug}" = true ] && {
        set +o xtrace
        script_debug=false
        printf '%s\n' '------ end ------'
    }

    trap - INT TERM HUP
    exit 0
}

#==============================================================================
_init() {
    #:"""
    #: .. function:: init()
    #:
    #: Check for requirements, other set-up stuff
    #:"""
    #-- TODO: 'Initilize', check for requirements, etc...
    :
}

#==============================================================================
#-- Check for debug flag & process
if [ "${*#*--debug}" != "${*}" ]; then
    _debug_info "$@"
    script_debug=true
    set -o xtrace
else
    script_debug=false
fi

#-- Some default settings
#   NOTE: we specifically do NOT want errexit in this script (rhelPrepareTemplate)
# set -o errexit  # Exit if any statement returns non-true value
set -o nounset  # Exit if attempt to use an uninitialised variable

#:"""
#: .. note::
#:     Setting traps seprately for 2 reasons:
#:
#:         - Avoid calling "$(kill -l $((trap_num - 128)))" in exti_trap
#:         - Incase we want to handle them differently in the future
#:
#: .. describe:: Bug
#:     Passing LINENO may not be working as expected, need more real-world tests
#:"""
trap '_exit_trap ${LINENO} INT'  INT
trap '_exit_trap ${LINENO} TERM' TERM
trap '_exit_trap ${LINENO} HUP'  HUP

#-- Process options (ignore --debug, as we already checked)
# 
# [ "${#}" -gt 0 ] && while :; do
while [ "${#}" -gt 0 ]; do  # 
    case "${1}" in
        --debug)     ;;
        -h|--help)   _usage   && exit 0 ;;
        --help-rest) _usage_rest   && exit 0 ;;
        --version)   _version && exit 0 ;;
        --)          shift && break ;;
        -?*)         exit_error 64 "invalid option: ${1}" ;;
        *)           ;;
    esac

    shift
done

_init

#==============================================================================
#-- Detect if this is a systemd (i.e. RHEL 7) system.
if command -v systemctl >/dev/null 2>&1 ; then
    printf '==>> %s\n' 'Detected systemd.'
    SYSTEMD=1
else
    printf '==>> %s\n' 'Did not detect systemd.'
    SYSTEMD=0
fi
#==============================================================================
#-- Steps to clean a VM template before deploying
#   NOTE: Based in part on the document "Preparing Linux Template VMs"
#         by Bob Plankers on 20130326.
#         Also, direction was taken from Red Hat documentation related to
#         sealing a VM.
#==============================================================================
printf '==>> %s\n' 'Set firstboot to run after deploy...'
if [ "${SYSTEMD}" ] ; then
    printf '==>> \t%s\n' 'Using systemctl.'
    systemctl --quiet is-enabled systemd-firstboot || systemctl enable systemd-firstboot
else
    printf '==>> \t%s\n' 'Touching /.unconfigured.'
    touch /.unconfigured
fi

printf '==>> %s\n' 'Removing yum cache files...'
yum clean all

printf '==>> %s\n' 'Removing temporary files...'
rm -rfv /tmp/*
rm -rfv /var/tmp/*

printf '==>> %s\n' 'Removing ssh keys...'
rm -fv /etc/ssh/ssh_host_*

printf '==>> %s\n' 'Removing root history & prevent creating more in current session...'
rm -fv ~root/.bash_history
unset HISTFILE

printf '==>> %s\n' 'Rotating/removing logs & prevent creating more in current session...'
if [ "${SYSTEMD}" ] ; then
    printf '==>> \t%s\n' 'Stopping rsyslog using systemctl.'
    systemctl --quiet is-active rsyslog && systemctl stop rsyslog
else
    printf '==>> \t%s\n' 'Stopping rsyslog using service.'
    service rsyslog stop
fi
printf '==>> \t%s\n' 'Rotating logs.'
logrotate -f /etc/logrotate.conf
printf '==>> \t%s\n' 'Finding and removing files.'
find /var/log -name "*-????????" -exec rm -fv {} ";"
find /var/log -name "*.gz" -exec rm -fv {} ";"

printf '==>> %s\n' 'Clearing audit files & prevent creating more in current session...'
if [ "${SYSTEMD}" ] ; then
    printf '==>> \t%s\n' 'Stopping auditd using systemctl.'
    printf '==>> \t%s\n' 'WARNING: systemctl does not currently allow stopping auditd.'
    # systemctl --quiet is-active auditd && systemctl stop auditd
else
    printf '==>> \t%s\n' 'Stopping auditd using service.'
    service auditd stop
fi
printf '==>> \t%s\n' 'Nulling files.'
cat /dev/null > /var/log/audit/audit.log
cat /dev/null > /var/log/wtmp

printf '==>> %s\n' 'Removing udev persistent rules...'
#   NOTE: I've seen both of these patterns from different RH sources
rm -fv /etc/udev/rules.d/70-*
rm -fv /etc/udev/rules.d/*-persistent-*.rules

printf '==>> %s\n' 'Removing MAC/UUID from network-scripts files...'
printf '==>> \t%s\n' 'NOTE: This script assumes DHCP was used to build template.'
#   TODO: Does this need to be done for ens devices?
for interface in /etc/sysconfig/network-scripts/ifcfg-e* ; do
    printf '==>> \t%s %s\n' 'Updating with sed hackery:' "${interface}"
    sed -ie '/^\(HWADDR\|UUID\)=/d' "${interface}"
    # NOTE: We could go down the rabbit hole of removing specific lines, but
    #       instead we'll just through the notice above and be done with it...
    # sed -ie '/^NETWORK=/d' "${interface}"
    # sed -ie '/^NETMASK=/d' "${interface}"
    # sed -ie '/^IPADDR=/d' "${interface}"
    # sed -ie '/^GATEWAY=/d' "${interface}"
done
#   TODO: I've seen reference to ifcfg-eth[x] files also located in:
#         /etc/sysconfig/networking/[devices|profiles/default]
#         however I do not have examples of these to test.

printf '==>> %s\n' 'Unregistering system...'
if [ -f '/etc/sysconfig/rhn/systemid' ] ; then
    printf '==>> \t%s\n' 'Looks like we are registered to RHN, removing systemid.'
    rm -fv /etc/sysconfig/rhn/systemid
fi

if command -v subscription-manager >/dev/null 2>&1 ; then
    printf '==>> \t%s\n' 'RHSM found, attempting to unregister.'
    subscription-manager unsubscribe --all
    subscription-manager unregister
    subscription-manager clean
fi

printf '==>> %s\n' 'Disable subscription services...'
printf '==>> \t%s\n' 'NOTE: We are going to disable all known RHN/RHSM service.'
printf '==>> \t%s\n' '      This may result in file not found errors which can be ignored.'
if [ "${SYSTEMD}" ] ; then
    printf '==>> \t%s\n' 'Using systemctl.'
    systemctl --quiet is-enabled goferd && systemctl disable goferd
    systemctl --quiet is-enabled rhsmcertd && systemctl disable rhsmcertd
    systemctl --quiet is-enabled rhnsd && systemctl disable rhnsd
else
    printf '==>> \t%s\n' 'Using chkconfig.'
    chkconfig goferd off
    chkconfig rhsmcertd off
    chkconfig rhnsd off
fi

printf '==>> %s\n' 'Resetting template hostname...'
if command -v hostnamectl >/dev/null 2>&1 ; then
    printf '==>> \t%s\n' 'Using hostnamectl.'
    hostnamectl set-hostname localhost.localdomain
else
    printf '==>> \t%s\n' 'Using sed hackery.'
    sed -ie 's/HOSTNAME=.*/HOSTNAME=localhost.localdomain/' /etc/sysconfig/network
fi

# printf '==>> %s\n' 'Cleaning /etc/hosts...'
#     printf '==>> \t%s\n' 'WARNING: cleaning /etc/hosts not currenly implemented.'
# TODO: insert code here

# printf '==>> %s\n' 'Disable networking...'
# #   NOTE: This is not necessary in all environments
# if [ "${SYSTEMD}" ] ; then
#     printf '==>> \t%s\n' 'Using systemctl.'
#     systemctl disable network
# else
#     printf '==>> \t%s\n' 'Using chkconfig.'
#     chkconfig network off
# fi

#==============================================================================
exit_clean