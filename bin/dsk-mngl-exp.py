#!/usr/bin/python2 -tt
# -*- coding: utf-8 -*-
# ^^-- use utf-8 strings by default
#-- NOTE: Tabs and spaces do NOT mix!! '-tt' will flag violations as an error.
#===============================================================================
'''
    :program:`dsk-mngl-exp.py`
    ============================================================

    In addition to the options listed in help output, :program:`dsk-mngl-exp.py` includes
    the following 'hidden' optoins:

    .. option:: --help-rest

        Output usage information in Sphinx/reST-style markup.

    .. option:: --debug

        Output debug-level information.

    :synopsis: TODO: CHANGEME

    :copyright: 2016 awmyhr
    :license: Apache-2.0

    .. codeauthor:: awmyhr <awmyhr@gmail.com>
'''
#===============================================================================
#-- Standard Imports
#-- NOTE: See __future__ documentation at https://docs.python.org/2/library/__future__.html
#--       This allows us to write Python 3 code for older version.
from __future__ import absolute_import  #: Require parens to group imports PEP-0328
from __future__ import division         #: Enable 3.x True Division PEP-0238
from __future__ import with_statement   #: Clean up some uses of try/except PEP--343
#-- These may break 2.5 compatibility
from __future__ import print_function   #: Makes print a function, not a statement PEP-3105
from __future__ import unicode_literals #: Introduce bytes type for older strings PEP-3112
import ConfigParser #: 'Easy' configuration parsing
#-- NOTE: We use optparse for compatibility with python < 2.7 as
#--       argparse wasn't standard until 2.7 (2.7 deprecates optparse)
#--       As of 20161212 the template is coded for optparse only
import optparse     #: pylint: disable=deprecated-module
import logging      #: Python's standard logging facilities
import os           #: Misc. OS interfaces
import sys          #: System-specific parameters & functions
import json
import yaml
import shlex
from subprocess import Popen, check_output, PIPE, STDOUT
# import traceback    #: Print/retrieve a stack traceback
#==============================================================================
#-- Third Party Imports
#==============================================================================
#-- Require a minimum Python version
if sys.version_info <= (2, 6):
    sys.exit("Minimum Python version: 2.7")
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
__revised__ = '20190307-145933' #: date of most recent revision
__contact__ = 'awmyhr <awmyhr@gmail.com>' #: primary contact for support/?'s
__synopsis__ = 'TODO: CHANGEME'
__description__ = '''TODO: CHANGEME
'''
#------------------------------------------------------------------------------
#-- The following few variables should be relatively static over life of script
__author__ = ['awmyhr <awmyhr@gmail.com>'] #: coder(s) of script
__created__ = '2019-02-28'               #: date script originlly created
__copyright__ = '2016 awmyhr' #: Copyright short name
__license__ = 'Apache-2.0'
__gnu_version__ = False #: If True print GNU version string (which includes copyright/license)
__cononical_name__ = 'dsk-mngl-exp.py' #: static name, *NOT* os.path.basename(sys.argv[0])
__project_name__ = 'nixTools from *NIXLand'  #: name of overall project, if needed
__project_home__ = 'https://github.com/awmyhr/nixTools'  #: where to find source/documentation
__template_version__ = '2.5.2'  #: version of template file used
#-- We are not using this variable for now.
__docformat__ = 'reStructuredText en'       #: attempted style for documentation
__basename__ = os.path.basename(sys.argv[0]) #: name script run as
#------------------------------------------------------------------------------
#-- Flags
__logger_file_set__ = False #: If a file setup for logger
__require_root__ = True    #: Does script require root
#------------------------------------------------------------------------------
#-- Load in environment variables, or set defaults
__default_dsf__ = os.getenv('DEFAULT_TIMESTAMP') if 'DEFAULT_TIMESTAMP' in os.environ else "%Y%m%d-%H%M%S"
__logger_dsf__ = os.getenv('LOGGER_DSF') if 'LOGGER_DSF' in os.environ else __default_dsf__
__backup_dsf__ = os.getenv('BACKUP_DSF') if 'BACKUP_DSF' in os.environ else __default_dsf__
__logger_file__ = os.getenv('LOGGER_FILE') if 'LOGGER_FILE' in os.environ else None
__logger_lvl__ = os.getenv('LOGGER_LVL') if 'LOGGER_LVL' in os.environ else 'info'

EXIT_STATUS = None
#==============================================================================
class _ModOptionParser(optparse.OptionParser):
    ''' By default format_epilog() strips newlines, we don't want that,
        so we override.
    '''

    def format_epilog(self, formatter):
        ''' We'll preformat the epilog in the decleration, just pass it through '''
        return self.epilog


#==============================================================================
class _ReSTHelpFormatter(optparse.HelpFormatter):
    ''' Format help for Sphinx/ReST output.

    NOTE: All over-ridden methods started life as copy'n'paste from original's
          source code.

    '''

    def __init__(self, indent_increment=0, max_help_position=4, width=80, short_first=0):
        optparse.HelpFormatter.__init__(self, indent_increment,
                                        max_help_position, width, short_first
                                       )

    def format_usage(self, usage):
        retval = ['%s\n' % ('=-'[self.level] * len(__cononical_name__))]
        retval.append('%s\n' % (__cononical_name__))
        retval.append('%s\n\n' % ('=-'[self.level] * len(__cononical_name__)))
        retval.append('%s' % self.format_heading('Synopsis'))
        retval.append('**%s** %s\n\n' % (__cononical_name__, usage))
        return ''.join(retval)

    def format_heading(self, heading):
        return '%s\n%s\n\n' % (heading, '--'[self.level] * len(heading))

    def format_description(self, description):
        if description:
            retval = ['%s' % self.format_heading('Description')]
            retval.append('%s\n' % self._format_text(description))
            return ''.join(retval)
        return ''

    def format_option(self, option):
        opts = self.option_strings[option]
        retval = ['.. option:: %s\n\n' % opts]
        if option.help:
            # help_text = self.expand_default(option)
            # help_lines = textwrap.wrap(help_text, self.help_width)
            retval.append('%4s%s\n\n' % ('', self.expand_default(option)))
            # retval.extend(['%4s%s\n' % ('', line)
            #                for line in help_lines[1:]])
        elif opts[-1] != '\n':
            retval.append('\n')
        return ''.join(retval)

    def format_option_strings(self, option):
        ''' Return a comma-separated list of option strings & metavariables. '''
        if option.takes_value():
            metavar = option.metavar or option.dest.upper()
            short_opts = ['%s <%s>' % (sopt, metavar)
                          for sopt in option._short_opts] #: pylint: disable=protected-access
                                                          #: We're over-riding the default
                                                          #:    method, keeping most the code.
                                                          #:    Not sure how else we'd do this.
            long_opts = ['%s=<%s>' % (lopt, metavar)
                         for lopt in option._long_opts]   #: pylint: disable=protected-access
        else:
            short_opts = option._short_opts               #: pylint: disable=protected-access
            long_opts = option._long_opts                 #: pylint: disable=protected-access

        if self.short_first:
            opts = short_opts + long_opts
        else:
            opts = long_opts + short_opts

        return ', '.join(opts)


#==============================================================================
class colors(object):
    ''' Simple class to ease access to ENV colors '''
    _colorlist = ['cf_black', 'cf_white', 'cf_orange', 'cf_magenta',
                  'cf_yellow', 'cf_red', 'cf_purple', 'cf_blue',
                  'cf_cyan', 'cf_green',
                  'c_bold', 'c_reset', 'c_undr', 'c_hide',
                  'c_blik', 'c_revr'
                 ]
    _colors = {}

    def __init__(self):
        for color in self._colorlist:
            self._colors[color] = os.getenv(color) if color in os.environ else ''

    @classmethod
    def load_colors(cls):
        ''' This will load colors from a file someday '''
        for color in cls._colorlist:
            cls._colors[color] = os.getenv(color) if color in os.environ else ''

    @classmethod
    def clear_colors(cls):
        ''' This will reset all colors to empty '''
        pass

    @property
    def black(self):
        ''' Instance property '''
        if 'cf_black' in self._colors:
            return self._colors['cf_black']
        return ''

    @property
    def white(self):
        ''' Instance property '''
        if 'cf_white' in self._colors:
            return self._colors['cf_white']
        return ''

    @property
    def magenta(self):
        ''' Instance property '''
        if 'cf_magenta' in self._colors:
            return self._colors['cf_magenta']
        return ''

    @property
    def orange(self):
        ''' Instance property '''
        if 'cf_orange' in self._colors:
            return self._colors['cf_orange']
        return ''

    @property
    def red(self):
        ''' Instance property '''
        if 'cf_red' in self._colors:
            return self._colors['cf_red']
        return ''

    @property
    def yellow(self):
        ''' Instance property '''
        if 'cf_yellow' in self._colors:
            return self._colors['cf_yellow']
        return ''

    @property
    def purple(self):
        ''' Instance property '''
        if 'cf_purple' in self._colors:
            return self._colors['cf_purple']
        return ''

    @property
    def blue(self):
        ''' Instance property '''
        if 'cf_blue' in self._colors:
            return self._colors['cf_blue']
        return ''

    @property
    def cyan(self):
        ''' Instance property '''
        if 'cf_cyan' in self._colors:
            return self._colors['cf_cyan']
        return ''

    @property
    def green(self):
        ''' Instance property '''
        if 'cf_green' in self._colors:
            return self._colors['cf_green']
        return ''

    @property
    def bold(self):
        ''' Instance property '''
        if 'c_bold' in self._colors:
            return self._colors['c_bold']
        return ''

    @property
    def reset(self):
        ''' Instance property '''
        if 'c_reset' in self._colors:
            return self._colors['c_reset']
        return ''

    @property
    def undr(self):
        ''' Instance property '''
        if 'c_undr' in self._colors:
            return self._colors['c_undr']
        return ''

    @property
    def hide(self):
        ''' Instance property '''
        if 'c_hide' in self._colors:
            return self._colors['c_hide']
        return ''

    @property
    def blik(self):
        ''' Instance property '''
        if 'c_blik' in self._colors:
            return self._colors['c_blik']
        return ''

    @property
    def revr(self):
        ''' Instance property '''
        if 'c_revr' in self._colors:
            return self._colors['c_revr']
        return ''


#==============================================================================
def timestamp(time_format=None):
    ''' Return date in specified format

    Args:
        time_format (str): Format string for timestamp. Compatible w/'date'.

    Returns:
        The formatted timestamp as a string.

    '''
    if 'logger' in globals():
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
    import time
    if time_format is None:
        time_format = __default_dsf__
    return time.strftime(time_format.strip('+'))


#==============================================================================
def get_temp(directory=None):
    ''' Creates a temporary file (or directory), returning the path.
        Defaults to file.

    Args:
        program (str): Name of program to find.

    Returns:
        For directory: absolute path to directory as a string.
        For a file: a tuple with OS-level handle to an open file.

    '''
    if 'logger' in globals():
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
    import tempfile
    if directory is not None and directory.lower() in 'directory':
        return tempfile.mkdtemp(prefix='%s-d.' % __cononical_name__)
    return tempfile.mkstemp(prefix='%s.' % __cononical_name__)


#==============================================================================
def set_value(filename, key, value):
    ''' Add or change a KEY to a VALUE in a FILE, creating FILE if necessary.

    Args:
        filename (str): File to create/modify
        key (str) :     Key to create/modify
        value (str):    Value to set key to

    Returns:
        Success/failure as a Boolean.

    '''
    if 'logger' in globals():
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        logger.debug('Passed: file: %s, key: %s, value: %s', filename, key, value)
    raise NotImplementedError('TODO: implement set_value().')

#==============================================================================
def RunLogger(debug=False):
    ''' Set up Python's Logging

    Args:
        debug (boolean): Debug flag.

    Returns:
        The logging object.

    '''
    new_logger = logging.getLogger(__name__)
    new_logger.setLevel(logging.DEBUG)

    if debug:
        level = logging.DEBUG
        formatter = logging.Formatter('%(asctime)s %(levelname)-8s %(message)s',
                                      __logger_dsf__
                                     )
    else:
        if __logger_lvl__.isdigit():
            if int(__logger_lvl__) > 49:
                level = logging.CRITICAL
            elif int(__logger_lvl__) < 10:
                level = logging.NOTSET
            else:
                level = (int(__logger_lvl__)) //10 * 10
        else:
            level = logging.getLevelName(__logger_lvl__.upper())
        #-- Yes, we are going to ignore unknown values by setting to INFO
        if isinstance(level, str) and level.startswith('Level'):
            level = logging.INFO
        formatter = logging.Formatter('%(message)s')

    #-- Console output
    console = logging.StreamHandler()
    console.setLevel(level)
    console.setFormatter(formatter)
    new_logger.addHandler(console)

    #-- File output
    if __logger_file__:
        if os.path.isfile(__logger_file__):
            os.rename(__logger_file__, '%s.%s' % (__logger_file__, timestamp(__backup_dsf__)))
        #: NOTE: In Python >= 2.6 normally I give FileHandler 'delay="true"'
        logfile = logging.FileHandler(__logger_file__)
        logfile.setLevel(logging.DEBUG)
        formatter = logging.Formatter(
            '%(asctime)s.%(msecs)d:%(levelno)s:%(name)s.%(funcName)s:%(lineno)d:%(message)s',
            __logger_dsf__
            )
        logfile.setFormatter(formatter)
        new_logger.addHandler(logfile)
        global __logger_file_set__               #: pylint: disable=global-statement
        __logger_file_set__ = True

    import platform #: Easily get platforms identifying info
    new_logger.debug('Version:   %s (%s) %s', __cononical_name__, __project_name__, __version__)
    new_logger.debug('Created:   %s / Revised: %s', __created__, __revised__)
    new_logger.debug('Abs Path:  %s', os.path.abspath(sys.argv[0]))
    new_logger.debug('Full Args: %s', ' '.join(sys.argv[:]))
    new_logger.debug('Python:    %s (%s)', sys.executable, platform.python_version())
    new_logger.debug('Coder(s):  %s', __author__)
    new_logger.debug('Contact:   %s', __contact__)
    new_logger.debug('Project Home: %s', __project_home__)
    new_logger.debug('Template Version: %s', __template_version__)
    new_logger.debug('System:    %s', platform.system_alias(platform.system(),
                                                            platform.release(),
                                                            platform.version()
                                                           )
                    )
    new_logger.debug('Platform:  %s', platform.platform())
    new_logger.debug('Hostname:  %s', platform.node())
    new_logger.debug('Logname:   %s', os.getlogin())
    new_logger.debug('[re]uid:  %s/%s', os.getuid(), os.geteuid())
    new_logger.debug('PID/PPID:  %s/%s', os.getpid(), os.getppid())
    if options._options is not None:             #: pylint: disable=protected-access
        new_logger.debug('Parsed Options: %s', options._options) #: pylint: disable=protected-access
    if debug:
        print('\n----- start -----\n')

    return new_logger


#==============================================================================
def which(program):
    '''Test if a program exists in $PATH.

    Args:
        program (str): Name of program to find.

    Returns:
        String to use for program execution.

    Note:
        Originally found this here:
        http://stackoverflow.com/questions/377017/test-if-executable-exists-in-python
    '''
    logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
    logger.debug('Looking for command: %s', program)
    def _is_exe(fpath):
        ''' Private test for executeable '''
        return os.path.isfile(fpath) and os.access(fpath, os.X_OK)

    fpath, _ = os.path.split(program)
    if fpath:
        if _is_exe(program):
            logger.debug('Found %s here.', program)
            return program
    else:
        for path in os.environ["PATH"].split(os.pathsep):
            path = path.strip('"')
            exe_file = os.path.join(path, program)
            if _is_exe(exe_file):
                logger.debug('Found %s here: %s', program, exe_file)
                return exe_file

    logger.debug('Could not find %s.', program)
    return None


#==============================================================================
class RunOptions(object):
    ''' Parse the options and put them into an object

        Returns:
            A RunOptions object.

    '''
    _defaults = {
        'debug': False,
    }

    _arguments = None
    _configs = None
    _options = None

    def __init__(self, args=None):
        if self._configs is not None:
            raise ValueError('Configs already initialized.')
        else:
            self._configs = self._load_configs()
        if self._options is not None:
            raise ValueError('Arguments already initialized.')
        else:
            (self._options, self._arguments) = self._parse_args(args)

    def _load_configs(self):
        parser = ConfigParser.SafeConfigParser(defaults=self._defaults)
        parser.read([os.path.expanduser('~/.%s' % __cononical_name__),
                     '%s.cfg' % __cononical_name__])
        #-- TODO: Define possible sections
        if not parser.has_section('debug'):
            parser.add_section('debug')
        return parser

    @property
    def args(self):
        ''' Class property '''
        if self._arguments is not None:
            return self._arguments
        return None

    @property
    def debug(self):
        ''' Class property '''
        if self._options is not None:
            return self._options.debug
        return self._defaults['debug']

    @property
    def ansible_called(self):
        ''' Class property '''
        return bool(__basename__.startswith('ansible_module'))

    def _parse_args(self, args):
        #-- Parse Options (rely on OptionsParser's exception handling)
        description_string = __synopsis__
        epilog_string = ('\n%s\n\n'
                         'Created: %s  Contact: %s\n'
                         'Revised: %s  Version: %s\n'
                         '%s, part of %s. Project home: %s\n'
                        ) % (__description__,
                             __created__, __contact__,
                             __revised__, __version__,
                             __cononical_name__, __project_name__, __project_home__
                            )
        usage_string = '%s [options]' % (__basename__)
        version_string = '%s (%s) %s' % (__cononical_name__, __project_name__, __version__)
        if __gnu_version__:
            version_string += '\nCopyright %s\nLicense %s\n' % (__copyright__, __license__)
        parser = _ModOptionParser(version=version_string, usage=usage_string,
                                  description=description_string, epilog=epilog_string)
        #-- TODO: Add options, also set _default and @property (if needed).
        #-- Visible Options
        #   These can *not* be set in a config file
        #   These could be set in a config file

        #-- Hidden Options
        #   These can *not* be set in a config file
        parser.add_option('--help-rest', dest='helprest', action='store_true',
                          help=optparse.SUPPRESS_HELP, default=None)
        #   These could be set in a config file
        parser.add_option('--debug', dest='debug', action='store_true',
                          help=optparse.SUPPRESS_HELP,
                          default=self._configs.get('debug', 'debug'))

        parsed_opts, parsed_args = parser.parse_args(args)
        if parsed_opts.helprest:
            parser.formatter = _ReSTHelpFormatter()
            parser.usage = '[*options*]'         #: pylint: disable=attribute-defined-outside-init
                                                 #: Not yet sure of a better way to do this...
            parser.description = __description__ #: pylint: disable=attribute-defined-outside-init
            parser.epilog = '\nAuthor\n------\n\n%s\n' % ('; '.join(__author__))
            parser.print_help()
            sys.exit(os.EX_OK)
        #-- Put any option validation here...

        return parsed_opts, parsed_args


#==============================================================================
class Convert():
    ''' adopted from:
        http://code.activestate.com/recipes/578019-bytes-to-human-human-to-bytes-converter/
    '''
    __version = '1.0.0-alpha01'
    SYMBOLS = {
        'customary': ('B', 'K', 'M', 'G', 'T', 'P', 'E', 'Z', 'Y'),
        'customary_ext': ('byte', 'kilo', 'mega', 'giga', 'tera', 'peta', 'exa', 'zetta', 'iotta'),
        'customary_mod': ('B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'),
        'customary_low': ('b', 'k', 'm', 'g', 't', 'p', 'e', 'z', 'y'),
        'customary_modlow': ('b', 'kb', 'mb', 'gb', 'tb', 'pb', 'eb', 'zb', 'yb'),
        'iec': ('Bi', 'Ki', 'Mi', 'Gi', 'Ti', 'Pi', 'Ei', 'Zi', 'Yi'),
        'iec_ext': ('byte', 'kibi', 'mebi', 'gibi', 'tebi', 'pebi', 'exbi', 'zebi', 'yobi'),
        'iec_low': ('bi', 'ki', 'mi', 'gi', 'ti', 'pi', 'ei', 'zi', 'yi'),
        }

    @classmethod
    def to_bytes(cls, value):
        ''' Convert human to bytes '''
        passed_value = value
        num = ""
        while value and value[0:1].isdigit() or value[0:1] == '.':
            num += value[0]
            value = value[1:]
        num = float(num)
        letter = value.strip()
        for set_name, set_items in cls.SYMBOLS.items():
            if letter in set_items:
                break
        else:
            set_name = 'customary'
            set_items = cls.SYMBOLS[set_name]
            raise ValueError("can't interpret %r" % passed_value)
        logger.debug('Using symbols set %s.', set_name)
        prefix = {set_items[0]:1}
        for i, s in enumerate(set_items[1:]):
            prefix[s] = 1 << (i+1)*10
        return int(num * prefix[letter])

    @classmethod
    def to_human(cls, num, fmt='%(value).1f %(symbol)s', symbols='customary'):
        ''' Convert bytes to human '''
        num = int(num)
        if num < 0:
            raise ValueError("num < 0")
        symbols = cls.SYMBOLS[symbols]
        prefix = {}
        for i, sym in enumerate(symbols[1:]):
            prefix[sym] = 1 << (i+1)*10
        for symbol in reversed(symbols[1:]):
            if num >= prefix[symbol]:
                value = float(num) / prefix[symbol]
                return fmt % locals()
        return fmt % dict(symbol=symbols[0], value=num)


#==============================================================================
class Storage():
    ''' docs
    '''
    __version = '1.0.0-alpha03'
    blktree = {}
    blklst = {}
    mntlst = {}
    lvlst = {}
    pvlst = {}
    vglst = {}
    lv_paths2full_name = {}

    def __init__(self):
        ''' '''
        if 'logger' in globals():
            logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        self._update_blk_lists()
        self._update_mnt_lists()
        self._update_lvm_lists()

    def _update_blk_lists(self):
        ''' '''
        if 'logger' in globals():
            logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        output = Popen(['lsblk', '--pairs', '--noheadings', '--bytes', '--all',
                        '--output', 'type,size,name,kname,pkname,fstype,mountpoint,label,uuid'],
                       stdout=PIPE, stderr=STDOUT)
        for line in iter(output.stdout.readline, ""):
            item = dict(token.split('=') for token in shlex.split(line))
            item = {k.lower(): v for k, v in item.items()}
            for spec in ['size', 'avail', 'used']:
                if spec in item:
                    item[spec] = int(item[spec])
            empty_item = {k for k, v in item.items() if v == ''}
            for k in empty_item:
                item[k] = None

            if item['type'] not in self.blktree:
                self.blktree[item['type']] = {}
            self.blktree[item['type']][item['name']] = []
            if item['mountpoint'] is not None:
                self.mntlst[item['mountpoint']] = item
            self.blklst[item['name']] = item
            self.blklst[item['name']].update({'children': []})
            if item['pkname'] is not None:
                self.blklst[item['pkname']]['children'].append(item['name'])
                self.blktree[self.blklst[item['pkname']]['type']][item['pkname']].append(item['name'])

    def _update_mnt_lists(self):
        ''' '''
        if 'logger' in globals():
            logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        output = Popen(['findmnt', '--pairs', '--noheadings', '--bytes', '--all',
                        '--output', 'source,target,fstype,label,uuid,size,avail,used,fsroot'],
                       stdout=PIPE, stderr=STDOUT)
        # import pprint
        for line in iter(output.stdout.readline, ""):
            item = dict(token.split('=') for token in shlex.split(line))
            item = {k.lower(): v for k, v in item.items()}
            for spec in ['size', 'avail', 'used']:
                if spec in item:
                    item[spec] = int(item[spec])
            empty_item = {k for k, v in item.items() if v == ''}
            for k in empty_item:
                item[k] = None

            # if item['target'] == '/var/tmp':
            #     print('====================================================')
            #     pprint.pprint(self.blklst['vg00-var_tmp'])
            #     pprint.pprint(item['target'])
            #     print('====================================================')
            if item['target'] not in self.mntlst:
                self.mntlst[item['target']] = item
                # if item['target'] == '/var/tmp':
                #     print('====================================================')
                #     print('ADDING TO MNTLST')
                #     pprint.pprint(item)
                #     print('====================================================')
            else:
                item['size'] = self.mntlst[item['target']]['size']
                self.mntlst[item['target']].update(item)
                # if item['target'] == '/var/tmp':
                #     print('====================================================')
                #     print('UPDATING MNTLST')
                #     pprint.pprint(item)
                #     print('====================================================')
                #     pprint.pprint(self.blklst['vg00-var_tmp'])
                #     print('====================================================')
            if item['target'] is not item['fsroot']:
                self.mntlst[item['fsroot']]['children'].append(item['target'])

    def _update_lvm_lists(self):
        ''' '''
        if 'logger' in globals():
            logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        out = check_output(['pvs', '--noheadings', '--units', 'B', '--nosuffix',
                            '--reportformat', 'json', '--options', 'pv_all'])
        for entry in json.loads(out)['report'][0]['pv']:
            for spec in ['dev_size', 'pv_free', 'pv_used', 'pv_size']:
                if spec in entry:
                    entry[spec] = int(entry[spec])
            self.pvlst[entry['pv_name']] = entry
        # of interest: pv_name,pv_size,pv_free,pv_in_use
        out = check_output(['vgs', '--readonly', '--noheadings', '--units', 'B',
                            '--nosuffix', '--reportformat', 'json', '--options',
                            'vg_all'])
        for entry in json.loads(out)['report'][0]['vg']:
            for spec in ['vg_size', 'vg_free', 'vg_used']:
                if spec in entry:
                    entry[spec] = int(entry[spec])
            self.vglst[entry['vg_name']] = entry
        # of interest: vg_name,vg_size,vg_free,pv_count,lv_count
        out = check_output(['lvs', '--readonly', '--noheadings', '--units', 'B',
                            '--nosuffix', '--reportformat', 'json', '--options',
                            'lv_all,vg_name'])
        for entry in json.loads(out)['report'][0]['lv']:
            for spec in ['lv_size']:
                if spec in entry:
                    entry[spec] = int(entry[spec])
            self.lvlst[entry['lv_full_name']] = entry
            if entry['lv_path'] != '':
                self.lv_paths2full_name[entry['lv_path']] = entry['lv_full_name']
            if entry['lv_dm_path'] != '':
                dm_path = entry['lv_dm_path']
                self.lv_paths2full_name[dm_path] = entry['lv_full_name']
                self.lv_paths2full_name[os.path.basename(dm_path)] = entry['lv_full_name']
        # of interest: lv_name,lv_full_name,lv_path,lv_dm_path,lv_size,vg_name

    @staticmethod
    def is_mpoint(path):
        ''' Checks if a path is a mountpoint
        Args:
            path:   Filesystem path to check
        Returns:
            True if path is a mountpoint
        '''
        if 'logger' in globals():
            logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        return os.path.ismount(path)

    @staticmethod
    def mnt_for_path(path):
        ''' Find mountpoint of a path
        Args:
            path:   Filesystem path to check
        Returns:
            [SWAP] if passed 'swap', 'SWAP', or '[SWAP]'
            None if path does not exist
            String of filesystem path to mountpoint
        '''
        if 'logger' in globals():
            logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        if path in ['swap', 'SWAP', '[SWAP]']:
            return '[SWAP]'
        if os.path.exists(path):
            return check_output(['findmnt', '--raw', '--noheadings', '--output', 'target', '-T', path]).strip()
        return None

    def lvol_for_path(self, path):
        ''' Find logical volume of a path
        Args:
            path:   Filesystem path to check
        Returns:
            None if path does not exist or is not on a logical volume
            String of logical volume full name
        '''
        if 'logger' in globals():
            logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        mpoint = self.mnt_for_path(path)
        if mpoint is None or mpoint not in self.mntlst:
            return None
        mpoint = self.mntlst[mpoint]
        if 'type' in mpoint and mpoint['type'] == 'lvm':
            if 'source' in mpoint:
                return self.lv_paths2full_name[mpoint['source']]
            return self.lv_paths2full_name[mpoint['name']]
        return None

    def vg_for_path(self, path):
        ''' Find volume group of a path
        Args:
            path:   Filesystem path to check
        Returns:
            None if path does not exist or is not in a volume group
            String of volume group name
        '''
        if 'logger' in globals():
            logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        lvol = self.lvol_for_path(path)
        if lvol is None:
            return None
        if 'vg_name' in self.lvlst[lvol]:
            return self.lvlst[lvol]['vg_name']
        return None

    def dev_for_path(self, path):
        ''' Find device of a path
        Args:
            path:   Filesystem path to check
        Returns:
            None if path does not exist or device is not known
            String of device path
        '''
        if 'logger' in globals():
            logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        mpoint = self.mnt_for_path(path)
        if mpoint is None or mpoint not in self.mntlst:
            return None
        mpoint = self.mntlst[mpoint]
        if 'source' in mpoint:
            return mpoint['source']
        return None

    def is_mnt_at_least(self, path, size):
        ''' Check if size of a mountpoint is at least given size
        Args:
            path:   Filesystem path to check
            size:   Minimum size to check
        Returns:
            None if path does not exist
            True if mountpoint is at least given size
            False if it is not
        '''
        if 'logger' in globals():
            logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        mpoint = self.mnt_for_path(path)
        if mpoint is None or mpoint not in self.mntlst:
            return None
        mpoint = self.mntlst[mpoint]
        if 'size' in mpoint and mpoint['size'] >= Convert.to_bytes(size):
            return True
        return False

    def is_lvol_at_least(self, lvol, size):
        ''' Check if size of a logical volume is at least given size
        Args:
            lvol:   lvol full name to check
            size:   Minimum size to check
        Returns:
            None if lvol does not exist
            True if lvol is at least given size
            False if it is not
        '''
        if 'logger' in globals():
            logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        if lvol not in self.lvlst:
            return None
        lvol = self.lvlst[lvol]
        if 'lv_size' in lvol and lvol['lv_size'] >= Convert.to_bytes(size):
            return True
        return False

    def is_vg_at_least(self, vgn, size):
        ''' Check if size of a volume group is at least given size
        Args:
            vgn:    vg name to check
            size:   Minimum size to check
        Returns:
            None if vgn does not exist
            True if vgn is at least given size
            False if it is not
        '''
        if 'logger' in globals():
            logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        if vgn not in self.vglst:
            return None
        vgn = self.vglst[vgn]
        if 'vg_size' in vgn and vgn['vg_size'] >= Convert.to_bytes(size):
            return True
        return False

#==============================================================================
def main():
    ''' This is where the action takes place
        We expect options and logger to be global
    '''
    logger.debug('Starting main()')
    #-- TODO: Do something more interesting here...
    from pprint import pprint
    devs = Storage()

    print('------------------------------------------------------------')

    # pprint(devs.blktree)
    # print('------------------------------------------------------------')

    # pprint(devs.pvlst)
    # print('------------------------------------------------------------')
    # pprint(devs.vglst)
    # print('------------------------------------------------------------')
    # pprint(devs.lvlst)
    # print('------------------------------------------------------------')

    # pprint(devs.blklst)
    # print('------------------------------------------------------------')
    # pprint(devs.mntlst)
    # print('------------------------------------------------------------')

    # pprint(devs.lv_paths2full_name)
    # print('------------------------------------------------------------')
    # pprint(devs.lv_dm_path2lv_full_name)
    # print('------------------------------------------------------------')

    for disk in devs.blktree['disk']:
        print('%s - %s' % (disk, Convert.to_human(devs.blklst[disk]['size'])))
        print('    num childs: %s' % len(devs.blklst[disk]['children']))
    # print('------------------------------------------------------------')

    # print('is_mpoint /var/tmp: %s' % devs.is_mpoint('/var/tmp'))
    # print('is_mpoint /var/tmp/test: %s' % devs.is_mpoint('/var/tmp/test'))
    # print('is_mpoint /tmp: %s' % devs.is_mpoint('/tmp'))
    # print('is_mpoint /var: %s' % devs.is_mpoint('/var'))
    # print('is_mpoint /var/lib: %s' % devs.is_mpoint('/var/lib'))
    # print('is_mpoint /var/lib/containers: %s' % devs.is_mpoint('/var/lib/containers'))
    # print('------------------------------------------------------------')

    # print('/var/log/anaconda lvol: %s' % devs.lvol_for_path('/var/log/anaconda'))
    # print('/var/log/anaconda vgrp: %s' % devs.vg_for_path('/var/log/anaconda'))
    # print('/var/log/anaconda mntp: %s' % devs.mnt_for_path('/var/log/anaconda'))
    # print('/var/log/anaconda  dev: %s' % devs.dev_for_path('/var/log/anaconda'))
    # print('------------------------------------------------------------')

    # print('swap lvol: %s' % devs.lvol_for_path('swap'))
    # print('swap vgrp: %s' % devs.vg_for_path('swap'))
    # print('swap mntp: %s' % devs.mnt_for_path('swap'))
    # print('swap  dev: %s' % devs.dev_for_path('swap'))
    # print('------------------------------------------------------------')

    # print('/var/tmp bigger 2G: %s' % devs.is_mnt_at_least('/var/tmp', '2G'))
    # print('/var/tmp bigger 9G: %s' % devs.is_mnt_at_least('/var/tmp', '9G'))
    # print('/var/tmp lvol at lest 5G: %s' % devs.is_lvol_at_least(devs.lvol_for_path('/var/tmp'), '5G'))
    # print('/var/tmp vg at least 10G: %s' % devs.is_vg_at_least(devs.vg_for_path('/var/tmp'), '10G'))
    # print('swap lvol at lest 2G: %s' % devs.is_lvol_at_least(devs.lvol_for_path('swap'), '2G'))
    # print('swap vg at least 90G: %s' % devs.is_vg_at_least(devs.vg_for_path('swap'), '90G'))
    # print('------------------------------------------------------------')

    # desired_conf = yaml.load(open('/home/amyhr/work/metlife/linux-engineering-tools/lib/default-dir.yml'))
    # # pprint(desired_conf)
    # for directory in desired_conf['directories']:
    #     print('%s' % (directory['path']))
    #     print('    lvol: %s' % devs.lvol_for_path(directory['path']))
    #     print('      vg: %s' % devs.vg_for_path(directory['path']))
    #     print('    fsys: %s' % devs.dev_for_path(directory['path']))
    #     if directory['mpreq']:
    #         print(' - is mountpoint? %s' % devs.is_mpoint(directory['path']))
    #     print(' - is at least %s? %s' % (directory['size'], devs.is_mnt_at_least(directory['path'], directory['size'])))
    # print('------------------------------------------------------------')

    # for vgroup in desired_conf['vgroups']:
    #     print('%s at least %s? %s' % (vgroup['name'], vgroup['size'], devs.is_vg_at_least(vgroup['name'], vgroup['size'])))
    # print('------------------------------------------------------------')


#==============================================================================
if __name__ == '__main__':
    #-- Setting up logger here so we can use them in even of exceptions.
    #   Parsing options here as we need them to setup the logger.
    options = RunOptions(sys.argv[1:])           #: pylint: disable=invalid-name
    logger = RunLogger(options.debug)            #: pylint: disable=invalid-name
    if __require_root__ and os.getegid() != 0:
        logger.error('Must be run as root.')
        sys.exit(77)

    #-- NOTE: "except Exception as variable:" syntax was added in 2.6, previously
    #         one would use "except Exception, variable:", but that is not
    #         compatible with 3.x. In order to be compatible with 2.5 (for RHEL 5)
    #         and forward, we use "execpt Exception:", then on the first line of
    #         the exception use "_, error, _ = sys.exc_info()". HOWEVER, pylint
    #         will no longer be able to warn on object members...
    #         type, value, traceback = sys.exc_info()
    try:
        main()
    except KeyboardInterrupt: # Catches Ctrl-C
        logger.debug('Caught Ctrl-C')
        EXIT_STATUS = 130
    except SystemExit as error: # Catches sys.exit()
        #_, error, _ = sys.exc_info()
        logger.debug('Caught SystemExit')
        logger.warning('%s: [SystemExit] %s', __basename__, error)
    except IOError as error:
        #_, error, _ = sys.exc_info()
        logger.debug('Caught IOError')
        if error.errno is None:
            logger.critical('%s: [IOError]: %s', __basename__, error)
            EXIT_STATUS = 10
        elif error.errno == 2:                #: No such file/directory
            logger.critical('%s: [IOError] %s: %s', __basename__,
                            error, error.filename
                           )
            EXIT_STATUS = os.EX_UNAVAILABLE
        elif error.errno == 13:                #: Permission Denied
            logger.critical('%s: [IOError] %s: %s', __basename__,
                            error, error.filename
                           )
            EXIT_STATUS = os.EX_NOPERM
        else:
            logger.critical('%s: [IOError] %s', __basename__, error)
            EXIT_STATUS = error.errno
    except OSError as error:
        #_, error, _ = sys.exc_info()
        logger.debug('Caught OSError')
        if error.errno == 2:                #: No such file/directory
            logger.critical('%s: [OSError] %s: %s', __basename__,
                            error, error.filename
                           )
            EXIT_STATUS = os.EX_UNAVAILABLE
        else:
            logger.critical('%s: [OSError] %s', __basename__, error)
            EXIT_STATUS = error.errno
    except Exception as error:                   #: pylint: disable=broad-except
        #_, error, _ = sys.exc_info()
        logger.debug('Caught Exception: %s', sys.exc_info())
        logger.critical('%s: %s', __basename__, error)
        EXIT_STATUS = 10
    else:
        logger.debug('main() exited cleanly.')
        if EXIT_STATUS is None:
            EXIT_STATUS = os.EX_OK
    #-- NOTE: "try..except..finally" does not work pre 2.5
    finally:
        logger.debug('Mandatory clean-up.')
        if EXIT_STATUS is None:
            logger.debug('EXIT_STATUS is still None.')
            EXIT_STATUS = 20
        if options.debug:
            print('\n------ end ------\n')
        logging.shutdown()
        sys.exit(EXIT_STATUS)
    #-- NOTE: more exit codes here:
    #--   https://docs.python.org/2/library/os.html#process-management
