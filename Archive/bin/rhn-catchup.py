#!/usr/bin/env python
# This has been cobbled together from several different sources
import sys
import re
import time
import socket
import xmlrpclib

def getConf():
  sinfo = open('/etc/satellite_api.conf').read()
  sserver, suser, spass = sinfo.split(' ')

  return (sserver, suser, spass)

def satLogin(sserver, suser, spass):
  # input: string server, string user, string password
  client = xmlrpclib.Server('http://' + sserver + '/rpc/api', verbose=0)
  key    = client.auth.login(suser,spass)

  return (client, key)

def mergeChannelErrata(client, key, origin_channel, dest_channel):
  resp = client.channel.software.mergeErrata(key, origin_channel, dest_channel)

  return resp

def mergeChannelPackages(client, key, origin_channel, dest_channel):
  resp = client.channel.software.mergePackages(key, origin_channel, dest_channel)

  return resp

def updateChannelInfo(client, key, channel_id, newdesc):
  resp = client.channel.software.setDetails(key, channel_id, newdesc)
  return resp

def main():
  ## Exit Codes
  SUCCESS = 0
  ERR_XMLRPC = 80
  ERR_SOCK = 81
  ERR_NOCONF = 82
  ERR_BADCONF = 83

  ## Get configuration information
  try:
    (satsrv, satuser, satpass) = getConf()
  except IOError as e:
    print "I/O error({0}): {1}".format(e.errno, e.strerror)
    return ERR_NOCONF
  except ValueError:
    print "Could not parse satellite info file"
    return ERR_BADCONF
  except:
    print "Unexpected error:", sys.exc_info()[0]
    raise

  ## Get satellite server client session
  try:
    (client, key) = satLogin(satsrv, satuser, satpass)
  except (xmlrpclib.Fault,xmlrpclib.ProtocolError), e:
    print "!!! Got XMLRPC error !!!\n\t%s" % e
    print "!!! Check Satellite FQDN and login information; You can also look at /var/log/httpd/error_log on the Satellite for more info !!!"
    return ERR_XMLRPC
  except socket.error, e:
    print "!!! Got socket error !!!\n\n%s" % e
    print "!!! Could not connect to %s" % sserver
    return ERR_SOCK
  except:
    print "Unexpected error:", sys.exc_info()[0]
    raise


  clist  = client.channel.listAllChannels(key)
  for env in ["dev"]:
    for channel in clist:
      if env in channel.get('label'):
        channelinfo = client.channel.software.getDetails(key, channel.get('label'))
        if channelinfo.get('clone_original'):
          cloneinfo = client.channel.software.getDetails(key, channelinfo.get('clone_original'))
          print  channel.get('label') + ': Merge Errata/Packages from: ' + cloneinfo.get('label')
          prelease = re.search(r"R20.*$", channelinfo.get('name'))
          prmajor, prminor = prelease.group(0).split('-')
          prdate = time.strptime(prmajor, "R%Y.%m")
          crdate = time.localtime()
          if prdate.tm_year == crdate.tm_year and prdate.tm_mon == crdate.tm_mon:
            prminor = int(prminor) + 1
          else:
            prminor = 1
          newdesc = {
            'name': re.sub(prelease.group(0), time.strftime("R%Y.%m") + '-' + str(prminor), channelinfo.get('name')),
            'description': re.sub(r"Updated.*", time.strftime("Updated %Y%m%d by script"), channelinfo.get('description'))
            }

          ## Merge Errata
          try:
            uperrata = mergeChannelErrata(client, key, cloneinfo.get('label'), channel.get('label'))
            if uperrata:
              print channel.get('label') + ': Merged ' + str(len(uperrata)) + ' Errata.'
            else:
              print channel.get('label') + ': No Errata to merge.'
          except xmlrpclib.Fault, e:
            print "!!! Got XMLRPC Fault !!!\n\t%s" % e
            return ERR_XMLRPC

          ## Merge Packages
          try:
            uppackages = mergeChannelPackages(client, key, cloneinfo.get('label'), channel.get('label'))
            if uppackages:
              print channel.get('label') + ': Merged ' + str(len(uppackages)) + ' Packages.'
            else:
              print channel.get('label') + ': No Packages to merge.'
          except xmlrpclib.Fault, e:
            print "!!! Got XMLRPC Fault !!!\n\t%s" % e
            return ERR_XMLRPC

          ## Update Channel Info
          try:
            updateChannelInfo(client, key, channel.get('id'), newdesc)
            print channel.get('label') + ': Successfully updated channel info.'
            print newdesc
          except xmlrpclib.Fault, e:
            print "!!! Got XMLRPC Fault !!!\n\t%s" % e
            return ERR_XMLRPC

        else:
          print channel.get('label') + ' has no original channel'

        print '******************************';

  try:
    client.auth.logout(key)
  except xmlrpclib.Fault, e:
    print "!!! Got XMLRPC Fault !!!\n\t%s" % e
    return ERR_XMLRPC

### END OF main() ###

if __name__ == "__main__":
  retval = 1
  try:
    retval = main()
  except KeyboardInterrupt:
    print "!!! Caught Ctrl-C !!!"

  print "\nExiting."
  sys.exit(retval)
