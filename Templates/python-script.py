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
.. program:: python-script.py
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
import logging      #: Python's standard logging facilities
import optparse     #: Argument parsing
import os           #: Misc. OS interfaces
import sys          #: System-specific parameters & functions
import traceback    #: Print/retrieve a stack traceback
#===============================================================================
#-- Third Party Imports
#===============================================================================
#-- Application Library Imports
#===============================================================================
#-- Variables which are meta for the script should be dunders (__varname__)
#-- TODO: Update meta vars
__version__ = '0.1.0-alpha'
__revised__ = '2016-12-15'
__contact__ = 'awmyhr <awmyhr@gmail.com>'  #: primary contact for support/?'s

#-- The following few variables should be relatively static over life of script
__author__ = 'awmyhr <awmyhr@gmail.com>'    #: coder(s) of script
__created__ = '2016-12-12'                  #: date script originlly created
__copyright__ = ''                          #: Copyright short name
__cononical_name__ = 'python-script.py'     #: static name, *NOT* os.path.basename(sys.argv[0])
__project_name__ = 'nixTools'               #: name of overall project, if needed
__project_home__ = 'https://github.com/awmyhr/nixTools' #: where to find source/documentation
__template_version__ = '1.0.0'              #: version of template file used
__docformat__ = 'reStructuredText en'       #: attempted style for documentation


#===============================================================================
class _ModOptionParser(optparse.OptionParser):
    """ By default format_epilog() strips newlines, we don't want that. """
    def format_epilog(self, formatter):
        return self.epilog


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
    #--        info is going to be output, this'll have to be fixed. It may
    #--        be possible to override print_version()
    text = '%s (%s) %s' % (__cononical_name__, __project_name__, __version__)
    #-- NOTE: If license text is not desired, it is probably better to move
    #--       the string to the PARSER declaration and remove this function
    #-- TODO: UPDATE license
    # text += ('Copyright (c) 2016 awmyhr\n'
    #          'License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>\n'
    #          'This is free software: you are free to change and redistribute it.\n'
    #          'There is NO WARRANTY, to the extent permitted by law.\n'
    #         )
    return text


#===============================================================================
def _debug_info():
    """ Provides meta info for debug-level output
    :return: The header-text for debug-level output.
    """
    text = ('%s\n\n'
            'Executeable: %s\n\n'
            'Created: %s  Coder(s): %s\n'
            'Revised: %s  Version:  %s\n'
            'Based on template.sh version: %s\n'
            '%s, part of %s. Project home: %s\n'
            '\n----- start -----\n'
           ) % (_version(),
                os.path.abspath(sys.argv[0]),
                __created__, __author__,
                __revised__, __version__,
                __template_version__,
                __cononical_name__, __project_name__, __project_home__
               )
    return text


#===============================================================================
def exit_error(error_number, error_string):
    """ Report error and exit.
    :param int error_number: Number to use for Exit Code.
    :param str error_string: Short description of error.
    .. warning:: This function exits the script.
    """
    if OPTIONS.debug:
        print '\n------ end ------\n'

    print '%s: %s' % (os.path.basename(sys.argv[0]), error_string)
    sys.exit(error_number)


#===============================================================================
def main():
    """ This is where the action takes place
    :return: Exit code. Should be os.EX_OK.
    """
    #-- TODO: Do something more interesting here...
    logger.info('Hello world!')

    return os.EX_OK
    #-- NOTE: more exit codes here:
    #--   https://docs.python.org/2/library/os.html#process-management


#===============================================================================
if __name__ == '__main__':
    #-- Parse Options (rely on OptionsParser's exception handling)
    PARSER = _ModOptionParser(
        version=_version(),
        description='Short description of script.',
        epilog=('\nLonger explanation of script purpose &/or use.\n\n'
                'Created: %s  Contact: %s\n'
                'Revised: %s  Version: %s\n'
                '%s, part of %s. Project home: %s\n'
               ) % (__created__, __contact__,
                    __revised__, __version__,
                    __cononical_name__, __project_name__, __project_home__
                   )
    )
    PARSER.add_option('--debug', help=optparse.SUPPRESS_HELP,
                      dest='debug', action='store_true', default=False
                     )
    PARSER.add_option('--debug-file', help=optparse.SUPPRESS_HELP,
                      dest='debugfile', type='string'
                     )
    (OPTIONS, ARGS) = PARSER.parse_args()

    #-- Setup output(s)
    if OPTIONS.debug:
        LEVEL = logging.DEBUG
        FORMATTER = logging.Formatter('%(levelname)-8s %(message)s')
    else:
        LEVEL = logging.INFO
        FORMATTER = logging.Formatter('%(message)s')
    logging.basicConfig(level=LEVEL)
    logger = logging.getLogger(__name__) #: pylint: disable=invalid-name
                                         #: lower-case is better here

    #-- Console output
    CONSOLE = logging.StreamHandler()
    CONSOLE.setLevel(LEVEL)
    CONSOLE.setFormatter(FORMATTER)
    logger.addHandler(CONSOLE)

    #-- File output
    if OPTIONS.debug and OPTIONS.debugfile:
        LOGFILE = logging.FileHandler(OPTIONS.debugfile, "w", encoding=None, delay="true")
        LOGFILE.setLevel(LEVEL)
        FORMATTER = logging.Formatter('%(levelname)-8s %(message)s')
        LOGFILE.setFormatter(FORMATTER)
        logger.addHandler(LOGFILE)

    ## Start of output
    logger.debug('%s (%s) %s', __cononical_name__, __project_name__, __version__)
    logger.debug('Executeable: %s', os.path.abspath(sys.argv[0]))
    logger.debug('Created: %s  Coder(s): %s', __created__, __author__)
    logger.debug('Revised: %s  Version:  %s', __revised__, __version__)
    logger.debug('Based on template.sh version: %s', __template_version__)
    logger.debug('%s, part of %s. Project home: %s',
                 __cononical_name__, __project_name__, __project_home__)
    logger.debug('----- start -----')
    ################
    # if OPTIONS.debug:
    #     print _debug_info()

    #-- Do The Stuff
    try:
        main()
    #-- NOTE: "except Exception as variable:" syntax was added in 2.6
    #-- NOTE: "try..except..finally" does not work pre 2.5
    except KeyboardInterrupt, error: # Ctrl-C
        raise error
    except SystemExit, error: # sys.exit()
        raise error
    except Exception, error: # Known issue, will fix... eventually... pylint: disable=broad-except
        print 'ERROR, UNEXPECTED EXCEPTION'
        print str(error)
        traceback.print_exc()
        sys.exit(1)
    else:
        logger.debug('------ end ------')
        sys.exit(0)
