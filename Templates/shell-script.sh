#!/bin/sh
#-- NOTE: Default to POSIX shell/mode. Use some level of thought before
#--       switching to bash
#===============================================================================
## @file      shell-script.sh
## @brief     This is a template for POSIX shell scripts
## @details   Summary of script purpose/use
## @author    awmyhr <awmyhr@gmail.com>
## @copyright (If applicable)
## @par       Non-standard Requirements:
## @par       Non-standard Options:
##
#===============================================================================
## @note    For guidance, please refer to:
##          - [POSIX.1-2008 Base Specification, Issue 7](http://pubs.opengroup.org/onlinepubs/9699919799/nframe.html)
##          - [GNU Coding Standard](http://www.gnu.org/prep/standards/)
## @note    ShellCheck should be used, accepted issues should be marked w/disable comment
## @warning Option parsing is currently less-than-ideal
#===============================================================================
## @par     Settings
#===============================================================================
#-- Variables which are meta for the script should be dunders (__varname__)
#-- TODO: UPDATE meta vars
__version__='0.1.0-alpha'
__revised__='2016-12-14'
__contact__='awmyhr <awmyhr@gmail.com>'  # primary contact for support/?'s
#-- The following few variables should be relatively static over life of script
__author__='awmyhr <awmyhr@gmail.com>'   # coders(s) of script
__created__='2016-11-16'                 # date script originlly created
__copyright__=''                         # Copyright short name
__cononical_name__='shell-script.sh'     # static name, *NOT* ${0}
__project_name__='nix-Tools'             # name of overall project, if needed
__project_home__='https://github.com/awmyhr/nixTools' # where to find source/documentation
__template_version__='0.6.0'             # version of template file used
__docformat__='Doxygen'                  # attempted style for documentation

#-- The following are string formats (prepended with strfmt_)
#-- NOTE: (you can ignore ShellCheck [SC2059] errors in lines where these are used)
strfmt_error="${__cononical_name__}: %s\n"

#===============================================================================
## @par     Functions
#===============================================================================

#===============================================================================
## @fn      usage()
## @brief   Provides usage information
## @note GNU does not recommend short options for help/version.
##       I do not recommend short option for, nor display of, debug option.
##       but I do recommend short option for help.
_usage() {
    #-- TODO: UPDATE usage text.
    printf 'Usage: %s [options]\n\n' "${0}"
    printf 'Options:\n'
    printf '  -h|--help      Dislay this help\n'
    printf '  --version      Display version\n\n'
    printf 'Short description of script purpose/use\n\n'
    printf 'Created: %s  Contact: %s\n'       "${__created__}" "${__contact__}" 
    printf 'Revised: %s  Version: %s\n'  "${__revised__}" "${__version__}"
    printf '%s, part of %s. Project home: %s\n' "${__cononical_name__}" "${__project_name__}" "${__project_home__}"
}

#===============================================================================
## @fn      version()
## @brief   Provides version information
## @note GNU guidelines dictate adding copyright and license info (see commented code.)
## @warning HOWEVER, this may not always be desierable.
##          If not, REMOVE these lines -- do NOT leave them commented!
_version() {
    printf '%s (%s) %s\n' "${__cononical_name__}" "${__project_name__}" "${__version__}"
    #-- TODO: UPDATE license
    # printf 'Copyright (c) 2016 awmyhr\n'
    # printf 'License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>\n'
    # printf 'This is free software: you are free to change and redistribute it.\n'
    # printf 'There is NO WARRANTY, to the extent permitted by law.\n'
}

#===============================================================================
## @fn      debug_info()
## @brief   Provides meta info for debug-level output
## @note We set script_path here to avoid calling cd/dirname/pwd when not really needed
_debug_info() {
    # shellcheck disable=SC1007
    script_path="$(CDPATH= cd -- "$(dirname -- "${0}")" && pwd )"

    _version

    printf '\nExecuteable: %s\n\n'        "${script_path}/${0}"
    printf 'Created: %s  Coder(s): %s\n'  "${__created__}"  "${__author__}" 
    printf 'Revised: %s  Version:  %s\n'  "${__revised__}"  "${__version__}"
    printf '%s, part of %s. Project home: %s\n' "${__cononical_name__}" "${__project_name__}" "${__project_home__}"
    printf 'Based on template.sh version: %s\n' "${__template_version__}"
    printf '\n%s\n' '----- start -----'
}

#===============================================================================
## @fn      exit_error()
## @brief   Report error and exit
## @param   error_number  Number to use for Exit Code
## @param   error_string  Short description of error
## @note    You may want to use ${LINENO} in the string this is called with.
## @warning This function exits the script
exit_error() {
    # shellcheck disable=SC2059
    printf "${strfmt_error}" "${2}" 1>&2
    exit "${1}"
}

#===============================================================================
## @fn      exit_trap()
## @brief   On terminal traps, run this before exit_error
## @param   trap_line   Line number trap caught on
## @param   trap_name   Short name of trap
_exit_trap() {
    exit_error "${?}" "caught trap ${2} at line ${1}; exiting"
}

#===============================================================================
## @fn      exit_clean()
## @brief   Clean up everything and exit gracefully
exit_clean() {
    [ "${script_debug}" = true ] && {
        set +o xtrace
        script_debug=false
        printf '%s\n' '------ end ------'
    }

    trap - INT TERM HUP
    exit 0
}

#===============================================================================
## @fn      init()
## @brief   Check for requirements, other set-up stuff
_init() {
    :
}

#===============================================================================
## @par     Preperation
#===============================================================================

if [ "${*#*--debug}" != "${*}" ]; then
    _debug_info
    script_debug=true
    set -o xtrace
else
    script_debug=false
fi

#-- Some default settings
set -o errexit  # Exit if any statement returns non-true value
set -o nounset  # Exit if attempt to use an uninitialised variable

## @note    Setting traps seprately for 2 reasons:
##          -# Avoid calling "$(kill -l $((trap_num - 128)))" in exti_trap
##          -# Incase we want to handle them differently in the future
##
## @bug     Passing LINENO may not be working as expected, need more real-world tests
trap '_exit_trap ${LINENO} INT'  INT
trap '_exit_trap ${LINENO} TERM' TERM
trap '_exit_trap ${LINENO} HUP'  HUP

[ "${#}" -gt 0 ] && while :; do
    case "${1}" in
        --debug)    ;;
        -h|--help)  _usage   && exit 0 ;;
        --version)  _version && exit 0 ;;
        --)         shift && break ;;
        -?*)        exit_error 64 "invalid option: ${1}" ;;
        *)          ;;
    esac

    shift
done

_init

#===============================================================================
## @par     Main
#===============================================================================

#-- TODO: Do something more interesting here...
printf '%s\n' 'Hello world!'


#===============================================================================
## @par     Post
#===============================================================================

exit_clean
