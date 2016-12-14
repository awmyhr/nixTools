#!/bin/sh
#-- NOTE: Default to POSIX shell/mode. Use some level of thought before
#--       switching to bash
#===============================================================================
#:"""
#: .. progrom:: shell-script.sh
#:    :synopsis: This is a template for POSIX shell scripts
#:
#: .. codeauthor:: awmyhr <awmyhr@gmail.com>
#: .. copyright:: (If applicable)
#:
#: .. note:: 
#:     For guidance, please refer to:
#:
#:      - [POSIX.1-2008 Base Specification, Issue 7](http://pubs.opengroup.org/onlinepubs/9699919799/nframe.html)
#:      - [GNU Coding Standard](http://www.gnu.org/prep/standards/)
#:
#: .. note::
#:     ShellCheck should be used, accepted issues should be marked w/disable comment
#:
#: .. warning::
#:     Option parsing is currently less-than-ideal
#:
#: This is where a long, verbose description of the script can go, using
#: Sphinx-flavored reStructuredText.
#:"""
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
__docformat__='reStructuredText en'      # attempted style for documentation

#-- The following are string formats (prepended with strfmt_)
#-- NOTE: (you can ignore ShellCheck [SC2059] errors in lines where these are used)
strfmt_error="${__cononical_name__}: %s\n"

#===============================================================================
_usage() {
    #"""
    #: .. function:: _usage()
    #:
    #: Provides usage information
    #:
    #: .. note::
    #:     GNU does not recommend short options for help/version.
    #:     I do not recommend short option for, nor display of, debug option.
    #:     but I do recommend short option for help.
    #:"""
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
_version() {
    #:"""
    #: .. function:: _version()
    #:
    #: Provides version information
    #:
    #: .. note::
    #:     GNU guidelines dictate adding copyright and license info
    #:     (see commented code.)
    #: .. warning::
    #:     HOWEVER, this may not always be desierable.
    #:     If not, REMOVE these lines -- do NOT leave them commented!
    #:"""
    printf '%s (%s) %s\n' "${__cononical_name__}" "${__project_name__}" "${__version__}"
    #-- TODO: UPDATE license
    # printf 'Copyright (c) 2016 awmyhr\n'
    # printf 'License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>\n'
    # printf 'This is free software: you are free to change and redistribute it.\n'
    # printf 'There is NO WARRANTY, to the extent permitted by law.\n'
}

#===============================================================================
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

    _version

    printf '\nExecuteable: %s\n\n'        "${script_path}/${0}"
    printf 'Created: %s  Coder(s): %s\n'  "${__created__}"  "${__author__}" 
    printf 'Revised: %s  Version:  %s\n'  "${__revised__}"  "${__version__}"
    printf '%s, part of %s. Project home: %s\n' "${__cononical_name__}" "${__project_name__}" "${__project_home__}"
    printf 'Based on template.sh version: %s\n' "${__template_version__}"
    printf '\n%s\n' '----- start -----'
}

#===============================================================================
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

#===============================================================================
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

#===============================================================================
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

#===============================================================================
_init() {
    #:"""
    #: .. function:: init()
    #:
    #: Check for requirements, other set-up stuff
    #:"""
    #-- TODO: 'Initilize', check for requirements, etc...
    :
}

#===============================================================================
#-- Check for debug flag & process
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

#:"""
#: .. note::
#:     Setting traps seprately for 2 reasons:
#:
#:      - Avoid calling "$(kill -l $((trap_num - 128)))" in exti_trap
#:      - Incase we want to handle them differently in the future
#:
#: .. describe:: Bug
#:     Passing LINENO may not be working as expected, need more real-world tests
#:"""
trap '_exit_trap ${LINENO} INT'  INT
trap '_exit_trap ${LINENO} TERM' TERM
trap '_exit_trap ${LINENO} HUP'  HUP

#-- Process options (ignore --debug, as we already checked)
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
#-- TODO: Do something more interesting here...
printf '%s\n' 'Hello world!'

#===============================================================================
exit_clean
