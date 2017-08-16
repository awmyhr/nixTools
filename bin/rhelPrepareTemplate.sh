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
__version__='2.1.0' #: current version
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
set -o errexit  # Exit if any statement returns non-true value
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
    printf '%s\n' 'Detected systemd.'
    SYSTEMD=1
else
    printf '%s\n' 'Did not detect systemd.'
    SYSTEMD=0
fi
#==============================================================================
#-- Steps to clean a VM template before deploying
#   NOTE: Based in part on the document "Preparing Linux Template VMs"
#         by Bob Plankers on 20130326.
#         Also, direction was taken from Red Hat documentation related to
#         sealing a VM.
#==============================================================================
printf '%s\n' 'Running firstboot after deploying...'
touch /.unconfigured

printf '%s\n' 'Removing yum files...'
yum clean all

printf '%s\n' 'Removing temp files from install...'
rm -rf /tmp/*
rm -rf /var/tmp/*

printf '%s\n' 'Removing ssh keys...'
rm -f /etc/ssh/ssh_host_*

printf '%s\n' 'Removing root history & do not create more in current session.'
rm -f ~root/.bash_history
unset HISTFILE

printf '%s\n' 'Rotating/removing logs & do not create more in current session...'
if [ "${SYSTEMD}" ] ; then
    printf '\t%s\n' 'Using systemctl.'
    systemctl stop rsyslog
else
    printf '\t%s\n' 'Using service.'
    service rsyslog stop
fi
logrotate -f /etc/logrotate.conf
find /var/log -name "*-????????" -exec rm -f {} ";"
find /var/log -name "*.gz" -exec rm -f {} ";"

printf '%s\n' 'Clearing audit files & do not create more in current session...'
if [ "${SYSTEMD}" ] ; then
    printf '\t%s\n' 'Using systemctl.'
    systemctl stop auditd
else
    printf '\t%s\n' 'Using service.'
    service auditd stop
fi
cat /dev/null > /var/log/audit/audit.log
cat /dev/null > /var/log/wtmp

printf '%s\n' 'Removing udev persistent rules...'
#   NOTE: I've seen both of these patterns from different RH sources
rm -f /etc/udev/rules.d/70-*
rm -f /etc/udev/rules.d/*-persistent-*.rules

printf '%s\n' 'Removing MAC/UUID from network-scripts files...'
#   TODO: Does this need to be done for ens devices?
for eth in /etc/sysconfig/network-scripts/ifcfg-e* ; do
    sed -i '/^\(HWADDR\|UUID\)=/d' "${eth}"
done

printf '%s\n' 'Renaming template...'
if [ "${SYSTEMD}" ] ; then
    printf '\t%s\n' 'Using systemctl.'
    hostnamectl set-hostname localhost.localdomain
else
    printf '\t%s\n' 'ACTION NOT YET IMPLEMENTED.'
    #-- Need sed command to replace HOSTNAME
    # NOTE: THIS IS NOT CORRECT
    # sed "/HOSTNAME=*/HOSTNAME=localhost.localdomain/s" /etc/sysocnfig/network
    :
fi

# printf '%s\n' 'Reseting /etc/hosts...'
# TODO: insert code here

printf '%s\n' 'Disable networking...'
#   NOTE: This is not necessary in all environments
if [ "${SYSTEMD}" ] ; then
    printf '\t%s\n' 'Using systemctl.'
    systemctl disable network
else
    printf '\t%s\n' 'Using chkconfig.'
    chkconfig network off
fi

#==============================================================================
exit_clean