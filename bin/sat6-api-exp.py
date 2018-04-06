#!/usr/bin/python2 -tt
# -*- coding: utf-8 -*-
# ^^-- use utf-8 strings by default
#-- NOTE: Tabs and spaces do NOT mix!! '-tt' will flag violations as an error.
#===============================================================================
"""
    :program:`bin/sat6-api-exp.py`
    ============================================================

    In addition to the options listed in help output, :program:`bin/sat6-api-exp.py` includes
    the following 'hidden' optoins:

    .. option:: --help-rest

        Output usage information in Sphinx/reST-style markup.

    .. option:: --debug

        Output debug-level information.

    :synopsis: TODO: CHANGEME

    :copyright: 2016 awmyhr
    :license: Apache-2.0

    .. codeauthor:: awmyhr <awmyhr@gmail.com>
"""
#===============================================================================
#-- Standard Imports
#-- NOTE: We use optparse for compatibility with python < 2.7 as
#--       argparse wasn't standard until 2.7 (2.7 deprecates optparse)
#--       As of 20161212 the template is coded for optparse only
import logging      #: Python's standard logging facilities
import optparse     #: pylint: disable=deprecated-module
import os           #: Misc. OS interfaces
import sys          #: System-specific parameters & functions
# import traceback    #: Print/retrieve a stack traceback
#==============================================================================
#-- Third Party Imports
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
__version__ = '0.1.1-alpha' #: current version
__revised__ = '20180405-163321' #: date of most recent revision
__contact__ = 'awmyhr <awmyhr@gmail.com>' #: primary contact for support/?'s
__synopsis__ = 'TODO: CHANGEME'
__description__ = """TODO: CHANGEME
"""
#------------------------------------------------------------------------------
#-- The following few variables should be relatively static over life of script
__author__ = ['awmyhr <awmyhr@gmail.com>'] #: coder(s) of script
__created__ = '2018-04-05'               #: date script originlly created
__copyright__ = '2016 awmyhr' #: Copyright short name
__license__ = 'Apache-2.0'
__gnu_version__ = False #: If True print GNU version string (which includes copyright/license)
__cononical_name__ = 'bin/sat6-api-exp.py' #: static name, *NOT* os.path.basename(sys.argv[0])
__project_name__ = 'nixTools from *NIXLand'  #: name of overall project, if needed
__project_home__ = 'https://github.com/awmyhr/nixTools'  #: where to find source/documentation
__template_version__ = '2.0.0-alpha-02'              #: version of template file used
#-- We are not using this variable for now.
__docformat__ = 'reStructuredText en'       #: attempted style for documentation
__basename__ = os.path.basename(sys.argv[0]) #: name script run as
#------------------------------------------------------------------------------
#-- Flags
__logger_file_set__ = False #: If a file setup for logger
__require_root__ = False    #: Does script require root
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
        return ''

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
def _debug_info():
    """ Provides meta info for debug-level output """
    import platform #: Easily get platforms identifying info
    logger = logging.getLogger(__name__)
    logger.debug('Cononical: %s', __cononical_name__)
    logger.debug('Abs Path:  %s', os.path.abspath(sys.argv[0]))
    logger.debug('Full Args: %s', ' '.join(sys.argv[:]))
    logger.debug('Python:    %s (%s)', sys.executable, platform.python_version())
    logger.debug('Version:   %s', __version__)
    logger.debug('Created:   %s', __created__)
    logger.debug('Revised:   %s', __revised__)
    logger.debug('Coder(s):  %s', __author__)
    logger.debug('Contact:   %s', __contact__)
    logger.debug('Project:   %s', __project_name__)
    logger.debug('Project Home: %s', __project_home__)
    logger.debug('Template Version: %s', __template_version__)
    logger.debug('System:    %s', platform.system_alias(platform.system(),
                                                        platform.release(),
                                                        platform.version()
                                                       )
                )
    logger.debug('Platform:  %s', platform.platform())
    logger.debug('Hostname:  %s', platform.node())
    logger.debug('[res]uid:  %s', os.getresuid())
    logger.debug('PID/PPID:  %s/%s', os.getpid(), os.getppid())


#==============================================================================
def timestamp(time_format=None):
    """ Return date in specified format """
    import time
    if time_format is None:
        time_format = __default_dsf__
    time_format = time_format.strip('+')
    return time.strftime(time_format)


#==============================================================================
def CLILogger(opts):
    """ Set up the Logger """
    if 'logger' in globals():
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
    if opts.debug:
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
        formatter = logging.Formatter('%(message)s')

    #-- Yes, we are going to ignore unknown values by setting to INFO
    if isinstance(level, str) and level.startswith('Level'):
        level = logging.INFO

    new_logger = logging.getLogger(__name__)
    new_logger.setLevel(level)

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
        global __logger_file_set__ #: pylint: disable=global-statement
        __logger_file_set__ = True

    if opts.debug:
        _debug_info()
        print('\n----- start -----\n')

    return new_logger


#==============================================================================
class CLIOptions(object):
    """ Parse the options and put them into an object """
    _hostname = None
    _lifecycle = None
    _org_name = None
    _org_id = None
    _server = None
    _username = None
    _password = None
    _authkey = None
    _configfile = None
    _helprest = False
    _debug = False

    _options = None
    _args = None

    def __init__(self, args=None):
        if self._options is not None:
            raise ValueError('CLIOptions already initialized.')
        else:
            (self._options, self._arguments) = self._parse_args(args)
        if self.helprest:
            self._print_rest_help()

    @property
    def args(self):
        """ Class property """
        if self._arguments is not None:
            return self._arguments
        return self._args

    @args.setter
    def args(self, value):
        self._args = value

    @property
    def helprest(self):
        """ Class property """
        if self._options is not None:
            return self._options.helprest
        return self._helprest

    @helprest.setter
    def helprest(self, value):
        self._helprest = value

    @property
    def debug(self):
        """ Class property """
        if self._options is not None:
            return self._options.debug
        return self._debug

    @debug.setter
    def debug(self, value):
        self._debug = value

    @property
    def hostname(self):
        """ Class property """
        if self._options is not None:
            return self._options.hostname
        return self._hostname

    @hostname.setter
    def hostname(self, value):
        self._hostname = value

    @property
    def lifecycle(self):
        """ Class property """
        if self._options is not None:
            return self._options.lifecycle
        return self._lifecycle

    @lifecycle.setter
    def lifecycle(self, value):
        self._lifecycle = value

    @property
    def org_name(self):
        """ Class property """
        if self._options is not None:
            return self._options.org_name
        return self._org_name

    @org_name.setter
    def org_name(self, value):
        self._org_name = value

    @property
    def org_id(self):
        """ Class property """
        if self._options is not None:
            return self._options.org_id
        return self._org_id

    @org_id.setter
    def org_id(self, value):
        self._org_id = value

    @property
    def server(self):
        """ Class property """
        if self._options is not None:
            return self._options.server
        return self._server

    @server.setter
    def server(self, value):
        self._server = value

    @property
    def username(self):
        """ Class property """
        if self._options is not None:
            return self._options.username
        return self._username

    @username.setter
    def username(self, value):
        self._username = value

    @property
    def password(self):
        """ Class property """
        if self._options is not None:
            return self._options.password
        return self._password

    @password.setter
    def password(self, value):
        self._password = value

    @property
    def authkey(self):
        """ Class property """
        if self._options is not None:
            return self._options.authkey
        return self._authkey

    @authkey.setter
    def authkey(self, value):
        self._authkey = value

    @property
    def configfile(self):
        """ Class property """
        if self._options is not None:
            return self._options.configfile
        return self._configfile

    @configfile.setter
    def configfile(self, value):
        self._configfile = value

    def _print_rest_help(self):
        self.parser.formatter = _ReSTHelpFormatter()
        self.parser.usage = '[*options*]'            #: pylint: disable=attribute-defined-outside-init
                                                #: Not yet sure of a better way to do this...
        self.parser.description = __description__    #: pylint: disable=attribute-defined-outside-init
        self.parser.epilog = ('\nAuthor\n------\n\n'
                              '%s\n'
                             ) % ('; '.join(__author__))
        self.parser.print_help()
        sys.exit(os.EX_OK)

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
            version_string += ('\nCopyright 2016 awmyhr\n'
                               'License Apache-2.0\n'
                              )
        parser = _ModOptionParser(version=version_string, usage=usage_string,
                                  description=description_string, epilog=epilog_string
                                 )
        self.parser = parser
        parser.add_option('-H', '--hostname', dest='hostname', type='string',
                          help='Hostname to change.', default=None
                         )
        parser.add_option('-L', '--lifecycle', dest='lifecycle', type='string',
                          help='Life-cycle environment.', default=None
                         )
        parser.add_option('-o', '--organization', dest='org_name', type='string',
                          help='Organization name.', default=None
                         )
        parser.add_option('-O', '--organization-id', dest='org_id', type='int',
                          help='Organization ID number.', default=None
                         )
        parser.add_option('-s', '--server', dest='server', type='string',
                          help='Satellite server.', default=None
                         )
        parser.add_option('-u', '--username', dest='username', type='string',
                          help='Satellite username.', default=None
                         )
        parser.add_option('-p', '--password', dest='password', type='string',
                          help='Satellite user password.', default=None
                         )
        parser.add_option('-K', '--userkey', dest='authkey', type='string',
                          help='Satellite user access key.', default=None
                         )
        #-- 'Hidden' options
        parser.add_option('-c', '--config', dest='configfile', type='string',
                          help='User Satellite config file.', default=None
                         )
        parser.add_option('--help-rest', dest='helprest', action='store_true',
                          help=optparse.SUPPRESS_HELP, default=False
                         )
        parser.add_option('--debug', dest='debug', action='store_true',
                          help=optparse.SUPPRESS_HELP, default=False
                         )

        parsed_opts, parsed_args = parser.parse_args(args)
        if parsed_opts.authkey is None:
            if parsed_opts.username is None:
                try:
                    parsed_opts.username = raw_input('Username for Satellite server: ')
                except:
                    raise
            if parsed_opts.password is None:
                try:
                    import getpass
                    parsed_opts.password = getpass.getpass('Password for Satellite server: ')
                except:
                    raise

        return parsed_opts, parsed_args


#==============================================================================
class Sat6Object:
    """ Class for interacting with Satellite 6 API """
    #-- Max number of items returned per page.
    per_page = 100
    lookup_tables = {'lce': 'lut/lce_name.json'}

    def __init__(self, server=None, username=None, password=None,
                 authkey=None, org_id=None, org_name=None):
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        logger.debug('Initiallizing a Sat6_Object.')
        if authkey is None:
            if username is None or password is None:
                raise RuntimeError('Must provide either authkey or username/password pair.')
            try:
                import base64
            except ImportError:
                raise ImportError('The python-base64 module is required.')
            logger.debug('Creating authkey for user: %s', username)
            self.username = username
            self.authkey = base64.b64encode('%s:%s' % (username, password)).strip()
        else:
            self.authkey = authkey
        if server is None:
            raise RuntimeError('Must provide Satellite server name.')
        else:
            self.server = server
        self.url = 'https://%s' % server
        self.pub = '%s/pub' % self.url
        self.foreman = '%s/api/v2' % self.url
        self.katello = '%s/katello/api' % self.url
        self.connection = self._new_connection()
        self.results = {"success": None, "msg": None, "return": None}
        self.lutables = {}
        if org_name is not None:
            self.org_name = org_name
            self.org_id = self.get_org(self.org_name)['id']
        elif org_id is not None:
            self.org_id = org_id
        else:
            self.org_id = 1

    def _get_rest_call(self, url, params=None):
        """ Call a REST API URL using GET.

        Args:
            session_obj (obj): Session object
            url (str):         URL of API
            params (dict):     Dict of params to pass to Requests.get

        Returns:
            Results of API call in a dict

        """
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        try:
            import requests
        except ImportError:
            raise ImportError('The python-requests module is required.')

        logger.debug('Calling URL: %s', url)
        if params is not None:
            logger.debug('With params: %s', params)

        try:
            results = self.connection.get(url, params=params)
            logger.debug('Final URL: %s', results.url)
            rjson = results.json()
        except requests.exceptions.ConnectionError as error:
            logger.debug('Caught Requests Connection Error.')
            error.message = '[ConnectionError]: %s' % (error.message) #: pylint: disable=no-member
            raise error
        except requests.exceptions.HTTPError as error:
            logger.debug('Caught Requests HTTP Error.')
            error.message = '[HTTPError]: %s' % (error.message) #: pylint: disable=no-member
            raise error
        except requests.exceptions.Timeout as error:
            logger.debug('Caught Requests Timeout.')
            error.message = '[Timeout]: %s' % (error.message) #: pylint: disable=no-member
            raise error
        except Exception as error:
            logger.debug('Caught Requests Exception.')
            error.message = '[Requests]: REST call failed: %s' % (error.message) #: pylint: disable=no-member
            raise error

        logger.debug('Results: %s', rjson)

        if rjson.get('error'):
            logger.debug('Requests API call returned error.')
            raise IOError(127, '[Requests]: API call failed: %s' % (rjson['error']['message']))
        return rjson

    def _put_rest_call(self, url, data=None):
        """ Call a REST API URL using PUT .

        Args:
            session_obj (obj): Session object
            url (str):         URL of API
            data (dict):       Dict of data to pass to Requests.put

        Returns:
            Results of API call in a dict

        """
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        try:
            import requests
        except ImportError:
            raise ImportError('The python-requests module is required.')
        try:
            import json
        except ImportError:
            raise ImportError('The python-json module is required.')

        logger.debug('Calling URL: %s', url)
        if data is not None:
            logger.debug('With data: %s', data)

        try:
            results = self.connection.put(url, data=json.dumps(data))
            logger.debug('Final URL: %s', results.url)
            rjson = results.json()
        except requests.exceptions.ConnectionError as error:
            logger.debug('Caught Requests Connection Error.')
            error.message = '[ConnectionError]: %s' % (error.message) #: pylint: disable=no-member
            raise error
        except requests.exceptions.HTTPError as error:
            logger.debug('Caught Requests HTTP Error.')
            error.message = '[HTTPError]: %s' % (error.message) #: pylint: disable=no-member
            raise error
        except requests.exceptions.Timeout as error:
            logger.debug('Caught Requests Timeout.')
            error.message = '[Timeout]: %s' % (error.message) #: pylint: disable=no-member
            raise error
        except Exception as error:
            logger.debug('Caught Requests Exception.')
            error.message = '[Requests]: REST call failed: %s' % (error.message) #: pylint: disable=no-member
            raise error

        logger.debug('Results: %s', rjson)

        if 'error' in rjson:
            logger.debug('Requests API call returned error.')
            raise IOError(127, '[Requests]: API call failed: %s' % (rjson['error']['message']))
        return rjson

    def _new_connection(self, authkey=None):
        """ Create a Request session object

        Args:
            authkey (str): Username

        Returns:
            Requests session object.

        """
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        try:
            import requests
        except ImportError:
            raise ImportError('The python-requests module is required.')
        if authkey is None:
            authkey = self.authkey
        connection = requests.Session()
        connection.headers = {'accept': 'application/json',
                              'authorization': 'Basic %s' % authkey,
                              'content-type': 'application/json'}
        logger.debug('Headers set: %s', connection.headers)
        connection.verify = False
        return connection

    def lookup_lce_name(self, lce_tag):
        """ Searches for and returns LCE from Satellite 6.
            This is a highly-custom routine which depends on a lookup-table
            existing as a static json file in the Satellites pub directory.
            The json file is a simple, manually maintained list of possible
            search phrases mapped to actual LCE names.

        Args:
            lce_tag (str):        Name of LCE find.

        Returns:
            Satellite 6 name of LCE.

        """
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        logger.debug('Looking for lce: %s', lce_tag)

        if 'lce' not in self.lutables:
            logger.debug('First time calling function, loading table.')
            self.lutables['lce'] = self._get_rest_call('%s/%s' % (self.pub, self.lookup_tables['lce']))
        return self.lutables['lce'].get(lce_tag.lower(), None)

    def get_host(self, hostname):
        """ Searches for and returns info for a Satellite 6 host.

        Args:
            hostname (str):        Name of host to find.

        Returns:
            Info for a host (dict). Of particular value may be
            return['certname']
            return['content_facet_attributes']['content_view']['id']
            return['content_facet_attributes']['content_view']['name']
            return['content_facet_attributes']['lifecycle_environment']['id']
            return['content_facet_attributes']['lifecycle_environment']['name']
            return['content_host_id']
            return['id']
            return['subscription_status']
            return['organization_name']
            return['organization_id']

        """
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        logger.debug('Looking for host: %s', hostname)
        if hostname is None:
            logger.debug('Error: hostname passed was type None.')
            return None
        elif isinstance(hostname, int):
            return self._get_rest_call('%s/hosts/%s' % (self.foreman, hostname))

        results = self._get_rest_call('%s/hosts' % (self.foreman),
                                      {'search': '"%s"' % hostname.split('.')[0]})

        if results['subtotal'] == 0:
            logger.debug('Error: No host matches for %s.', hostname.split('.')[0])
            return None
        elif results['subtotal'] > 1:
            logger.debug('Error: Too many host matches for %s.', hostname.split('.')[0])
            return None

        return results['results'][0]

    def get_host_list(self):
        """ This returns a list of Satellite 6 Hosts.

        Returns:
            List of Hosts (dict). Of particular value will be

        """
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        item = 0
        page_item = 0
        page = 1

        results = self._get_rest_call('%s/hosts' % (self.foreman),
                                      {'page': page, 'per_page': self.per_page})
        while item < results['subtotal']:
            if page_item == self.per_page:
                page += 1
                page_item = 0
                results = self._get_rest_call('%s/hosts' % (self.foreman),
                                              {'page': page, 'per_page': self.per_page})
            yield results['results'][page_item]
            item += 1
            page_item += 1

    def get_cv_list(self):
        """ This returns a list of Satellite 6 content views.

        Returns:
            List of Orgs (dict). Of particular value will be

        """
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        item = 0
        page_item = 0
        page = 1

        results = self._get_rest_call('%s/content_views' % (self.katello),
                                      {'page': page, 'per_page': self.per_page})
        while item < results['subtotal']:
            if page_item == self.per_page:
                page += 1
                page_item = 0
                results = self._get_rest_call('%s/content_views' % (self.katello),
                                              {'page': page, 'per_page': self.per_page})
            yield results['results'][page_item]
            item += 1
            page_item += 1

    def get_org(self, organization=None):
        """ Returns info about a Satellite 6 organization.
            If organization is an integer (i.e., self.org_id), will return
            detailed info about that specific org.
            Otherwise will run a search for string passed. If only one result
            is found, will return some very basic info about said org.

        Args:
            organization (str/int): Name of organization to find.

        Returns:
            Basic info of organization (dict). Of particular value may be
            return['name']
            return['id']
            return['title']
            return['label']
            return['description']

        """
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        if organization is None:
            if self.org_id is None:
                organization = self.org_name
            else:
                organization = self.org_id
        logger.debug('Looking for organization: %s', organization)

        if isinstance(organization, int):
            return self._get_rest_call('%s/organizations/%s' % (self.katello, organization))

        results = self._get_rest_call('%s/organizations' % (self.katello),
                                      {'search': '"%s"' % organization})

        if results['subtotal'] == 0:
            logger.debug('Error: No org matches for %s.', organization)
            return None
        elif results['subtotal'] > 1:
            logger.debug('Error: Too many org matches for %s.', organization)
            return None

        return results['results'][0]

    def get_org_list(self):
        """ This returns a list of Satellite 6 organizations.

        Returns:
            List of Orgs (dict). Of particular value will be

        """
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        item = 0
        page_item = 0
        page = 1

        results = self._get_rest_call('%s/organizations' % (self.katello),
                                      {'page': page, 'per_page': self.per_page})
        while item < results['subtotal']:
            if page_item == self.per_page:
                page += 1
                page_item = 0
                results = self._get_rest_call('%s/organizations' % (self.katello),
                                              {'page': page, 'per_page': self.per_page})
            yield results['results'][page_item]
            item += 1
            page_item += 1

    def get_org_lce(self, lce_name, org_id=None):
        """ This returns info about an Lifecycle Environments

        Args:
            lce_name: LCE name to lookup
            org_id:   Organization ID to check

        Returns:
            A dict of info about a LCE

        """
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        if org_id is None:
            org_id = self.org_id
        logger.debug('Looking for Life Cycle Environment %s in org %s.', lce_name, org_id)
        if lce_name is None:
            logger.debug('Error: lce_name passed was type None.')
            return None

        results = self._get_rest_call('%s/organizations/%s/environments' % (self.katello, org_id),
                                      {'search': '"%s"' % lce_name})
        if results['subtotal'] == 0:
            logger.debug('Error: No LCE matches for %s in org %s.', lce_name, org_id)
            return None
        elif results['subtotal'] > 1:
            logger.debug('Error: Too many LCE matches for %s in org %s.', lce_name, org_id)
            return None

        return results['results'][0]

    def get_org_lce_list(self, org_id=None):
        """ This returns a list of an Orgs Lifecycel Environments

        Args:
            org_id:           Organization ID to check

        Returns:
            List of LCEs (dict). Of particular value may be

        """
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        if org_id is None:
            org_id = self.org_id
        logger.debug('Retriveing list of Lifecycle Environments for org_id %s.', org_id)
        item = 0
        page_item = 0
        page = 1

        results = self._get_rest_call('%s/organizations/%s/environments' % (self.katello, org_id),
                                      {'page': page, 'per_page': self.per_page})
        while item < results['subtotal']:
            if page_item == self.per_page:
                page += 1
                page_item = 0
                results = self._get_rest_call('%s/organizations/%s/environments' % (self.katello, org_id),
                                              {'page': page, 'per_page': self.per_page})
            yield results['results'][page_item]
            item += 1
            page_item += 1

    def set_host_lce(self, host, lce):
        """ Set the LifeCycle Environment of a Sat6 host

         Args:
            host:           Host to change
            lce:            New LCE to set

        Returns:
            Status of request. Will set self.results

       """
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        self.results = {"success": None, "msg": None, "return": None}
        if host is None:
            self.results['success'] = False
            self.results['msg'] = 'Passed host is None.'
            return False
        if lce is None:
            self.results['success'] = False
            self.results['msg'] = 'Passed LCE is None.'
            return False

        if 'id' not in host:
            logger.debug('Host does not have ID attribute, attempting lookup for: %s.', host)
            host = self.get_host(host)
            if host is None:
                self.results['success'] = False
                self.results['msg'] = 'Host lookup returned None.'
                return False
        if 'content_facet_attributes' in host:
            if 'id' not in lce:
                logger.debug('LCE does not have ID attribute, attempting lookup for: %s.', lce)
                lce = self.get_org_lce(self.lookup_lce_name(lce))
                if lce is None:
                    self.results['success'] = False
                    self.results['msg'] = 'LCE lookup returned None.'
                    return False
        else:
            self.results['success'] = False
            self.results['msg'] = '%s is not a content host.' % (host['name'])
            return False

        if host['content_facet_attributes']['lifecycle_environment']['id'] == lce['id']:
            self.results['return'] = host
            self.results['success'] = True
            self.results['msg'] = 'LCE was already %s, no change needed.' % (lce['name'])
            return True

        results = self._put_rest_call('%s/hosts/%s' % (self.foreman, host['id']),
                                      {'host': {'content_facet_attributes':
                                                    {'lifecycle_environment_id': lce['id']}
                                               }}
                                     )
        if results['content_facet_attributes']['lifecycle_environment']['id'] == lce['id']:
            self.results['return'] = results
            self.results['success'] = True
            self.results['msg'] = 'LCE changed to %s.' % (lce['name'])
            return True

        self.results['return'] = results
        self.results['success'] = False
        self.results['msg'] = 'LCE not set, cause unknown.'
        return False

#==============================================================================
def main():
    """ This is where the action takes place """
    logger.debug('Starting main()')
    sat6_session = Sat6Object(server=options.server, username=options.username,
                              password=options.password, authkey=options.authkey,
                              org_id=options.org_id, org_name=options.org_name)

    if options.lifecycle:
        print(sat6_session.lookup_lce_name(options.lifecycle))
    print('-------------------')

    my_host = sat6_session.get_host(options.hostname)
    if my_host:
        print('Host ID:           %s' % my_host['id'])
        print('Host Org Name:     %s' % my_host['organization_name'])
        print('Host Org ID:       %s' % my_host['organization_id'])
        if 'content_facet_attributes' in my_host:
            print('Host Lifecycle:    %s' % my_host['content_facet_attributes']['lifecycle_environment']['name'])
            print('Host Lifecycle ID: %s' % my_host['content_facet_attributes']['lifecycle_environment']['id'])
            print('Host Content View: %s' % my_host['content_facet_attributes']['content_view']['name'])
    else:
        print('Warning: No host matches for %s.' % options.hostname)
    print('-------------------')

    if options.lifecycle:
        if sat6_session.set_host_lce(my_host, options.lifecycle):
            print('LCE set for %s (%s)' % (my_host['name'], sat6_session.results['msg']))
            my_host = sat6_session.results['return']
        else:
            print('LCE *not* set for %s (%s)' % (my_host['name'], sat6_session.results['msg']))
    else:
        print('No LCE provided.')
    print('host LCE now: %s' % my_host['content_facet_attributes']['lifecycle_environment']['name'])
    print('-------------------')

    for host in sat6_session.get_host_list():
        if 'content_facet_attributes' in host:
            print("Host ID: %s  Name: %s  LCE: %s" % (host['id'], host['name'], host['content_facet_attributes']['lifecycle_environment']['name']))
        else:
            print("Host ID: %s  Name: %s" % (host['id'], host['name']))
    print('host LCE now: %s' % my_host['content_facet_attributes']['lifecycle_environment']['name'])
    print('-------------------')

    my_org = sat6_session.get_org()
    print('Org ID:            %s' % my_org['id'])
    print('Org Label:         %s' % my_org['label'])
    print('-------------------')

    for cview in sat6_session.get_cv_list():
        print("CV ID: %s  Name: %s  Label: %s" % (cview['id'], cview['name'], cview['label']))
    print('-------------------')

    for org in sat6_session.get_org_list():
        print("Org ID: %s  Name: %s  Label: %s" % (org['id'], org['name'], org['label']))
    print('-------------------')

    lce_check = 'Incoming'
    my_lce = sat6_session.get_org_lce(lce_check)
    if my_lce:
        print('LCE ID:            %s' % my_lce['id'])
        print('LCE Name:          %s' % my_lce['name'])
    else:
        print('Warning: LCE %s unknown.' % lce_check)
    print('-------------------')

    for lce in sat6_session.get_org_lce_list():
        print("LCE ID: %s  Name: %s  Label: %s" % (lce['id'], lce['name'], lce['label']))
    print('-------------------')

#==============================================================================
if __name__ == '__main__':
    #-- Setting up logger here so we can use them in even of exceptions.
    #   Parsing options here as we need them to setup the logger.
    options = CLIOptions(sys.argv[1:])
    logger = CLILogger(options)

    if __require_root__ and os.getegid() != 0:
        logger.error('Must be run as root.')
        sys.exit(77)

   #-- This will disable insecure https warnings (amongst others)
    logging.captureWarnings(True)

    try:
        main()
    except KeyboardInterrupt: # Catches Ctrl-C
        logger.debug('Caught Ctrl-C')
        EXIT_STATUS = 130
    except SystemExit as error: # Catches sys.exit()
        logger.debug('Caught SystemExit')
        logger.warning('%s: [SystemExit] %s', __basename__, error.strerror)
        if error.errno is None:
            EXIT_STATUS = 10
        else:
            EXIT_STATUS = error.errno
    #-- NOTE: "except Exception as variable:" syntax was added in 2.6
    except IOError as error:
        logger.debug('Caught IOError')
        if error.errno is None:
            logger.critical('%s: [IOError]: %s', __basename__, error.message)
            EXIT_STATUS = 10
        elif error.errno == 2:                #: No such file/directory
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
        logger.debug('Caught OSError')
        if error.errno == 2:                #: No such file/directory
            logger.critical('%s: [OSError] %s: %s', __basename__,
                            error.strerror, error.filename
                           )
            EXIT_STATUS = os.EX_UNAVAILABLE
        else:
            logger.critical('%s: [OSError] %s', __basename__, error.strerror)
            EXIT_STATUS = error.errno
    except Exception as error:
        logger.debug('Caught Exception')
        logger.critical('%s: %s' % (__basename__, error))
        EXIT_STATUS = 10
    else:
        logger.debug('main() exited cleanly.')
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
