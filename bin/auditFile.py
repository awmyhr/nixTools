#!/usr/bin/python -tt
# -*- coding: utf-8 -*-
# ^^-- use utf-8 strings by default
#-- NOTE: Tabs and spaces do NOT mix!! '-tt' will flag violations as an error.
#===============================================================================
"""
    :program:`auditFile.py`
    ============================================================

    In addition to the options listed in help output, :program:`auditFile.py` includes
    the following 'hidden' optoins:

    .. option:: --help-rest

        Output usage information in Sphinx/reST-style markup.

    .. option:: --debug

        Output debug-level information.

    .. option:: --debug-file <FILE>

        Save debug-level information to specified file.

        .. note:: This output is more detailed, but less readable, than simple --debug

    :synopsis: TODO: CHANGEME

    :copyright: 2016 awmyhr
    :license: Apache-2.0

    .. codeauthor:: awmyhr <awmyhr@gmail.com>
"""
#===============================================================================
from __future__ import (absolute_import, division, print_function)
__metaclass__ = type
#-- Standard Imports
#-- NOTE: We use optparse for compatibility with python < 2.7 as (the superior)
#--       argparse wasn't standard until 2.7 (2.7 deprecates optparse)
#--       As of 20161212 the template is coded for optparse only
import optparse     #: Argument parsing
import os           #: Misc. OS interfaces
import sys          #: System-specific parameters & functions
import json
from collections import namedtuple
# import traceback    #: Print/retrieve a stack traceback
#==============================================================================
#-- Third Party Imports
from ansible.executor.task_queue_manager import TaskQueueManager
from ansible.parsing.dataloader import DataLoader
from ansible.playbook.play import Play
from ansible.plugins.callback import CallbackBase
# from ansible.vars.manager import VariableManager
# from ansible.inventory.manager import InventoryManager
#-- NOTE: The above are for Ansible 2.4; 2.3 uses these two instead
from ansible.inventory import Inventory
from ansible.vars import VariableManager
#-- These are for mimicking ansible cmd execution
from ansible import constants as C
from ansible.cli import CLI
from ansible.errors import AnsibleError, AnsibleOptionsError, AnsibleParserError
from ansible.module_utils._text import to_text
from ansible.utils.display import Display
#==============================================================================
#-- Require a minimum Python version
if sys.version_info <= (2, 6):
    sys.exit("Minimum Python version: 2.6")
#-- NOTE: default Python versions:
#--       RHEL4    2.3.4
#--       RHEL5    2.4.3
#--       RHEL6.0  2.6.5
#--       RHEL6.1+ 2.6.6
#--       REHL7    2.7.5
#-- Recent Fedora versions (24/25) stay current on 2.7 (2.7.12 as of 20161212)
#==============================================================================
#==============================================================================
#-- Application Library Imports
#==============================================================================
#-- Variables which are meta for the script should be dunders (__varname__)
#-- TODO: Update meta vars
__version__ = '0.1.0-alpha' #: current version
__revised__ = '20190419-094856' #: date of most recent revision
__contact__ = 'awmyhr <awmyhr@gmail.com>' #: primary contact for support/?'s

#-- The following few variables should be relatively static over life of script
__author__ = ['awmyhr <awmyhr@gmail.com>'] #: coder(s) of script
__created__ = '2017-10-25'               #: date script originlly created
__copyright__ = '2016 awmyhr' #: Copyright short name
__license__ = 'Apache-2.0'
__cononical_name__ = 'auditFile.py' #: static name, *NOT* os.path.basename(sys.argv[0])
__project_name__ = 'nixTools from *NIXLand'  #: name of overall project, if needed
__project_home__ = 'https://github.com/awmyhr/nixTools'  #: where to find source/documentation
__template_version__ = '1.8.1'              #: version of template file used
__docformat__ = 'reStructuredText en'       #: attempted style for documentation
__basename__ = os.path.basename(sys.argv[0]) #: name script run as
__synopsis__ = 'TODO: CHANGEME'
__description__ = """TODO: CHANGEME
"""

EXIT_STATUS = None


#==============================================================================
class _ModOptionParser(optparse.OptionParser):
    """By default format_epilog() strips newlines, we don't want that, os override."""

    def format_epilog(self, formatter):
        """We'll preformat the epilog in the decleration, just pass it through"""
        return self.epilog


#==============================================================================
class _ReSTHelpFormatter(optparse.HelpFormatter):
    """Format help for Sphinx/ReST output.

    All over-ridden methods started life as copy'n'paste from original's source
    code.
    """

    def __init__(self, indent_increment=0, max_help_position=4, width=80, short_first=0):
        optparse.HelpFormatter.__init__(self, indent_increment,
                                        max_help_position, width, short_first
                                       )

    def format_usage(self, usage):
        retval = ["%s\n" % ("=-"[self.level] * len(__cononical_name__))]
        retval.append("%s\n" % (__cononical_name__))
        retval.append("%s\n\n" % ("=-"[self.level] * len(__cononical_name__)))
        retval.append("%s" % self.format_heading('Synopsis'))
        retval.append("**%s** %s\n\n" % (__cononical_name__, usage))
        return ''.join(retval)

    def format_heading(self, heading):
        return "%s\n%s\n\n" % (heading, "--"[self.level] * len(heading))

    def format_description(self, description):
        if description:
            retval = ["%s" % self.format_heading('Description')]
            retval.append("%s\n" % self._format_text(description))
            return ''.join(retval)
        else:
            return ""

    def format_option(self, option):
        opts = self.option_strings[option]
        retval = ['.. option:: %s\n\n' % opts]
        if option.help:
            # help_text = self.expand_default(option)
            # help_lines = textwrap.wrap(help_text, self.help_width)
            retval.append("%4s%s\n\n" % ("", self.expand_default(option)))
            # retval.extend(["%4s%s\n" % ("", line)
            #                for line in help_lines[1:]])
        elif opts[-1] != "\n":
            retval.append("\n")
        return "".join(retval)

    def format_option_strings(self, option):
        """Return a comma-separated list of option strings & metavariables."""
        if option.takes_value():
            metavar = option.metavar or option.dest.upper()
            short_opts = ["%s <%s>" % (sopt, metavar)
                          for sopt in option._short_opts] #: pylint: disable=protected-access
                                                          #: We're over-riding the default
                                                          #:    method, keeping most the code.
                                                          #:    Not sure how else we'd do this.
            long_opts = ["%s=<%s>" % (lopt, metavar)
                         for lopt in option._long_opts]   #: pylint: disable=protected-access
        else:
            short_opts = option._short_opts               #: pylint: disable=protected-access
            long_opts = option._long_opts                 #: pylint: disable=protected-access

        if self.short_first:
            opts = short_opts + long_opts
        else:
            opts = long_opts + short_opts

        return ", ".join(opts)


#==============================================================================
def _version():
    """Build formatted version output

    Returns:
        The version string.
    """
    return '%s (%s) %s' % (__cononical_name__, __project_name__, __version__)


#==============================================================================
def _debug_info():
    """ Provides meta info for debug-level output """
    import platform #: Easily get platforms identifying info
    logger.debug('Cononical: %s' % __cononical_name__)
    logger.debug('Abs Path:  %s' % os.path.abspath(sys.argv[0]))
    logger.debug('Full Args: %s' % ' '.join(sys.argv[:]))
    logger.debug('Python:    %s (%s)' % (sys.executable, platform.python_version()))
    logger.debug('Version:   %s' % __version__)
    logger.debug('Created:   %s' % __created__)
    logger.debug('Revised:   %s' % __revised__)
    logger.debug('Coder(s):  %s' % __author__)
    logger.debug('Contact:   %s' % __contact__)
    logger.debug('Project:   %s' % __project_name__)
    logger.debug('Project Home: %s' % __project_home__)
    logger.debug('Template Version: %s' % __template_version__)
    logger.debug('System:    %s' %
                 to_text(platform.system_alias(platform.system(),
                                               platform.release(),
                                               platform.version()
                                              )
                        ))
    if platform.system() in 'Linux':
        logger.debug('Distro:    %s' % to_text(platform.linux_distribution()))
    logger.debug('Hostname:  %s' % platform.node())
    logger.debug('[res]uid:  %s' % to_text(os.getresuid()))
    logger.debug('PID/PPID:  %s/%s' % (os.getpid(), os.getppid()))

    # TODO: We should really output some Ansible stuff here, will look into it...
    logger.debug('Inventory: %s' % C.DEFAULT_HOST_LIST)

#==============================================================================
def main():
    """ This is where the action takes place """
    logger.debug('Starting main()')
    #-- TODO: Do something more interesting here...


#==============================================================================
if __name__ == '__main__':
    #-- Parse Options (rely on OptionsParser's exception handling)
    PARSER = CLI.base_parser(
        # version='%s (%s) %s' % (__cononical_name__, __project_name__, __version__),
        usage='%s <host-pattern> [options] <filename>' % (__basename__),
        # description=__synopsis__,
        epilog=('\n%s\n\n'
                'Created: %s  Contact: %s\n'
                'Revised: %s  Version: %s\n'
                '%s, part of %s. Project home: %s\n'
               ) % (__description__,
                    __created__, __contact__,
                    __revised__, __version__,
                    __cononical_name__, __project_name__, __project_home__
                   ),
        runas_opts=True,
        inventory_opts=True,
        async_opts=True,
        output_opts=True,
        connect_opts=True,
        check_opts=True,
        runtask_opts=True,
        vault_opts=True,
        fork_opts=True,
        module_opts=True,
    )
    PARSER.conflict_handler = 'resolve'
    PARSER.add_option('--version', dest='version', action='store_true',
                      help=optparse.SUPPRESS_HELP, default=False
                     )
    #-- 'Hidden' optoins
    PARSER.add_option('--help-rest', dest='helprest', action='store_true',
                      help=optparse.SUPPRESS_HELP, default=False
                     )
    PARSER.add_option('--debug', dest='debug', action='store_true',
                      help=optparse.SUPPRESS_HELP, default=False
                     )
    PARSER.add_option('--debug-file', dest='debugfile', type='string',
                      help=optparse.SUPPRESS_HELP
                     )
    (OPTIONS, ARGS) = PARSER.parse_args()
    if OPTIONS.helprest:
        PARSER.formatter = _ReSTHelpFormatter()
        PARSER.usage = '[*options*]'            #: pylint: disable=attribute-defined-outside-init
                                                #: Not yet sure of a better way to do this...
        PARSER.description = __description__    #: pylint: disable=attribute-defined-outside-init
        PARSER.epilog = ('\nAuthor\n------\n\n'
                         '%s\n'
                        ) % ('; '.join(__author__))
        PARSER.print_help()
        sys.exit(os.EX_OK)
    elif OPTIONS.version:
        print(_version())
        sys.exit(os.EX_OK)

    #-- Setup output(s)
    # if OPTIONS.debug:
    #     LEVEL = logging.DEBUG
    #     FORMATTER = logging.Formatter('%(asctime)s %(levelname)-8s %(message)s',
    #                                   '%Y%m%d-%H%M'
    #                                  )
    # else:
    #     LEVEL = logging.INFO
    #     FORMATTER = logging.Formatter('%(message)s')
    # logger = logging.getLogger(__name__) #: pylint: disable=invalid-name
    #                                      #: lower-case is better here
    # logger.setLevel(LEVEL)

    # #-- Console output
    # CONSOLE = logging.StreamHandler()
    # CONSOLE.setLevel(LEVEL)
    # CONSOLE.setFormatter(FORMATTER)
    # logger.addHandler(CONSOLE)

    # #-- File output
    # if OPTIONS.debug and OPTIONS.debugfile:
    #     #: NOTE: In Python >= 2.6 normally I give FileHandler 'delay="true"'
    #     LOGFILE = logging.FileHandler(OPTIONS.debugfile)
    #     LOGFILE.setLevel(LEVEL)
    #     FORMATTER = logging.Formatter(
    #         '%(asctime)s.%(msecs)d:%(levelno)s:%(name)s.%(funcName)s:%(lineno)d:%(message)s',
    #         '%Y%m%d-%H%M'
    #         )
    #     LOGFILE.setFormatter(FORMATTER)
    #     logger.addHandler(LOGFILE)

    #-- NOTE: I've replaced my original logging-based carp w/Ansible's Display
    #   schtuff. Currently this means debug-file and help-rest don't work :-(
    logger = Display()
    if OPTIONS.debug:
        C.DEFAULT_DEBUG = True
        C.COLOR_DEBUG = 'purple'
        _debug_info()
        logger.display('\n')
        logger.debug('----- start -----')

    #-- Do The Stuff
    try:
        main()
    except KeyboardInterrupt: # Catches Ctrl-C
        logger.debug('Caught Ctrl-C')
        EXIT_STATUS = 130
    except SystemExit: # Catches sys.exit()
        logger.debug('Caught SystemExit')
        raise
    #-- NOTE: "except Exception as variable:" syntax was added in 2.6
    #-- Ansible excepts taken from ansible source code
    except AnsibleOptionsError as error:
        PARSER.print_help()
        logger.error('Ansible options error: %s' % to_text(error.message), wrap_text=False)
        EXIT_STATUS = 5
    except AnsibleParserError as error:
        logger.error('Ansible parser error: %s' % to_text(error.message), wrap_text=False)
        EXIT_STATUS = 4
    except AnsibleError as error:
        logger.error('Ansible error: %s' % to_text(error.message), wrap_text=False)
        EXIT_STATUS = 1
    except IOError as error:
        logger.debug('Caught IOError')
        if error.errno == 2:                #: No such file/directory
            msg = ('%s: [IOError] %s: %s') % (__basename__, error.strerror, error.filename)
            logger.error(to_text(msg), wrap_text=False)
            EXIT_STATUS = os.EX_UNAVAILABLE
        elif error.errno == 13:                #: Permission Denied
            msg = ('%s: [IOError] %s: %s') % (__basename__, error.strerror, error.filename)
            logger.error(to_text(msg), wrap_text=False)
            EXIT_STATUS = os.EX_NOPERM
        else:
            msg = ('%s: [IOError] %s') % (__basename__, error.strerror)
            logger.error(to_text(msg), wrap_text=False)
            EXIT_STATUS = error.errno
    except OSError as error:
        logger.debug('Caught OSError')
        if error.errno == 2:                #: No such file/directory
            msg = ('%s: [OSError] %s: %s') % (__basename__,
                                              error.strerror, error.filename)
            logger.error(to_text(msg), wrap_text=False)
            EXIT_STATUS = os.EX_UNAVAILABLE
        else:
            msg = ('%s: [OSError]: %s') % (__basename__, error.strerror)
            logger.error(to_text(msg), wrap_text=False)
            EXIT_STATUS = error.errno
    # except:       #: This is _not_ working, see hack below
    #     EXIT_STATUS = 1
    #     # print("Unexpected error:", sys.exc_info()[0])
    #     raise
    else:
        logger.debug('main() exited cleanly.')
        EXIT_STATUS = os.EX_OK
    #-- NOTE: "try..except..finally" does not work pre 2.5
    finally:
        logger.debug('Mandatory clean-up.')
        if EXIT_STATUS is None:
            logger.debug('EXIT_STATUS is still None.')
            EXIT_STATUS = 1
            raise #: pylint: disable=misplaced-bare-raise
                  #: Ignoring this here until I find a Better Way(TM)
        if OPTIONS.debug:
            logger.debug('------ end ------')
        sys.exit(EXIT_STATUS)
    #-- NOTE: more exit codes here:
    #--   https://docs.python.org/2/library/os.html#process-management
