#!/usr/bin/python2 -tt
# -*- coding: utf-8 -*-
#==============================================================================
import sys          #: System-specific parameters & functions
try:
    import base64
except ImportError:
    raise ImportError('The python-base64 module is required.')
try:
    import requests
except ImportError:
    raise ImportError('The python-requests module is required.')
try:
    import json
except ImportError:
    raise ImportError('The python-json module is required.')
try:
    from urllib import urlencode
except ImportError:
    raise ImportError('The python-urllib module is required.')
try:
    from cookielib import LWPCookieJar
except ImportError:
    raise ImportError('The python-cookielib module is required.')
#==============================================================================
class UtilityClass(object):
    ''' Class for interacting with Satellite 6 API '''
    __version = '1.5.0'

    per_page = 100

    def __init__(self, server=None, authkey=None, insecure=False,
                 token=None, client_id=None, cookiefile=None):
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        logger.debug('Initiallizing UtilityClass version %s.', self.__version)
        logger.debug(locals())
        if token is not None:
            authorization = 'Bearer %s' % token['access_token']
        else:
            if authkey is None:
                raise RuntimeError('authkey not provided.')
            authorization = 'Basic %s' % authkey
        self.connection = requests.Session()
        self.connection.headers = {
            'x-ibm-client-id': client_id,
            'content-type': 'application/json',
            'authorization': authorization,
            'accept': 'application/json',
            'cache-control': 'no-cache'
        }
        logger.debug('Headers set: %s', self.connection.headers)
        self.connection.verify = not bool(insecure)
        self.cookiefile = cookiefile
        if cookiefile is not None:
            self.connection.cookies = LWPCookieJar(cookiefile)
            try:
                self.connection.cookies.load(ignore_discard=True)
            except IOError:
                pass
        self.verbose = False
        self.results = {"success": None, "msg": None, "return": None}

    def __del__(self):
        if self.cookiefile is not None:
            try:
                self.connection.cookies.save(ignore_discard=True)
            except IOError:
                pass

    #===============================================================================
    #-- The following originates from a  StackOverflow thread titled
    #   "Check if a string matches an IP address pattern in Python".
    #   We are only interested in valid IPv4 addresses.
    #===============================================================================
    # https://stackoverflow.com/questions/3462784/check-if-a-string-matches-an-ip-address-pattern-in-python
    #===============================================================================
    @classmethod
    def is_valid_ipv4(cls, ipaddr):
        '''Checks if passed paramater is a valid IPv4 address'''
        parts = ipaddr.split('.')
        if len(parts) != 4:
            return False
        try:
            return all(0 <= int(p) < 256 for p in parts)
        except ValueError:
            return False

    @classmethod
    def get_authkey(cls, username, password):
        '''Return base64 encoded username/password'''
        return  base64.b64encode('%s:%s' % (username, password)).strip()

    # def _get_cookies(self):
    #     ''' Handle session cookie '''
    #     logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
    #     self.cookies = LWPCookieJar(os.getenv("HOME") + "/.sat6_api_session")
    #     try:
    #         self.cookies.load(ignore_discard=True)
    #     except IOError:
    #         pass
    #     return self.cookies

    def rest_call(self, method, url, params=None, data=None, jsonin=None):
        ''' Call a REST API URL using method.

        Args:
            session_obj (obj): Session object
            method (str):      One of: get, put, post
            url (str):         URL of API
            params (dict):     Dict of params to pass to Requests.get

        Returns:
            Results of API call in a dict

        '''
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        results = {"success": None, "msg": None, "return": None}

        logger.debug('Calling URL: %s', url)
        logger.debug('Using method: %s', method)
        logger.debug('With Headers: %s', self.connection.headers)
        if params is not None:
            logger.debug('With params: %s', params)
        if jsonin is not None:
            logger.debug('With json: %s', jsonin)
        if data is not None:
            logger.debug('With data: %s', data)
            data = json.dumps(data)

        try:
            req_results = self.connection.request(method, url, params=params, data=data, json=jsonin)
            logger.debug('Final URL: %s', req_results.url)
            logger.debug('Return Headers: %s', req_results.headers)
            logger.debug('Status Code: %s', req_results.status_code)
            logger.debug('Results: %s', req_results.content)
            rjson = req_results.json()
            if not req_results.ok:
                if self.verbose:
                    logger.debug('Results: %s', rjson)
                if 'error' in rjson:
                    logger.debug('Requests API call returned error.')
                    if 'full_messages' in rjson['error']:
                        logger.error('\n'.join(rjson['error']['full_messages']))
                    else:
                        logger.error('Sorry, no further info, try --debug.')
                elif 'displayMessage' in rjson:
                    logger.debug(rjson['displayMessage'])
                    logger.error('Sorry, no useful info, try --debug.')
                else:
                    logger.error('Sorry, no error info, try --debug.')
            req_results.raise_for_status()
            results['success'] = True
            results['return'] = rjson
        except requests.exceptions.HTTPError as error:
            logger.debug('Caught Requests HTTP Error.')
            results['msg'] = '[HTTPError]: %s' % (error.message) #: pylint: disable=no-member
        except requests.exceptions.ConnectionError as error:
            logger.debug('Caught Requests Connection Error.')
            results['msg'] = '[ConnectionError]: %s' % (error.message) #: pylint: disable=no-member
        except requests.exceptions.Timeout as error:
            logger.debug('Caught Requests Timeout.')
            results['msg'] = '[Timeout]: %s' % (error.message) #: pylint: disable=no-member
        except requests.exceptions.RequestException as error:
            logger.debug('Caught Requests Exception.')
            results['msg'] = '[Requests]: REST call failed: %s' % (error.message) #: pylint: disable=no-member

        logger.debug('rest_call: %s', results['msg'])
        return results

    def find_item(self, url, search=None, field='name'):
        ''' Searches for and returns info for a Satellite 6 host.

        Args:
            hostname (str):        Name of host to find.

        Returns:

        '''
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        results = {"success": False, "msg": None, "return": None}

        if url is None:
            results['msg'] = 'Error: No url passed.'
        else:
            search_str = '%s~"%s"' % (field, search)

            results = self.rest_call('get', url,
                                      urlencode([('search', '' + str(search_str))]))
            if results['return']['subtotal'] == 0:
                results['success'] = False
                results['msg'] = 'Warning: No matches for %s.' % search
            elif results['return']['subtotal'] > 1:
                results['success'] = False
                results['msg'] = 'Warning: Too many matches for %s (%s).' % (search, results['total'])
            else:
                results['success'] = True
                results['msg'] = 'Success: %s found.' % search
                results['return'] = results['return']['results'][0]

        logger.debug('find_item: %s', results['msg'])
        return results

    def get_item(self, url, label):
        ''' Searches for and returns info for a Satellite 6 host.

        Args:
            url (str):        url to hit.

        Returns:

        '''
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        results = {"success": False, "msg": None, "return": None}

        if url is None:
            results['msg'] = 'Error: No url passed.'
        else:
            results = self.rest_call('get', url)
            if 'error' in results['return']:
                #-- This is not likely to execute, as if the host ID is not
                #   found a 404 is thrown, which is caught by the exception
                #   handling mechanism, and the program will bomb out.
                #   Not sure I want to change that...
                results['success'] = False
                results['msg'] = 'Warning: %s not found.' % label
            else:
                results['success'] = True
                results['msg'] = 'Success: %s found.' % label

        logger.debug('get_item: %s', results['msg'])
        return results

    def get_list(self, url, search=None, field='name', per_page=None, params=None):
        ''' This returns a list of Satellite 6 Hosts.

        Returns:
            List of Hosts (dict). Of particular value will be

        '''
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        if per_page is None:
            per_page = self.per_page
        if params is None:
            params = {'page': 1, 'per_page': per_page}
        else:
            params['page'] = 1
            params['per_page'] = per_page
        if search is not None:
            if any(symbol in search for symbol in '=~!^'):
                params['search'] = search
            else:
                params['search'] = '%s~"%s"' % (field, search)
        item = 0
        page_item = 0

        results = self.rest_call('get', url, params)
        while item < results['return']['subtotal']:
            if page_item == per_page:
                params['page'] += 1
                page_item = 0
                results = self.rest_call('get', url, params)
            yield results['return']['results'][page_item]
            item += 1
            page_item += 1

