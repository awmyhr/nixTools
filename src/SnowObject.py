#!/usr/bin/python2 -tt
# -*- coding: utf-8 -*-
''' Class for working with ServiceNow '''
#==============================================================================
import os           #: Misc. OS interfaces
import sys          #: System-specific parameters & functions
#==============================================================================
class SnowObject(object):
    ''' Class for interacting with ServiceNow API '''
    __version = '1.4.0'

    def __init__(self, server=None, username=None, password=None, authkey=None,
                 client_id=None, insecure=False, basepath=None):
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        logger.debug('Initiallizing SnowObject version %s.', self.__version)
        if authkey is None:
            if username is None or password is None:
                raise RuntimeError('Must provide either authkey or username/password pair.')
            logger.debug('Creating authkey for user: %s', username)
            self.username = username
            self.authkey = base64.b64encode('%s:%s' % (username, password)).strip()
        else:
            self.authkey = authkey
        if client_id is None:
            raise RuntimeError('Must provide API Client ID.')
        self.client_id = client_id
        if server is None:
            raise RuntimeError('Must provide API server name.')
        self.server = server
        self.insecure = insecure
        self.url = 'https://%s/%s' % (self.server, basepath)
        self.compinsts = '%s/itsm-compute/compute/instances' % self.url
        self.token_url = '%s/authorization/token' % self.url
        self.token_file = '%s/.%s-%s' % (tempfile.gettempdir(),
                                         os.getenv('USER'),
                                         self.client_id.split("-")[0])
        self.util = UtilityClass(authkey=authkey, insecure=insecure,
                                 cookiefile=os.getenv("HOME") + "/.sat6_api_session")
        self.connection = self._new_connection(client_id=self.client_id)
        self.token = self._get_token()
        self.connection = self._new_connection(token=self.token,
                                               client_id=self.client_id)
        self.results = {"success": None, "msg": None, "return": None, "entries": 0, "list": None}

    def __del__(self):
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        logger.debug('Saving token file: %s.', self.token_file)
        with open(self.token_file, 'w') as file_:
            json.dump(self.token, file_)

    def _get_token(self):
        ''' Retrive a Bearer token

        Returns:
            Token as a dict

        '''
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        try:
            logger.debug('Attempting to load token file: %s.', self.token_file)
            with open(self.token_file, 'r') as file_:
                token = json.load(file_)
            if 'expires' not in token or int(time.time()) > int(token['expires']):
                logger.debug('Token file invalid or expired, getting new token.')
                logger.debug('Time: %s ; Token Exp: %s', int(time.time()), int(token['expires']))
                logger.debug('Token: %s', token)
                token = self._get_rest_call(self.token_url)
        except (IOError, AttributeError, TypeError, ValueError):
            logger.debug('Error with token file, requesting new token.')
            token = self._get_rest_call(self.token_url)
        if 'access_token' not in token:
            raise RuntimeError('Error: No access token. Only found: %s' % token)
        return token

    def _get_rest_call(self, url, params=None, data=None):
        ''' Call a REST API URL using GET.

        Args:
            url (str):       URL of API to call
            params (dict):   Dict of params to pass to Requests.get
            data (dict):     Dict of data to pass to Requests.get

        Returns:
            Results of API call in a dict

        '''
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access

        logger.debug('Calling URL: %s', url)
        logger.debug('With Headers: %s', self.connection.headers)
        if params is not None:
            logger.debug('With params: %s', params)
        if data is not None:
            logger.debug('With data: %s', data)
            data = json.dumps(data)

        try:
            results = self.connection.get(url, params=params, data=data)
            logger.debug('Final URL: %s', results.url)
            logger.debug('Return Headers: %s', results.headers)
            logger.debug('%s: %s', results.status_code, results.raw)
        except requests.ConnectionError as error:
            logger.debug('Caught Requests Connection Error.')
            error.message = '[ConnectionError]: %s' % (error.message) #: pylint: disable=no-member
            raise error
        except requests.HTTPError as error:
            logger.debug('Caught Requests HTTP Error.')
            error.message = '[HTTPError]: %s' % (error.message) #: pylint: disable=no-member
            raise error
        except requests.Timeout as error:
            logger.debug('Caught Requests Timeout.')
            error.message = '[Timeout]: %s' % (error.message) #: pylint: disable=no-member
            raise error
        except Exception as error:
            logger.debug('Caught Requests Exception.')
            error.message = '[Requests]: REST call failed: %s' % (error.message) #: pylint: disable=no-member
            raise error
        results.raise_for_status()

        rjson = results.json()
        logger.debug('Results: %s', rjson)

        if rjson.get('error'):
            logger.debug('Requests API call returned error.')
            raise IOError(127, '[Requests]: API call failed: %s' % (rjson['error']['message']))
        return rjson

    def _new_connection(self, authkey=None, insecure=None, token=None, client_id=None):
        ''' Create a Request session object

        Args:
            authkey (str):   User authorization key
            insecure (bool): If True do not validate SSL
            token (dict):    User token as a dict, need 'access_token'
            client_id (str): User client ID for controlled API access

        Returns:
            Requests session object.

        '''
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        connection = requests.Session()
        connection.headers = {
            'content-type': 'application/json',
            'accept': 'application/json',
            'cache-control': 'no-cache'
        }
        if token is None:
            if authkey is None:
                authkey = self.authkey
            connection.headers['authorization'] = 'Basic %s' % authkey
        else:
            connection.headers['authorization'] = 'Bearer %s' % token['access_token']
        if client_id is not None:
            connection.headers['x-ibm-client-id'] = client_id
        logger.debug('Headers set: %s', connection.headers)
        if insecure is None:
            connection.verify = not bool(self.insecure)
        else:
            connection.verify = not bool(insecure)

        return connection

    def is_valid_ipv4(self, ipaddr):
        '''Checks if passed paramater is a valid IPv4 address'''
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        parts = ipaddr.split('.')
        if len(parts) != 4:
            return False
        try:
            return all(0 <= int(p) < 256 for p in parts)
        except ValueError:
            return False

    def get_host(self, hostname, rels=False):
        ''' Return SNOW info on a specific host

        Args:
            hostname (str):  Name of host to find.

        Returns:
            Info for a host (dict). Of particular value may be
            return['certname']
            return['ciFunction']
            return['environment']
            return['lifecycleStatus']

        '''
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        logger.debug('Looking for host: %s', hostname)
        self.results = {"success": None, "msg": None, "return": None, "entries": 0, "list": None}

        if hostname is None:
            self.results['success'] = False
            self.results['msg'] = 'Hostname passed was type None.'
            self.results['return'] = None
            logger.debug('Error: %s', self.results['msg'])
        else:
            if self.is_valid_ipv4(hostname):
                field = 'ipAddress'
            else:
                hostname = hostname.upper().split(".")[0]
                field = 'name'
            req_results = self._get_rest_call(self.compinsts, {field: hostname})
            if req_results['total'] == 0:
                self.results['success'] = False
                self.results['msg'] = 'No host matches for %s.' % hostname
                self.results['entries'] = 0
                self.results['return'] = None
                logger.debug('Error: %s', self.results['msg'])
            else:
                if rels:
                    count = 0
                    for item in req_results['items']:
                        req_results['items'][count]['relations'] = self.get_host_relations(item['id'])
                        req_results['items'][count]['costCenter'] = next((entry['parent'] for entry in req_results['items'][count]['relations'] if entry['type'] == "Expensed by::Expensed to"), None)
                        req_results['items'][count]['registeredOn'] = next((entry['child'] for entry in req_results['items'][count]['relations'] if entry['type'] == "Registered on::Has registered"), None)
                        req_results['items'][count]['hostedOn'] = next((entry['child'] for entry in req_results['items'][count]['relations'] if entry['type'] == "Hosted on::Hosts"), None)
                        count += 1
                if req_results['total'] > 1:
                    req_results['items'] = sorted(req_results['items'], key=lambda i: i['id'])
                    self.results['success'] = False
                    self.results['msg'] = 'Too many host matches for %s (%s).' % (hostname, req_results['total'])
                    self.results['entries'] = req_results['total']
                    self.results['list'] = req_results['items']
                    self.results['return'] = None
                    logger.debug('Error: %s', self.results['msg'])
                else:
                    self.results['success'] = True
                    self.results['msg'] = 'Found %s.' % hostname
                    self.results['entries'] = 1
                    self.results['list'] = req_results['items']
                    self.results['return'] = req_results['items'][0]
                    logger.debug('Success: %s', self.results['msg'])
        return self.results['return']


    def get_host_relations(self, hostid):
        ''' Return SNOW info on a specific host

        Args:
            hostname (str):  Name of host to find.

        Returns:
            Info for a host (dict). Of particular value may be
            return['certname']
            return['ciFunction']
            return['environment']
            return['lifecycleStatus']

        '''
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        logger.debug('Looking for host: %s', hostid)
        self.results = {"success": None, "msg": None, "return": None, "entries": 0, "list": None}

        if hostid is None:
            self.results['success'] = False
            self.results['msg'] = 'Host ID passed was type None.'
            self.results['return'] = None
            logger.debug('Error: %s', self.results['msg'])
        else:
            req_results = self._get_rest_call('%s/%s/relationships' % (self.compinsts, hostid))
            self.results['return'] = req_results['items']
            self.results['entries'] = req_results['total']
            if self.results['return'] is None:
                self.results['success'] = False
            else:
                self.results['success'] = True
        return self.results['return']


