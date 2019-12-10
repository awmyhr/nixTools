#!/usr/bin/python2 -tt
# -*- coding: utf-8 -*-
''' Class for holding/translating colors '''
#==============================================================================
import os
#==============================================================================
class Colors(object):
    ''' Simple class to ease access to ENV colors '''
    __version = '0.2.0'

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
        return

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

