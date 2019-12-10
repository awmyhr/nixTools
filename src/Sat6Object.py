#!/usr/bin/python2 -tt
# pylint: disable=too-many-lines
''' Class for working with Satellite 6.x '''
#==============================================================================
import os           #: Misc. OS interfaces
import sys          #: System-specific parameters & functions
import UtilityClass
#==============================================================================
class Sat6Object(object):
    ''' Class for interacting with Satellite 6 API '''
    __version = '2.4.0'
    #-- Max number of items returned per page.
    #   Though we allow this to be configured, KB articles say 100 is the
    #   optimal value to avoid timeouts.
    per_page = 100
    lookup_tables = {'lce': 'lut/lce_name.json'}

    def __init__(self, server=None, authkey=None,
                 org_id=None, org_name=None, insecure=False):
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        logger.debug('Initiallizing Sat6Object version %s.', self.__version)
        if server is None:
            raise RuntimeError('Must provide Satellite server name.')
        self.server = server
        self.url = 'https://%s' % server
        self.pub = '%s/pub' % self.url
        self.foreman = '%s/api/v2' % self.url
        self.katello = '%s/katello/api/v2' % self.url
        # self.kcert = '/etc/rhsm/ca/katello-server-ca.pem'
        self.util = UtilityClass(authkey=authkey, insecure=insecure,
                                 cookiefile=os.getenv("HOME") + "/.sat6_api_session")
        self.results = {"success": None, "msg": None, "return": None}
        self.lutables = {}
        self.verbose = False
        if org_name is not None:
            self.org_name = org_name
            self.org_id = self.get_org(self.org_name)['id']
        elif org_id is not None:
            self.org_id = org_id
        else:
            self.org_id = 1

    def lookup_lce_name(self, lce_tag):
        ''' Searches for and returns LCE from Satellite 6.
            This is a highly-custom routine which depends on a lookup-table
            existing as a static json file in the Satellites pub directory.
            The json file is a simple, manually maintained list of possible
            search phrases mapped to actual LCE names.

        Args:
            lce_tag (str):        Name of LCE find.

        Returns:
            Satellite 6 name of LCE.

        '''
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        logger.debug('Looking for lce: %s', lce_tag)

        if 'lce' not in self.lutables:
            logger.debug('First time calling function, loading table.')
            results = self.util.rest_call('get', '%s/%s' % (self.pub,
                                          self.lookup_tables['lce']))
            if results['success']:
                self.lutables['lce'] = results['return']
                if '_revision' in self.lutables['lce']:
                    logger.debug('LCE Table revision: %s', self.lutables['lce']['_revision'])
                else:
                    logger.debug('Warning: LCE Table did not have _revision tag.')
            else:
                self.lutables['lce'] = None
        if self.lutables['lce']:
            return self.lutables['lce'].get(lce_tag.lower(), None)
        return None

    def get_host(self, hostname=None):
        ''' Searches for and returns info for a Satellite 6 host.

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

        '''
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        self.results = {"success": False, "msg": None, "return": None}

        if hostname is None:
            self.results['msg'] = 'Error: Hostname passed was type None.'
        else:
            logger.debug('Looking for host: %s', hostname)

            if not isinstance(hostname, int):
                if not self.util.is_valid_ipv4(hostname):
                    hostname = hostname.split('.')[0]
                self.results = self.util.find_item('%s/hosts' % (self.foreman), hostname)
                if self.results['success']:
                    hostname = self.results['return']['id']
                else:
                    logger.debug('find unsuccessful: %s', self.results)
                    hostname = None
            if hostname is not None:
                self.results = self.util.get_item('%s/hosts/%s' % (self.foreman, hostname), 'host_id %s' % hostname)

        logger.debug('get_host: %s', self.results['msg'])
        if self.results['success']:
            return self.results['return']
        return None

    def get_host_subs(self, hostname=None):
        ''' comment
        '''
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        self.results = {"success": False, "msg": None, "return": None}

        # if hostname is None:
        #     self.results['msg'] = 'Error: Hostname passed was type None.'
        # else:
        #     logger.debug('Looking for host: %s', hostname)

        #     if not isinstance(hostname, int):
        #         if not self.util.is_valid_ipv4(hostname):
        #             hostname = hostname.split('.')[0]
        #         self.results = self.util.find_item('%s/hosts' % (self.foreman), hostname)
        #         if self.results['success']:
        #             hostname = self.results['return']['id']
        #         else:
        #             logger.debug('find unsuccessful: %s', self.results)
        #             hostname = None
        return self.util.get_list('%s/hosts/%s/subscriptions' % (self.foreman, hostname))

    def get_host_errata(self, host=None, applicable=False):
        ''' comment
        '''
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        self.results = {"success": False, "msg": None, "return": None}

        host = self.get_host(host)
        if 'content_facet_attributes' in host:
            if applicable:
                env_id = 1
            else:
                env_id = host['content_facet_attributes']['lifecycle_environment_id']
            params = {'environment_id': env_id,
                      'content_view_id': host['content_facet_attributes']['content_view_id']}
        else:
            params = None
        return self.util.get_list('%s/hosts/%s/errata' % (self.foreman, host['id']), params=params)

    def get_host_list(self, search=None, field='name'):
        ''' This returns a list of Satellite 6 Hosts.

        Returns:
            List of Hosts (dict). Of particular value will be

        '''
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access

        return self.util.get_list('%s/hosts' % (self.foreman), search=search, field=field)

    def get_cv(self, cview=None):
        ''' Returns info about a Satellite 6 content view.
            If content view is an integer (i.e., self.org_id), will return
            detailed info about that specific org.
            Otherwise will run a search for string passed. If only one result
            is found, will return some very basic info about said org.

        Args:
            content view (str/int): Name of content view to find.

        Returns:
            Basic info of content view (dict). Of particular value may be
            return['name']
            return['id']
            return['title']
            return['label']
            return['description']

        '''
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        self.results = {"success": False, "msg": None, "return": None}

        if cview is None:
            self.results['msg'] = 'Error: cview passed was type None.'
        else:
            logger.debug('Looking for cview: %s', cview)

            if not isinstance(cview, int):
                self.results = self.util.find_item('%s/content_views/' % (self.katello), cview)
                if self.results['success']:
                    cview = self.results['return']['id']
                else:
                    logger.debug('find unsuccessful: %s', self.results)
                    cview = None
            if cview is not None:
                self.results = self.util.get_item('%s/content_views/%s' % (self.katello, cview), 'cview_id %s' % cview)

        logger.debug('get_cv: %s', self.results['msg'])
        if self.results['success']:
            return self.results['return']
        return None

    def get_cv_list(self, search=None, field='name'):
        ''' This returns a list of Satellite 6 content views.

        Returns:
            List of Content Views (dict). Of particular value will be

        '''
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access

        return self.util.get_list('%s/content_views' % (self.katello), search=search, field=field)

    def get_hc(self, collection=None):
        ''' Returns info about a Satellite 6 collection.
            If collection is an integer (i.e., self.org_id), will return
            detailed info about that specific org.
            Otherwise will run a search for string passed. If only one result
            is found, will return some very basic info about said org.

        Args:
            collection (str/int): Name of collection to find.

        Returns:
            Basic info of collection (dict). Of particular value may be
            return['name']
            return['id']
            return['title']
            return['label']
            return['description']

        '''
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        self.results = {"success": False, "msg": None, "return": None}

        if collection is None:
            self.results['msg'] = 'Error: collection passed was type None.'
        else:
            logger.debug('Looking for collection: %s', collection)

            if not isinstance(collection, int):
                self.results = self.util.find_item('%s/organizations/%s/host_collections/' % (self.katello, self.org_id), collection)
                if self.results['success']:
                    collection = self.results['return']['id']
                else:
                    logger.debug('find unsuccessful: %s', self.results)
                    collection = None
            if collection is not None:
                self.results = self.util.get_item('%s/host_collections/%s' % (self.katello, collection), 'collection_id %s' % collection)

        logger.debug('get_hc: %s', self.results['msg'])
        if self.results['success']:
            return self.results['return']
        return None

    def get_hc_list(self, search=None, field='name', org_id=None):
        ''' This returns a list of Satellite 6 content views.

        Returns:
            List of Host Collections (dict). Of particular value will be

        '''
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        if org_id is None:
            org_id = self.org_id

        return self.util.get_list('%s/organizations/%s/host_collections' % (self.katello, org_id), search=search, field=field)

    def create_hc(self, collection):
        ''' Creates a host collection in the default organization

        Args:
            collection (str): Name of collection to create

        Returns:
            Basic info of collection created
        '''
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        self.results = {"success": False, "msg": None, "return": None}

        if collection is None:
            self.results['msg'] = 'Error: Was not given collection to create.'
            return None
        logger.debug('Creating collection: %s', collection)

        check = self.get_hc(collection)
        if check:
            self.results['success'] = True
            self.results['msg'] = 'Collection %s exists, nothing to do.' % (collection)
            self.results['return'] = check
            return True

        self.results = self.util.rest_call('post', '%s/organizations/%s/host_collections' % (self.katello, self.org_id),
                                  data={'organization_id': self.org_id, 'name': collection}
                                 )
        if self.results['return']['id']:
            self.results['success'] = True
            self.results['msg'] = 'Collection %s created.' % (collection)
            return True
        self.results['success'] = False
        self.results['msg'] = 'Unable to create collection, reason unknown.'
        return False

    def get_org(self, organization=None):
        ''' Returns info about a Satellite 6 organization.
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

        '''
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        self.results = {"success": False, "msg": None, "return": None}

        if organization is None:
            self.results['msg'] = 'Error: organization passed was type None.'
        else:
            logger.debug('Looking for organization: %s', organization)

            if not isinstance(organization, int):
                self.results = self.util.find_item('%s/organizations' % (self.katello), organization)
                if self.results['success']:
                    organization = self.results['return']['id']
                else:
                    logger.debug('find unsuccessful: %s', self.results)
                    organization = None
            if organization is not None:
                self.results = self.util.get_item('%s/organizations/%s' % (self.katello, organization), 'org_id %s' % organization)

        logger.debug('get_org: %s', self.results['msg'])
        if self.results['success']:
            return self.results['return']
        return None

    def get_org_list(self, search=None, field='name'):
        ''' This returns a list of Satellite 6 organizations.

        Returns:
            List of Orgs (dict). Of particular value will be

        '''
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access

        return self.util.get_list('%s/organizations' % (self.katello), search=search, field=field)

    def get_org_lce(self, lce_name, org_id=None):
        ''' This returns info about an Lifecycle Environments

        Args:
            lce_name: LCE name to lookup
            org_id:   Organization ID to check

        Returns:
            A dict of info about a LCE

        '''
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        if org_id is None:
            org_id = self.org_id
        self.results = {"success": False, "msg": None, "return": None}

        if lce_name is None:
            self.results['msg'] = 'Error: lce_name passed was type None.'
        else:
            logger.debug('Looking for Life Cycle Environment %s in org %s.', lce_name, org_id)

            if not isinstance(lce_name, int):
                self.results = self.util.find_item('%s/organizations/%s/environments' % (self.katello, org_id), lce_name)
                if self.results['success']:
                    lce_name = self.results['return']['id']
                else:
                    logger.debug('find unsuccessful: %s', self.results)
                    lce_name = None
            if lce_name is not None:
                self.results = self.util.get_item('%s/organizations/%s/environments/%s' % (self.katello, org_id, lce_name), 'lce_id %s' % lce_name)

        logger.debug(self.results['msg'])
        if self.results['success']:
            return self.results['return']
        return None

    def get_org_lce_list(self, search=None, field='name', org_id=None):
        ''' This returns a list of an Orgs Lifecycel Environments

        Args:
            org_id:           Organization ID to check

        Returns:
            List of LCEs (dict). Of particular value may be

        '''
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        if org_id is None:
            org_id = self.org_id
        logger.debug('Retriveing list of Lifecycle Environments for org_id %s.', org_id)
        return self.util.get_list('%s/organizations/%s/environments' % (self.katello, org_id), search=search, field=field)

    def get_loc(self, location=None):
        ''' Returns info about a Satellite 6 location.
            If location is an integer (i.e., self.org_id), will return
            detailed info about that specific org.
            Otherwise will run a search for string passed. If only one result
            is found, will return some very basic info about said org.

        Args:
            location (str/int): Name of location to find.

        Returns:
            Basic info of location (dict). Of particular value may be
            return['name']
            return['id']
            return['title']
            return['label']
            return['description']

        '''
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        self.results = {"success": False, "msg": None, "return": None}

        if location is None:
            self.results['msg'] = 'Error: location passed was type None.'
        else:
            logger.debug('Looking for location: %s', location)

            if not isinstance(location, int):
                if '/' in location:
                    field = 'title'
                else:
                    field = 'name'

                self.results = self.util.find_item('%s/locations/' % (self.foreman), location, field)
                if self.results['success']:
                    location = self.results['return']['id']
                else:
                    logger.debug('find unsuccessful: %s', self.results)
                    location = None
            if location is not None:
                self.results = self.util.get_item('%s/locations/%s' % (self.foreman, location), 'loc_id %s' % location)

        logger.debug(self.results['msg'])
        if self.results['success']:
            return self.results['return']
        return None

    def get_loc_list(self, search=None, field='name'):
        ''' This returns a list of Satellite 6 locations.

        Returns:
            List of locations (dict). Of particular value will be

        '''
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access

        return self.util.get_list('%s/locations' % (self.foreman), search=search, field=field)

    def set_host_cv(self, host=None, cview=None):
        ''' Set the Content View of a Sat6 host

         Args:
            host:           Host to change
            cview:          New CView to set

        Returns:
            Status of request. Will set self.results

       '''
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        self.results = {"success": None, "msg": None, "return": None}

        if host is None:
            self.results['success'] = False
            self.results['msg'] = 'Passed host is None.'
        elif 'id' not in host:
            logger.debug('Host does not have ID attribute, attempting lookup for: %s.', host)
            host = self.get_host(host)
        #-- We rely on the fact that get_host will set self.results appropriately
        if self.results['success'] is False:
            logger.debug('set_host_cv: %s', self.results['msg'])
            return False
        elif 'content_facet_attributes' not in host:
            self.results['success'] = False
            self.results['msg'] = '%s is not a content host.' % (host['name'])
            return False

        if cview is None:
            self.results['success'] = False
            self.results['msg'] = 'Passed CView is None.'
        elif 'id' not in cview:
            logger.debug('CView does not have ID attribute, attempting lookup for: %s.', cview)
            cview = self.get_cv(cview)
        #-- We rely on the fact that get_cv will set self.results appropriately
        if self.results['success'] is False:
            logger.debug('set_host_cv: %s', self.results['msg'])
            return False

        if host['content_facet_attributes']['content_view']['id'] == cview['id']:
            self.results['success'] = True
            self.results['msg'] = 'CView was already %s, no change needed.' % (cview['name'])
            self.results['return'] = host
            logger.debug('set_host_cv: %s', self.results['msg'])
            return True

        self.results = self.util.rest_call('put', '%s/hosts/%s' % (self.foreman, host['id']),
                                      data={'host': {'content_facet_attributes':
                                                    {'content_view_id': cview['id']}
                                               }}
                                     )
        host = self.results['return']
        if host['content_facet_attributes']['content_view']['id'] == cview['id']:
            self.results['return'] = host
            self.results['success'] = True
            self.results['msg'] = 'CView changed to %s.' % (cview['name'])
            logger.debug('set_host_cv: %s', self.results['msg'])
            return True

        self.results['success'] = False
        self.results['msg'] = 'CView not set, cause unknown.'
        logger.debug('set_host_cv: %s', self.results['msg'])
        return False

    def set_host_lce(self, host, lce):
        ''' Set the LifeCycle Environment of a Sat6 host

         Args:
            host:           Host to change
            lce:            New LCE to set

        Returns:
            Status of request. Will set self.results

       '''
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        self.results = {"success": None, "msg": None, "return": None}

        if host is None:
            self.results['success'] = False
            self.results['msg'] = 'Passed host is None.'
        elif 'id' not in host:
            logger.debug('Host does not have ID attribute, attempting lookup for: %s.', host)
            host = self.get_host(host)
        #-- We rely on the fact that get_host will set self.results appropriately
        if self.results['success'] is False:
            logger.debug('set_host_lce: %s', self.results['msg'])
            return False
        elif 'content_facet_attributes' not in host:
            self.results['success'] = False
            self.results['msg'] = '%s is not a content host.' % (host['name'])
            logger.debug('set_host_lce: %s', self.results['msg'])
            return False

        if lce is None:
            self.results['success'] = False
            self.results['msg'] = 'Passed LCE is None.'
        #-- We rely on the fact that get_org_lce will set self.results appropriately
        elif 'id' not in lce:
            logger.debug('LCE does not have ID attribute, attempting lookup for: %s.', lce)
            lce = self.get_org_lce(self.lookup_lce_name(lce))
        if self.results['success'] is False:
            logger.debug('set_host_lce: %s', self.results['msg'])
            return False

        if host['content_facet_attributes']['lifecycle_environment']['id'] == lce['id']:
            self.results['success'] = True
            self.results['msg'] = 'LCE was already %s, no change needed.' % (lce['name'])
            self.results['return'] = host
            logger.debug('set_host_lce: %s', self.results['msg'])
            return True

        self.results = self.util.rest_call('put', '%s/hosts/%s' % (self.foreman, host['id']),
                                      data={'host': {'content_facet_attributes':
                                                    {'lifecycle_environment_id': lce['id']}
                                               }}
                                     )
        host = self.results['return']
        if host['content_facet_attributes']['lifecycle_environment']['id'] == lce['id']:
            self.results['success'] = True
            self.results['msg'] = 'LCE changed to %s.' % (lce['name'])
            self.results['return'] = host
            logger.debug('set_host_lce: %s', self.results['msg'])
            return True

        self.results['success'] = False
        self.results['msg'] = 'LCE not set, cause unknown.'
        logger.debug('set_host_lce: %s', self.results['msg'])
        return False

    def set_host_loc(self, host, location):
        ''' Set the LifeCycle Environment of a Sat6 host

         Args:
            host:           Host to change
            location:            New Location to set

        Returns:
            Status of request. Will set self.results

       '''
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        self.results = {"success": None, "msg": None, "return": None}

        if host is None:
            self.results['success'] = False
            self.results['msg'] = 'Passed host is None.'
        elif 'id' not in host:
            logger.debug('Host does not have ID attribute, attempting lookup for: %s.', host)
            host = self.get_host(host)
        #-- We rely on the fact that get_host will set self.results appropriately
        if self.results['success'] is False:
            logger.debug('set_host_loc: %s', self.results['msg'])
            return False

        if location is None:
            self.results['success'] = False
            self.results['msg'] = 'Passed Location is None.'
        #-- We rely on the fact that get_org_location will set self.results appropriately
        elif 'id' not in location:
            logger.debug('Location does not have ID attribute, attempting lookup for: %s.', location)
            location = self.get_loc(location)
        if self.results['success'] is False:
            logger.debug('set_host_loc: %s', self.results['msg'])
            return False

        if host['location_id'] == location['id']:
            self.results['return'] = host
            self.results['success'] = True
            self.results['msg'] = 'Location was already %s, no change needed.' % (location['name'])
            logger.debug('set_host_loc: %s', self.results['msg'])
            return True

        self.results = self.util.rest_call('put', '%s/hosts/%s' % (self.foreman, host['id']),
                                  data={'host': {'location_id': location['id']} }
                                 )
        host = self.results['return']
        if host['location_id'] == location['id']:
            self.results['success'] = True
            self.results['msg'] = 'Location changed to %s.' % (location['title'])
            self.results['return'] = host
            logger.debug('set_host_loc: %s', self.results['msg'])
            return True

        self.results['success'] = False
        self.results['msg'] = 'Location not set, cause unknown.'
        logger.debug('set_host_loc: %s', self.results['msg'])
        return False

    def add_host_hc(self, host, collection):
        ''' Add a Sat6 host to a collection

         Args:
            host:           Host to add
            collection:     New collection to add to

        Returns:
            Status of request. Will set self.results

       '''
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        self.results = {"success": None, "msg": None, "return": None}

        if host is None:
            self.results['success'] = False
            self.results['msg'] = 'Passed host is None.'
        elif 'id' not in host:
            logger.debug('Host does not have ID attribute, attempting lookup for: %s.', host)
            host = self.get_host(host)
        #-- We rely on the fact that get_host will set self.results appropriately
        if self.results['success'] is False:
            logger.debug('add_host_hc: %s', self.results['msg'])
            return False

        if collection is None:
            self.results['success'] = False
            self.results['msg'] = 'Passed Collection is None.'
        #-- We rely on the fact that get_org_location will set self.results appropriately
        elif 'id' not in collection:
            logger.debug('Collection does not have ID attribute, attempting lookup for: %s.', collection)
            collection = self.get_hc(collection)
        if self.results['success'] is False:
            logger.debug('add_host_hc: %s', self.results['msg'])
            return False

        for _, item in enumerate(host['host_collections']):
            if item['id'] == collection['id']:
                self.results['success'] = True
                self.results['msg'] = 'Host already in %s, no change needed.' % (collection['name'])
                self.results['return'] = host
                logger.debug('add_host_hc: %s', self.results['msg'])
                return True

        self.results = self.util.rest_call('put', '%s/host_collections/%s/add_hosts' % (self.katello, collection['id']),
                                  data={'id': collection['id'], 'host_ids': [host['id']]}
                                 )
        host = self.get_host(host['id'])
        for _, item in enumerate(host['host_collections']):
            if item['id'] == collection['id']:
                self.results['success'] = True
                self.results['msg'] = 'Host successfully added to %s.' % (collection['name'])
                self.results['return'] = host
                logger.debug('add_host_hc: %s', self.results['msg'])
                return True

        self.results['success'] = False
        self.results['msg'] = 'Host not added to collection, cause unknown.'
        logger.debug('add_host_hc: %s', self.results['msg'])
        return False

    def remove_host_hc(self, host, collection):
        ''' Remove a Sat6 host to a collection

         Args:
            host:           Host to remove
            collection:     New collection to remove from

        Returns:
            Status of request. Will set self.results

       '''
        logger.debug('Entering Function: %s', sys._getframe().f_code.co_name) #: pylint: disable=protected-access
        self.results = {"success": None, "msg": None, "return": None}

        if host is None:
            self.results['success'] = False
            self.results['msg'] = 'Passed host is None.'
        elif 'id' not in host:
            logger.debug('Host does not have ID attribute, attempting lookup for: %s.', host)
            host = self.get_host(host)
        #-- We rely on the fact that get_host will set self.results appropriately
        if self.results['success'] is False:
            logger.debug('remove_host_hc: %s', self.results['msg'])
            return False

        if collection is None:
            self.results['success'] = False
            self.results['msg'] = 'Passed Collection is None.'
        #-- We rely on the fact that get_org_location will set self.results appropriately
        elif 'id' not in collection:
            logger.debug('Collection does not have ID attribute, attempting lookup for: %s.', collection)
            collection = self.get_hc(collection)
        if self.results['success'] is False:
            logger.debug('remove_host_hc: %s', self.results['msg'])
            return False

        in_list = False
        for _, item in enumerate(host['host_collections']):
            if item['id'] == collection['id']:
                in_list = True

        if not in_list:
            self.results['return'] = host
            self.results['success'] = True
            self.results['msg'] = 'Host not in %s, no change needed.' % (collection['name'])
            logger.debug('remove_host_hc: %s', self.results['msg'])
            return True

        self.results = self.util.rest_call('put', '%s/host_collections/%s/remove_hosts' % (self.katello, collection['id']),
                                  data={'id': collection['id'], 'host_ids': [host['id']]}
                                 )
        host = self.get_host(host['id'])
        for _, item in enumerate(host['host_collections']):
            if item['id'] == collection['id']:
                self.results['success'] = False
                self.results['msg'] = 'Host not removed from collection, cause unknown.'
                logger.debug('remove_host_hc: %s', self.results['msg'])
                return False

        self.results['success'] = True
        self.results['msg'] = 'Host successfully removed from collection %s.' % (collection['name'])
        self.results['return'] = host
        logger.debug('remove_host_hc: %s', self.results['msg'])
        return True

