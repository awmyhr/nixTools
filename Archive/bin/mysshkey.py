#!/usr/bin/env python
# Mysshkey
# Version 0.0.3
# Bill Scheel <LinuxRockz@gmail.com>
# January 1, 2007
# Released under the GPL License- http://www.fsf.org/licensing/licenses/gpl.txt
#
import sys, string, glob, os, re, exceptions, traceback, pxssh, pexpect, getpass

# System Functions Do Not Touch
CLEAR = sys.stdout.write(os.popen('clear').read())

def main():
    GET_CURRENT_USER = os.popen('whoami').read()
    CURRENT_USER = string.strip(GET_CURRENT_USER)
    SSH_DIR = "~/.ssh"
    KEY_FILE = "id_dsa.pub"
    SERVER_PATH = "~/"

    host_address = raw_input("Enter host:  ")
    str(host_address)
    user_name = raw_input("Enter username:  ")
    str(user_name)
    user_password = getpass.getpass(prompt='Enter password:  ')
    str(user_password)

    CLEAR

    if user_name == "root":
        LOCAL_SSH_DIR = '/root/.ssh'
    else:
        LOCAL_SSH_DIR = '/home/' + CURRENT_USER + '/.ssh'
    try:
        child = pexpect.spawn('scp ' + LOCAL_SSH_DIR + '/' + KEY_FILE + ' ' + user_name + '@' + host_address + ':' + SERVER_PATH)
        child.expect ('[pP]assword:')
        child.sendline (user_password)
        child.expect(pexpect.EOF)
        print "\nKey uploaded successfully.\n"

    except pexpect.TIMEOUT:
        print "\nSCP Failed.\n\n"
        sys.exit()

    except pexpect.EOF:
        print "\nBad Host or already has key authenication, or unable to connect.\n"
        sys.exit()

    ssh = pxssh.pxssh()
    if not ssh.login (host_address , user_name, user_password):
        print "SSH session failed on login."
        print str(ssh)
    else:
        print "\nSSH session login successful.\n"
        ssh.sendline ('mkdir ' + SSH_DIR + '; cat ' + SERVER_PATH  + KEY_FILE + '>> ' + SSH_DIR + '/authorized_keys' + '; chmod 700 ' + SSH_DIR + '; chmod 600 ' + SSH_DIR + '/authorized_keys')
        ssh.sendline ('rm -f ' + SERVER_PATH  + KEY_FILE)

        print "\nKey installed successfully.\n\n"
        ssh.logout()
        sys.exit()

if __name__ == '__main__':
    main()
