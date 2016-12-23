#!/usr/bin/python -tt
#-- NOTE: Tabs and spaces do NOT mix!! '-tt' will flag violations as an error.
#===============================================================================
"""
.. program:: newfile
   :synopsis: Creates a new file from a template, auto-filling some fields.

.. codeauthor:: awmyhr <awmyhr@gmail.com>

.. copyright:: Apache-2.0
    Copyright 2016 awmyhr <awmyhr@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

This program will create a new file from a template, auto-filling fields.
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
# import traceback    #: Print/retrieve a stack traceback
#===============================================================================
#-- Third Party Imports
from jinja2 import Environment, FileSystemLoader, TemplateNotFound
                    #: Popular templating library
#===============================================================================
#-- Application Library Imports
#===============================================================================
#-- Variables which are meta for the script should be dunders (__varname__)
#-- TODO: Update meta vars
__version__ = '1.0.0-beta'
__revised__ = '2016-12-22'
__contact__ = 'awmyhr <awmyhr@gmail.com>'  #: primary contact for support/?'s

#-- The following few variables should be relatively static over life of script
__author__ = ['awmyhr <awmyhr@gmail.com>',
              'MyHR, Andy <andy.myhr@metlife.com'
             ]    #: coder(s) of script
__created__ = '2016-12-19'                  #: date script originlly created
__copyright__ = 'Apache-2.0'                          #: Copyright short name
__cononical_name__ = 'newfile'              #: static name, *NOT* os.path.basename(sys.argv[0])
__project_name__ = 'nixTools'               #: name of overall project, if needed
__project_home__ = 'https://github.com/awmyhr/nixTools' #: where to find source/documentation
__template_version__ = '1.1.0'              #: version of template file used
__docformat__ = 'reStructuredText en'       #: attempted style for documentation
__basename__ = os.path.basename(sys.argv[0])#: name script run as
EXIT_STATUS = None

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
    #-- NOTE: This entire function only exists to allow for outputting license
    #--       info per GNU guidelines. If not doing that, just remove it.
    #-- TODO: Like the OptionParser.epilog method, version strips newlines.
    #--        However, there is no format_version to override. If license
    #--        info is going to be output, this'll have to be fixed. It may
    #--        be possible to override print_version()
    # text = '%s (%s) %s' % (__cononical_name__, __project_name__, __version__)
    #-- NOTE: If license text is not desired, it is probably better to move
    #--       the string to the PARSER declaration and remove this function
    #-- TODO: UPDATE license
    # text += ('Copyright (c) 2016 awmyhr\n'
    #          'Licensed under the Apache License, Version 2.0 (the "License");\n'
    #          'you may not use this file except in compliance with the License.\n'
    #          'You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0\n'
    #          'Unless required by applicable law or agreed to in writing, software\n'
    #          'distributed under the License is distributed on an "AS IS" BASIS,\n'
    #          'WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.\n'
    #          'See the License for the specific language governing permissions and\n'
    #          'limitations under the License.'
    #         )


#===============================================================================
def _debug_info():
    """ Provides meta info for debug-level output """
    logger.debug('Cononical: %s', __cononical_name__)
    logger.debug('Abs Path:  %s', os.path.abspath(sys.argv[0]))
    logger.debug('Full Args: %s', ' '.join(sys.argv[:]))
    logger.debug('Python:    %s (%s.%s.%s)',
                 sys.executable, sys.version_info[0], sys.version_info[1], sys.version_info[2]
                )
    logger.debug('Version:   %s', __version__)
    logger.debug('Created:   %s', __created__)
    logger.debug('Revised:   %s', __revised__)
    logger.debug('Coder(s):  %s', __author__)
    logger.debug('Contact:   %s', __contact__)
    logger.debug('Project:   %s', __project_name__)
    logger.debug('Project Home: %s', __project_home__)
    logger.debug('Template Version: %s', __template_version__)
    logger.debug('Platform:  %s (%s)', sys.platform, os.name)
    logger.debug('uname:     %s', os.uname())
    logger.debug('[res]uid:  %s', os.getresuid())
    logger.debug('PID/PPID:  %s/%s', os.getpid(), os.getppid())


#===============================================================================
def print_list(directory):
    """ Print a list of available langauge/type combos
    :params str directory: Full path to templates directory.
    """
    logger.debug('Checking for templates in: %s', directory)
    logger.info('%-10s %-10s', 'Language', 'Type')
    for filename in os.listdir(directory):
        logger.debug('Found: %s', os.path.join(directory, filename))
        try:
            [flang, ftype] = filename.split('-')
        except ValueError:
            pass
        else:
            logger.info('%-10s %-10s', flang, ftype)


#===============================================================================
def get_git(setting):
    """ Get a config setting from git
    :param str setting: Name of git setting to retrieve
    :return: Value of setting, or 'TODO: Change <setting>'
    """
    from subprocess import check_output, CalledProcessError
    logger.debug('Checking git for setting: %s', setting)
    try:
        return check_output(['git', 'config', '--get', setting]).rstrip()
    except (OSError, CalledProcessError):
        return 'TODO: Change %s' % setting


#===============================================================================
def find_config_file():
    """ Look for .newfilerc in current + all parents
    .. Note:: Based on code found here: http://stackoverflow.com/a/37560251
    :return: fully qualified file, or None
    """
    logger.debug('Looking for .newfilerc')
    file_name = '.newfilerc'
    cur_dir = os.getcwd()

    while True:
        file_list = os.listdir(cur_dir)
        parent_dir = os.path.dirname(cur_dir)
        if file_name in file_list:
            logger.debug('Returning config file: %s',
                         os.path.join(cur_dir, file_name)
                        )
            return os.path.join(cur_dir, file_name)
        else:
            if cur_dir == parent_dir:
                logger.debug('No config file found.')
                return None
            else:
                cur_dir = parent_dir


#===============================================================================
def get_context(script_name, config_file):
    """ Finds and returns the context.
    :param str script_name: Name of new file being created.
    :param str config_file: Name (w/path if neded) of config file.
    :return: The context dictonary.
    """
    import datetime     #: Stadard date/time library
    import yaml         #: using YAML format for config file
    logger.debug('Building template context for %s with values from %s.',
                 script_name, config_file
                )
    context = {'version': '0.1.0-alpha',
               'script_name': script_name,
               'date': datetime.date.today()
              }
    context['full_name'] = get_git('user.name')
    context['email'] = get_git('user.email')
    if config_file is not None:
        for key, value in yaml.load(open(config_file, 'r')).iteritems():
            context[key] = value
    else:
        logger.warning('No config file found, check TODOs.')
    logger.debug('Returning template values: %s', context)
    return context


#===============================================================================
def main():
    """ This is where the action takes place """
    logger.debug('Template directory: %s', OPTIONS.tempdir)
    if OPTIONS.list is True:
        print_list(OPTIONS.tempdir)
        return
    logger.debug('Template lang: %s', OPTIONS.lang)
    logger.debug('Template type: %s', OPTIONS.type)
    logger.debug('New file name: %s', OPTIONS.filename)
    #-- Refuse to replace existing file
    if os.path.isfile(OPTIONS.filename):
        raise OSError(
            os.EX_CANTCREAT,
            'Cowardly refusing to overwrite existing file: %s.' % OPTIONS.filename
        )
    if OPTIONS.configfile:
        if not os.path.isfile(OPTIONS.configfile):
            raise OSError(
                os.EX_NOINPUT,
                'Indicated config file not found: %s.' % OPTIONS.configfile
            )
    else:
        OPTIONS.configfile = find_config_file()
    logger.debug('Config file: %s', OPTIONS.configfile)
    context = get_context(OPTIONS.filename, OPTIONS.configfile)

    templatefile = '%s-%s' % (OPTIONS.lang, OPTIONS.type)
    logger.debug('Loading template: %s/%s', OPTIONS.tempdir, templatefile)
    environment = Environment(loader=FileSystemLoader(OPTIONS.tempdir, followlinks=True))
    template = environment.get_template(templatefile, globals=context)
    with open(OPTIONS.filename, 'w') as outfile:
        outfile.write(template.render())

    logger.info('File has been created: %s', OPTIONS.filename)


#===============================================================================
if __name__ == '__main__':
    #-- Parse Options (rely on OptionsParser's exception handling)
    PARSER = _ModOptionParser(
        usage='Usage: %prog [options] filename',
        version='%s (%s) %s' % (__cononical_name__, __project_name__, __version__),
        description='Creates a new file from a template, auto-filling some fields.',
        epilog=('\nThis program will create a new file from a template, auto-filling fields.\n\n'
                'Created: %s  Contact: %s\n'
                'Revised: %s  Version: %s\n'
                '%s, part of %s.\nProject home: %s\n'
               ) % (__created__, __contact__,
                    __revised__, __version__,
                    __cononical_name__, __project_name__, __project_home__
                   )
    )
    PARSER.add_option('-l', '--language', dest='lang', type='string', default='python',
                      help='language/app of file [default: %default]'
                     )
    PARSER.add_option('-t', '--type', help='type of file [default: %default]',
                      dest='type', type='string', default='script'
                     )
    PARSER.add_option('--list', help='list available language/type combos',
                      dest='list', action='store_true', default=False
                     )
    PARSER.add_option('--template-dir', help='directory with template files [default: %default]',
                      dest='tempdir', type='string', action='store',
                      default=os.path.expanduser('~/Templates')
                     )
    PARSER.add_option('--config-file', dest='configfile', type='string',
                      help='config file to use [default: will search for .newfilerc'
                     )
    PARSER.add_option('--debug', help=optparse.SUPPRESS_HELP,
                      dest='debug', action='store_true', default=False
                     )
    PARSER.add_option('--debug-file', help=optparse.SUPPRESS_HELP,
                      dest='debugfile', type='string'
                     )
    (OPTIONS, ARGS) = PARSER.parse_args()
    if len(ARGS) != 1 and OPTIONS.list is False:
        PARSER.error('incorrect number of arguments')
    elif OPTIONS.list is False:
        OPTIONS.filename = ARGS[0]

    #-- Setup output(s)
    if OPTIONS.debug:
        LEVEL = logging.DEBUG
        FORMATTER = logging.Formatter('%(asctime)s %(levelname)-8s %(message)s',
                                      '%Y%m%d-%H%M'
                                     )
    else:
        LEVEL = logging.INFO
        FORMATTER = logging.Formatter('%(message)s')
    logger = logging.getLogger(__name__) #: pylint: disable=invalid-name
                                         #: lower-case is better here
    logger.setLevel(LEVEL)

    #-- Console output
    CONSOLE = logging.StreamHandler()
    CONSOLE.setLevel(LEVEL)
    CONSOLE.setFormatter(FORMATTER)
    logger.addHandler(CONSOLE)

    #-- File output
    if OPTIONS.debug and OPTIONS.debugfile:
        LOGFILE = logging.FileHandler(OPTIONS.debugfile, delay="true")
        LOGFILE.setLevel(LEVEL)
        FORMATTER = logging.Formatter(
            '%(asctime)s.%(msecs)d:%(levelno)s:%(name)s.%(funcName)s:%(lineno)d:%(message)s',
            '%Y%m%d-%H%M'
            )
        LOGFILE.setFormatter(FORMATTER)
        logger.addHandler(LOGFILE)

    if OPTIONS.debug:
        _debug_info()
        print '\n----- start -----\n'

    #-- Do The Stuff
    try:
        main()
    except KeyboardInterrupt: # Catches Ctrl-C
        EXIT_STATUS = 130
    except SystemExit: # Catches sys.exit()
        raise
    except TemplateNotFound as error:
        logger.critical('%s: No such template: %s',
                        __basename__, error
                       )
        logger.info('Possible templates in %s:', OPTIONS.tempdir)
        print_list(OPTIONS.tempdir)
        EXIT_STATUS = os.EX_UNAVAILABLE
    except IOError as error:
        if error.errno == 2:                #: No such file/directory
            logger.critical('%s: [IOError] %s: %s', __basename__,
                            error.strerror, error.filename
                           )
            EXIT_STATUS = os.EX_UNAVAILABLE
        elif error.errno == 13:                #: Permission Denied
            logger.critical('%s: [IOError] %s: %s', __basename__,
                            error.strerror, error.filename
                           )
            EXIT_STATUS = os.EX_NOPERM
        else:
            logger.critical('%s: [IOError] %s', __basename__, error.strerror)
            EXIT_STATUS = error.errno
    except OSError as error:
        if error.errno == 2:                #: No such file/directory
            logger.critical('%s: [OSError] %s: %s', __basename__,
                            error.strerror, error.filename
                           )
            EXIT_STATUS = os.EX_UNAVAILABLE
        else:
            logger.critical('%s: [OSError] %s', __basename__, error.strerror)
            EXIT_STATUS = error.errno
    else:
        EXIT_STATUS = os.EX_OK
    finally:
        if EXIT_STATUS is None:
            EXIT_STATUS = 1
            raise #: pylint: disable=misplaced-bare-raise
                  #: Ignoring this here until I find a Better Way(TM)
        if OPTIONS.debug:
            print '\n------ end ------\n'
        sys.exit(EXIT_STATUS)
