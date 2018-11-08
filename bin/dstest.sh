#!/bin/sh
#-- NOTE: Default to POSIX shell/mode. Be mindful of your reasons before
#--       switching to Bash, and consider using Python instead...
#==============================================================================
#:"""
#: .. program:: dstest.sh
#:    :synopsis: TODO: CHANGEME
#:
#:    :copyright: 2016 awmyhr
#:    :license: Apache-2.0
#:
#: .. codeauthor:: awmyhr <awmyhr@gmail.com>
#:
#: .. note:
#:     For guidance, please refer to:
#:
#:         - 'POSIX.1-2008 Base Specification, Issue 7 <http://pubs.opengroup.org/onlinepubs/9699919799/nframe.html>'_
#:         - 'GNU Coding Standard <http://www.gnu.org/prep/standards/>'_
#:
#: .. note:
#:     ShellCheck should be used, accepted issues should be marked w/disable comment
#:
#: .. warning:
#:     Option parsing is currently less-than-ideal
#:
#: TODO: CHANGEME- description for documentation
#:"""
#==============================================================================
#-- Variables which are meta for the script should be dunders (__varname__)
#-- TODO: UPDATE meta vars
__version__='0.1.0-alpha' #: current version
__revised__='20181108-123420' #: date of most recent revision
__contact__='awmyhr <awmyhr@gmail.com>' #: primary contact for support/?'s
__synopsis__='TODO: CHANGEME'
__description__="
TODO: CHANGEME - description for --help
"
#------------------------------------------------------------------------------
#-- TODO: If you want to hard-set some variables, do it here. For example:
# LOGGER_FILE="${HOME}/var/log/dstest.sh.$(date +%Y%m%d-%H%M%S).log"
#------------------------------------------------------------------------------
#-- Flags
__require_root__='false'    #: Does script require root
__container_safe__='false'  #: Are we safe to run inside a Docker container?
__gnu_version__='false'     #: If true print GNU version string (which includes copyright/license)
#==============================================================================
#-- The following few variables should be relatively static over life of script
__author__='awmyhr <awmyhr@gmail.com>' #: coder(s) of script
__created__='2018-11-08'               #: date script originlly created
__copyright__='2016 awmyhr' #: Copyright short name
__license__='Apache-2.0'
__cononical_name__='dstest.sh' #: static name, *NOT* os.path.basename(sys.argv[0])
__project_name__='nixTools from *NIXLand'  #: name of overall project, if needed
__project_home__='https://github.com/awmyhr/nixTools'  #: where to find source/documentation
__template_version__='2.8.1'  #: version of template file used
#-- We are not using this variable for now.
# shellcheck disable=2034
__docformat__='reStructuredText en'  #: attempted style for documentation
__basename__="${0}"  #: name script run as
#------------------------------------------------------------------------------
#-- Load in environment variables, or set defaults
__default_dsf__=${DEFAULT_TIMESTAMP:="+%Y%m%d-%H%M%S"} #: Default format for 'date' command
__logger_dsf__=${LOGGER_DSF:="+%Y%m%d-%H%M%S"}         #: Debug logging output format for 'date' command
__backup_dsf__=${BACKUP_DSF:="+%Y%m%d-%H%M%S"}         #: Backup file format for 'date' command
__logger_file__=${LOGGER_FILE:="nil"}                  #: Path & name of log file to use
case "$(printf '%s' "${LOGGER_LVL:="info"}" | tr '[:upper:]' '[:lower:]')" in
    debug)          __logger_lvl__=10 ;;
    info)           __logger_lvl__=20 ;;
    warn|warning)   __logger_lvl__=30 ;;
    error)          __logger_lvl__=40 ;;
    crit|critical)  __logger_lvl__=50 ;;
    *)              __logger_lvl__=0 ;;
esac
#------------------------------------------------------------------------------
#-- Load colors from environment variables, or set to empty
cf_black=${cf_black:=''}   ; cf_white=${cf_white:=''}
cf_orange=${cf_orange:=''} ; cf_magenta=${cf_magenta:=''}
cf_yellow=${cf_yellow:=''} ; cf_red=${cf_red:=''}
cf_purple=${cf_purple:=''} ; cf_blue=${cf_blue:=''}
cf_cyan=${cf_cyan:=''}     ; cf_green=${cf_green:=''}
c_bold=${c_bold:=''}       ; c_reset=${c_reset:=''}
c_undr=${c_undr:=''}       ; c_hide=${c_hide:=''}
c_blik=${c_blik:=''}       ; c_revr=${c_revr:=''}
#------------------------------------------------------------------------------
#-- Set some default settings
#-- NOTE: If you don't want to handle these error conditions yourself,
#         then uncomment these.
# set -o errexit  # Exit if any statement returns non-true value
# set -o nounset  # Exit if attempt to use an uninitialised variable
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
    usage_options '  %s     %s\n'
    printf '\n%s\n\n' "${__description__}"
    printf 'Created: %s  Contact: %s\n' "${__created__}" "${__contact__}"
    printf 'Revised: %s  Version: %s\n' "${__revised__}" "${__version__}"
    printf '(c) Copyright %s (License: %s)\n'   "${__copyright__}" "${__license__}"
    printf '%s, part of %s. Project home: %s\n' "${__cononical_name__}" \
                                                "${__project_name__}" \
                                                "${__project_home__}"

    return
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
    __usage_rest_char="%${#__cononical_name__}s" #
    #-- We are using a variable to format data in printf
    # shellcheck disable=2059
    printf "${__usage_rest_char}\\n" | tr " " "="
    printf '%s\n' "${__cononical_name__}"
    #-- We are using a variable to format data in printf
    # shellcheck disable=2059
    printf "${__usage_rest_char}\\n" | tr " " "="
    printf '\n'
    printf 'Synopsis\n'
    printf '%s\n\n' '--------'
    printf '**%s** [*options*]\n\n' "${__cononical_name__}" #: TODO: UPDATE usage
    printf 'Description\n'
    printf '%s\n\n' '-----------'
    printf '%s\n\n' "${__description__}"
    printf 'Options\n'
    printf '%s\n\n' '-------'
    usage_options '.. option:: %s\n\n    %s\n\n'
    printf 'Author\n'
    printf '%s\n\n' '------'
    printf '%s\n\n' "${__author__}"
    printf 'Copyright\n'
    printf '%s\n\n' '------'
    printf '(c) Copyright %s (License: %s)\n\n' "${__copyright__}" "${__license__}"

    return
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
    #:"""
    printf '%s (%s) %s\n' "${__cononical_name__}" "${__project_name__}" "${__version__}"
    if [ "${__gnu_version__}" = 'true' ]; then
        printf 'Copyright %s\n' "${__copyright__}"
        printf 'License %s\n' "${__license__}"
    fi

    return
}

#==============================================================================
_debug_info() {
    #:"""
    #: .. function:: _debug_info()
    #:
    #: Provides meta info for debug-level output
    #:
    #: .. note::
    #:     We set script_path here to avoid calling cd/dirname/pwd when not really needed
    #:"""
    # shellcheck disable=SC1007
    script_path="$(CDPATH= cd -- "$(dirname -- "${0}")" && pwd )"

    logger debug "Cononical: ${__cononical_name__}"
    logger debug "Abs Path:  ${script_path}/${__basename__}"
    logger debug "Args List: ${*}"
    logger debug "Version:   ${__version__}"
    logger debug "md5sum:    $(md5sum "${__basename__}")"
    logger debug "Created:   ${__created__}"
    logger debug "Revised:   ${__revised__}"
    logger debug "Coder(s):  ${__author__}"
    logger debug "Contact:   ${__contact__}"
    logger debug "Project:   ${__project_name__}"
    logger debug "Project Home: ${__project_home__}"
    logger debug "Template Version: ${__template_version__}"
    logger debug "System:    $(uname -orv)"
    logger debug "Hostname:  $(hostname)"
    logger debug "Logname:   $(logname)"
    logger debug "[re]uid:   $(id -ur)/$(id -u)"
    logger debug "PID/PPID:  ${$}/${PPID}"
    logger debug '-----------------'
    logger debug '----- start -----'
    logger debug '-----------------'

    return
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
    #: .. warning::
    #:     This function calls exit_error, which exits the script
    #:"""
    exit_error "${?}" "caught trap ${2} at line ${1}; exiting"
}

#==============================================================================
logger() {
    #:"""
    #: .. function:: logger()
    #:
    #: Provides an interface similar to Python's logging module
    #:
    #: :param str log_level:     String indicating log level
    #: :param str log_string:    String to print
    #: .. note::
    #:     This was inspired by tinylogger (Copyright (c) 2017 Nagarjuna
    #:     Kumarappan), but I think there is very little left of the original
    #:     code here. See: https://github.com/nk412/tinylogger
    #:"""
    case "$(printf '%s' "${1}")" in
        debug)          __logger_action_tag='DEBUG'    ; __logger_log_level_th=10 ;;
        info)           __logger_action_tag='INFO'     ; __logger_log_level_th=20 ;;
        warn|warning)   __logger_action_tag='WARNING'  ; __logger_log_level_th=30 ;;
        error)          __logger_action_tag='ERROR'    ; __logger_log_level_th=40 ;;
        crit|critical)  __logger_action_tag='CRITICAL' ; __logger_log_level_th=50 ;;
        *)              __logger_action_tag='UNKNOWN'  ; __logger_log_level_th=0 ;;
    esac
    shift

    if [ "${__logger_file_set__}" = "true" ]; then
        printf '%s [%s]: %s\n' "$(timestamp "${__logger_dsf__}")" \
                               "${__logger_action_tag}" "${@}" 1>&3
    fi

    if [ "${__logger_lvl__}" -le "${__logger_log_level_th}" ]; then
        if [ "${__script_debug__}" = true ]; then
            printf '%s %-10s ' "${cf_blue}$(timestamp "${__logger_dsf__}")" \
                               "${__logger_action_tag}${c_reset}"
        fi
        if [ "${__logger_log_level_th}" -le 10 ]; then
            printf '%sdebug: %s%s\n' "${cf_green}" "${@}" "${c_reset}"
        elif [ "${__logger_log_level_th}" -le 20 ]; then
            printf '%s%s%s\n' "${cf_white}" "${@}" "${c_reset}"
        elif [ "${__logger_log_level_th}" -le 30 ]; then
            printf '%sWarning: %s%s\n' "${cf_yellow}" "${@}" "${c_reset}" 1>&2
        elif [ "${__logger_log_level_th}" -le 40 ]; then
            printf '%sError: %s%s\n' "${cf_magenta}" "${@}" ""${c_reset} 1>&2
        else
            printf '%sCRITICAL: %s%s\n' "${cf_red}" "${@}" "${c_reset}" 1>&2
        fi
    fi

    return
}

#==============================================================================
timestamp() {
    #:"""
    #: .. function:: timestamp()
    #:
    #: Return date in specified format
    #:
    #: :param str datestamp_format:  Format string for 'date' command
    #:"""#
    if [ "${#}" -eq 0 ]; then #
        date "${__default_dsf__}"
    else
        date "${1}"
    fi

    return
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
    printf '%s: %s\n' "${cf_red}${__cononical_name__}" \
                      "${c_bold}${2}${c_reset}" 1>&2
    if [ "${__logger_file_set__}" = "true" ]; then
        printf '%s [EXIT]: %s\n' "$(timestamp "${__logger_dsf__}")" "${2}" 1>&3
        printf 'Log file created: %s\n' "${__logger_file__}"
        exec 3>&-
    fi
    exit "${1}"
}

#==============================================================================
exit_clean() {
    #:"""
    #: .. function:: exit_clean()
    #:
    #: Clean up everything and exit gracefully
    #: .. warning::
    #:     This function exits the script
    #:"""
    [ "${__script_debug__}" = true ] && {
        set +o xtrace
        logger debug '-----------------'
        logger debug '------ end ------'
        logger debug '-----------------'
        __script_debug__=false
    }

    trap - INT TERM HUP
    if [ "${__logger_file_set__}" = "true" ]; then
        printf '%s [EXIT]: Script finished.\n' "$(timestamp "${__logger_dsf__}")" 1>&3
        printf 'Log file created: %s\n' "${__logger_file__}"
        exec 3>&-
    fi
    exit 0
}

#==============================================================================
get_temp() {
    #:"""
    #: .. function:: get_temp_dir()
    #:
    #: Creates a temporary file (or directory), returning the path. Defaults to file.
    #:
    #: :param str directory:   Pass any substring of 'directory' to create a directory
    #:"""
    #
    if [ "${#}" -eq 1 ] && is_in_string "${1}" "directory"; then  #
        __get_temp_dir='-d'
    else
        __get_temp_dir=''
    fi
    if command -v mktemp >/dev/null 2>&1; then
        mktemp ${__get_temp_dir} -t "${__cononical_name__}${__get_temp_dir}.XXXXXXXXXX" || return "${?}"
    else
        if [ "${__get_temp_dir}" = '' ]; then
            __get_temp_path="/tmp/${__cononical_name__}.${$}"
            touch "${__get_temp_path}" || return "${?}"
        else
            __get_temp_path="/tmp/${__cononical_name__}-d.${$}"
            mkdir "${__get_temp_path}" || return "${?}"
        fi
        printf '%s' "${__get_temp_path}"
    fi

    return
}

#==============================================================================
is_in_string() {
    #:"""
    #: .. function:: is_in_string()
    #:
    #: Check if a substring is in a string
    #:
    #: :param str needle:   Substring to search for
    #: :param str heystack: String to search in
    #:"""
    case "${2}" in
        *${1}*) return 0 ;;
        *)      return 1 ;;
    esac ;
}

#==============================================================================
set_value() {
    #:"""
    #: .. function:: set_value()
    #:
    #: Add or change a KEY to a VALUE in a FILE, creating FILE if necessary.
    #:
    #: :param str file:   File to create/modify
    #: :param str key:    Key to create/modify
    #: :param str value:  Value to set key to
    #:"""
    __set_value_file="${1}"
    __set_value_key="${2}"
    __set_value_value="${3}"
    if [ ! -e "${__set_value_file}" ]; then touch "${__set_value_file}" || return "${?}"; fi
    if grep -q "^${__set_value_key}=" "${__set_value_file}"; then
        sed -i "s/^${__set_value_key}=.*/${__set_value_key}='${__set_value_value}'/" "${__set_value_file}" || return "${?}"
    else
        printf '%s=%s\n' "${__set_value_key}" "'${__set_value_value}'" >> "${__set_value_file}" || return "${?}"
    fi

    return
}

#==============================================================================
identify_platform() {
    #:"""
    #: .. function:: identify_platform()
    #:
    #: Identify underlining 'hardware' platform and return tag.
    #:"""
    if [ -f '/sys/devices/virtual/dmi/id/sys_vendor' ] ; then
        __identify_platform_sys_vendor="$(cat /sys/devices/virtual/dmi/id/sys_vendor)"
        case "${__identify_platform_sys_vendor}" in
            'Microsoft Corporation') printf 'azure' ;;
            'VMware, Inc.')          printf 'vmware' ;;
            'innotek GmbH')          printf 'vbox' ;;
            *)                       printf 'other' ;;
        esac
    else
        printf 'unknown'
    fi

    return
}

#==============================================================================
init() {
    #:"""
    #: .. function:: init()
    #:
    #: Check for requirements, other set-up stuff
    #:"""
    #--------------------------------------------------------------------------
    #-- Check if effectively root
    #--------------------------------------------------------------------------
    if [ "${__require_root__}" = "true" ] && [ "$(id -u)" -ne 0 ] ; then
      exit_error 77 'Must be run as root.'
    fi
    #--------------------------------------------------------------------------
    #-- Check if running inside Docker container
    #--------------------------------------------------------------------------
    if [ "${__container_safe__}" = "false" ] && grep -q '/docker' /proc/self/cgroup ; then
      exit_error 78 'This script is not container safe.'
    fi
    #--------------------------------------------------------------------------
    return
}

#==============================================================================
usage_options() {
    #:"""
    #: .. function:: usage_options()
    #:
    #: Lists options usign format passed to it.
    #:
    #: :param str option_strfmt: The format to use.
    #:"""
    #-- TODO: UPDATE option list.
    __usage_option_strfmt="${1}"
    #-- We are using a variable to format data in printf
    # shellcheck disable=2059
    printf "${__usage_option_strfmt}" '--help, -h' 'Dislay this help'
    #-- We are using a variable to format data in printf
    # shellcheck disable=2059
    printf "${__usage_option_strfmt}" '--version ' 'Display version'

    return
}

#==============================================================================
#-- Set up log file
if [ "${__logger_file__}" != "nil" ]; then
    mkdir -p "$(dirname "${__logger_file__}")"
    if [ -f "${__logger_file__}" ] ; then
        mv "${__logger_file__}" "${__logger_file__}"."$(timestamp "${__backup_dsf__}")"
    fi
    exec 3<> "${__logger_file__}" || exit 1
    __logger_file_set__='true'
else
    exec 3>&1 || exit 1
    __logger_file_set__='false'
fi
#-- Check for debug flag & process
if [ "${*#*--debug}" != "${*}" ]; then
    __script_debug__='true'
    __logger_lvl__=10
    #-- Only do full shell trace if external DEBUG var set to full
    [ "${DEBUG}" = 'full' ] && set -o xtrace
else
    __script_debug__='false'
fi
_debug_info "$@"

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
#   NOTE: this is not optimal, but is an attempt to keep things POSIX
#         compliant. If you are expecting arguments instead of params,
#         be sure to assign them... somehow...
#   Be sure to update usage_options() as well
#
# [ "${#}" -gt 0 ] && while :; do
while [ "${#}" -gt 0 ]; do  #
    case "${1}" in
        --debug)     ;;
        -h|--help)   _usage   && exit 0 ;;
        --help-rest) _usage_rest   && exit 0 ;;
        --version)   _version && exit 0 ;;
        # --)          shift && break ;;
        # -?*)         exit_error 64 "Invalid option: ${1}" ;;
        *)           exit_error 64 "Invalid option: ${1}" ;;
    esac

    shift
done

init

#==============================================================================
#-- Loop through some simple dd tests
DD_BYTES=1
DD_COUNT=0
TEMP_FILE='.tempfile'

while [ ${DD_BYTES} -le 8192 ] ; do
    DD_COUNT=$(( 250000 / $DD_BYTES ))
    sync
    printf 'Block size: %4sK ; Block count: %s\n' "${DD_BYTES}" "${DD_COUNT}"
    printf '    Write: '
    dd  bs="${DD_BYTES}"K count="${DD_COUNT}" if=/dev/zero \
        of="${TEMP_FILE}" oflag=direct 2>&1 | grep copied
    sync
    # sysctl -w vm.drop_caches=3 1>/dev/null 2>&1

    printf '    Read:  '
    dd  bs="${DD_BYTES}"K of=/dev/null \
        if="${TEMP_FILE}" iflag=direct 2>&1 | grep copied

    DD_BYTES=$(( $DD_BYTES * 2 ))
done

if [ -f "${TEMP_FILE}" ] ; then
    rm -f "${TEMP_FILE}"
fi
#==============================================================================
exit_clean
