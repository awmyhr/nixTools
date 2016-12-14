#!/usr/bin/python -tt
#-- NOTE: Tabs and spaces do NOT mix!! '-tt' will flag violations as an error.
#===============================================================================
#-- NOTE: default Python versions:
#--       RHEL4    2.3.4
#--       RHEL5    2.4.3
#--       RHEL6.0  2.6.5
#--       RHEL6.1+ 2.6.6
#--       REHL7    2.7.5
#-- Recent Fedora versions (24/25) stay current on 2.7 (2.7.12 as of 20161212)
#===============================================================================
"""
.. program:: template.py
   :synopsis: This is a template for single-file Python scripts

.. codeauthor:: awmyhr <awmyhr@gmail.com>

This is where a long, verbose description of the script can go, using
Sphinx-flavored reStructuredText.
"""
#===============================================================================
#-- Standard Imports
#-- NOTE: We use optparse for compatibility with python < 2.7 as (the superior)
#--       argparse wasn't standard until 2.7 (2.7 deprecates optparse)
#--       As of 20161212 the template is coded for optparse only
import optparse     # Argument parsing
import os           # Misc. OS interfaces
import sys          # System-specific parameters & functions
import traceback    # Print/retrieve a stack traceback
#===============================================================================
#-- Third Party Imports
#===============================================================================
#-- Application Library Imports
#===============================================================================
#-- Variables which are meta for the script should be dunders (__varname__)
#-- TODO: Update meta vars
__version__ = '0.1.0-alpha'
__revised__ = '2016-12-14'
__contact__ = 'awmyhr <awmyhr@gmail.com>'  # primary contact for support/?'s

#-- The following few variables should be relatively static over life of script
__author__ = 'awmyhr <awmyhr@gmail.com>'    # coder(s) of script
__created__ = '2016-12-12'                  # date script originlly created
__copyright__ = ''                          # Copyright short name
__cononical_name__ = 'template.py'          # static name, *NOT* os.path.basename(sys.argv[0])
__project_name__ = 'SysAdminTools'          # name of overall project, if needed
__project_home__ = 'N/A'                    # where to find source/documentation
__template_version__ = '0.1.0'              # version of template file used
__docformat__ = 'reStructuredText en'       # attempted style for documentation


#===============================================================================
class _ModOptionParser(optparse.OptionParser):
    """ By default format_epilog strips newlines, we don't want that. """
    def format_epilog(self, formatter):
        return self.epilog


#===============================================================================
def _usage_epilog():
    """ Builds the usage epilog string
    :return: Usage text which goes after the options
    """
    #-- TODO: UPDATE usage text.
    text = '\nShort description of script purpose/use\n\n'
    text += 'Created: {0}  Contact: {1}\n'.format(__created__, __contact__)
    text += 'Revised: {0}  Version: {1}\n'.format(__revised__, __version__)
    text += '{0}, part of {1}. Project home: {2}\n'.format(__cononical_name__,
                                                           __project_name__,
                                                           __project_home__
                                                          )
    return text


#===============================================================================
def _version():
    """ Build formatted version output
    :return: The version string.
    .. note::
        GNU guidelines dictate adding copyright/license info (see
        commented code)
    .. warning::
        HOWEVER, this may not always be desierable.
        If not, REMOVE these lines -- do NOT leave them commented!
    """
    #-- TODO: Like the OptionParser.epilog method, version strips newlines.
    #--        However, there is no format_version to override. If license
    #--        info is going to be output, this'll have to be fixed.
    text = "{0} ({1}) {2}".format(__cononical_name__, __project_name__, __version__)
    #-- TODO: UPDATE license
    #text += 'Copyright (c) 2016 awmyhr\n'
    #text +='License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>\n'
    #text +='This is free software: you are free to change and redistribute it.\n'
    #text +='There is NO WARRANTY, to the extent permitted by law.\n'
    return text


#===============================================================================
def _debug_info():
    """ Provides meta info for debug-level output
    :return: The header-text for debug-level output.
    """
    text = '{0}\n\n'.format(_version())
    text += 'Executeable: {0}\n\n'.format(os.path.abspath(sys.argv[0]))
    text += 'Created: {0}  Coder(s): {1}\n'.format(__created__, __author__)
    text += 'Revised: {0}  Version:  {1}\n'.format(__revised__, __version__)
    text += 'Based on template.sh version: {0}\n'.format(__template_version__)
    text += '{0}, part of {1}. Project home: {2}\n'.format(__cononical_name__,
                                                           __project_name__,
                                                           __project_home__
                                                          )
    text += '\n----- start -----\n'
    return text


#===============================================================================
def exit_error(error_number, error_string):
    """ Report error and exit.
    :param error_number: Number to use for Exit Code.
    :type error_number: int.
    :param error_string: Short description of error.
    :type error_string: str.
    .. warning:: This function exits the script.
    """
    if OPTIONS.debug:
        print '\n------ end ------\n'

    print '{0}: {1}'.format(__cononical_name__, error_string)
    sys.exit(error_number)


#===============================================================================
def exit_clean():
    """ Clean up everything and exit gracefully.
    .. warning:: This function exits the script.
    """
    if OPTIONS.debug:
        print '\n------ end ------\n'

    sys.exit(0)


#===============================================================================
def main():
    """ This is where the action takes place
    :return: Exit code. Should be os.EX_OK.
    """
    #-- TODO: Do something more interesting here...
    print 'Hello world!'

    return os.EX_OK
    #-- NOTE: more exit codes here:
    #--   https://docs.python.org/2/library/os.html#process-management


#===============================================================================
if __name__ == '__main__':
    try:
        PARSER = _ModOptionParser(
            version=_version(),
            epilog=_usage_epilog()
        )
        PARSER.add_option('-d', '--debug', help='enable debug mode',
                          dest='debug', action='store_true', default=False
                         )
        (OPTIONS, ARGS) = PARSER.parse_args()
        #if len(ARGS) < 1:
        #    PARSER.error ('missing argument')
        if OPTIONS.debug:
            print _debug_info()

        RETURN_VALUE = main()

        if RETURN_VALUE == os.EX_OK:
            exit_clean()
        else:
            exit_error(RETURN_VALUE, 'undefined error occured')
    #-- NOTE: "except Exception as variable:" syntax was added in 2.6
    #-- NOTE: "try..except..finally" does not work pre 2.5
    except KeyboardInterrupt, error: # Ctrl-C
        raise error
    except SystemExit, error: # sys.exit()
        raise error
    except Exception, error:
        print 'ERROR, UNEXPECTED EXCEPTION'
        print str(error)
        traceback.print_exc()
        sys.exit(1)

