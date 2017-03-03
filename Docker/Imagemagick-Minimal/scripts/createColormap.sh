#!/bin/sh
#===============================================================================
#
# FILE: createColormaps.sh
#
# USAGE: createColormaps.sh
#
# DESCRIPTION: Creates color swatch and colormap files for a theme.
#
# OPTIONS: see function ’usage’ below
# REQUIREMENTS: Image Magick 'convert' & 'montage' commands
# BUGS: ---
# NOTES: ---
# AUTHOR: awmyhr, awmyhr@gmail.com
# VERSION: 0.1
# CREATED: 2016-09-28
# REVISION: 2016-09-28
#===============================================================================
# [[ "$TRACE" ]] && set -x
#----------------------------------------------------------------------
# Set up theme colors
#   Eventually SCHEME will be set by command line option, colors will
#   then be loaded from a file
#----------------------------------------------------------------------
SCHEME='solarized'

c_BASE03='#002b36' 
c_BASE02='#073642' 
c_BASE01='#586e75' 
c_BASE00='#657b83' 
c_BASE0='#839496' 
c_BASE1='#93a1a1' 
c_BASE2='#eee8d5' 
c_BASE3='#fdf6e3' 
c_YELLOW='#b58900' 
c_ORANGE='#cb4b16' 
c_RED='#dc322f' 
c_MAGENTA='#d33682' 
c_VIOLET='#6c71c4' 
c_BLUE='#268bd2' 
c_CYAN='#2aa198' 
c_GREEN='#859900' 

#----------------------------------------------------------------------
# Set canvas size - eventually this will be a command line option
#----------------------------------------------------------------------
SIZE='100x100'

#----------------------------------------------------------------------
# Setup file names - these wil not be modifiable outside script
#----------------------------------------------------------------------
f_BASE03="${SCHEME}-base03.gif" 
f_BASE02="${SCHEME}-base02.gif" 
f_BASE01="${SCHEME}-base01.gif" 
f_BASE00="${SCHEME}-base00.gif" 
f_BASE0="${SCHEME}-base0.gif"  
f_BASE1="${SCHEME}-base1.gif"  
f_BASE2="${SCHEME}-base2.gif"  
f_BASE3="${SCHEME}-base3.gif"  
f_YELLOW="${SCHEME}-yellow.gif" 
f_ORANGE="${SCHEME}-orange.gif" 
f_RED="${SCHEME}-red.gif"    
f_MAGENTA="${SCHEME}-magenta.gif"
f_VIOLET="${SCHEME}-violet.gif" 
f_BLUE="${SCHEME}-blue.gif"   
f_CYAN="${SCHEME}-cyan.gif"   
f_GREEN="${SCHEME}-green.gif"  

f_MAP_BGDARK="${SCHEME}-colormap-bg-dark.gif"
f_MAP_BGLIGHT="${SCHEME}-colormap-bg-light.gif"
f_MAP_CONTENT="${SCHEME}-colormap-content.gif"
f_MAP_DARK="${SCHEME}-colormap-dark.gif"
f_MAP_LIGHT="${SCHEME}-colormap-light.gif"
f_MAP_SCALE="${SCHEME}-colormap-scale.gif"
f_MAP_ACCENT="${SCHEME}-colormap-accent.gif"
f_MAP_ALL="${SCHEME}-colormap-all.gif"

#----------------------------------------------------------------------
# Create swatches
#----------------------------------------------------------------------
convert -size "${SIZE}" xc:"${c_BASE03}"  "${f_BASE03}"
convert -size "${SIZE}" xc:"${c_BASE02}"  "${f_BASE02}"
convert -size "${SIZE}" xc:"${c_BASE01}"  "${f_BASE01}"
convert -size "${SIZE}" xc:"${c_BASE00}"  "${f_BASE00}"
convert -size "${SIZE}" xc:"${c_BASE0}"   "${f_BASE0}"
convert -size "${SIZE}" xc:"${c_BASE1}"   "${f_BASE1}"
convert -size "${SIZE}" xc:"${c_BASE2}"   "${f_BASE2}"
convert -size "${SIZE}" xc:"${c_BASE3}"   "${f_BASE3}"
convert -size "${SIZE}" xc:"${c_YELLOW}"  "${f_YELLOW}"
convert -size "${SIZE}" xc:"${c_ORANGE}"  "${f_ORANGE}"
convert -size "${SIZE}" xc:"${c_RED}"     "${f_RED}"
convert -size "${SIZE}" xc:"${c_MAGENTA}" "${f_MAGENTA}"
convert -size "${SIZE}" xc:"${c_VIOLET}"  "${f_VIOLET}"
convert -size "${SIZE}" xc:"${c_BLUE}"    "${f_BLUE}"
convert -size "${SIZE}" xc:"${c_CYAN}"    "${f_CYAN}"
convert -size "${SIZE}" xc:"${c_GREEN}"   "${f_GREEN}"

#----------------------------------------------------------------------
# Create colormaps
#----------------------------------------------------------------------

montage -tile 2x1 "${f_BASE03}"  "${f_BASE02}" -geometry +0+0 "${f_MAP_BGDARK}"
montage -tile 2x1 "${f_BASE3}"   "${f_BASE2}"  -geometry +0+0 "${f_MAP_BGLIGHT}"
montage -tile 2x2 "${f_BASE01}"  "${f_BASE00}" "${f_BASE0}"   "${f_BASE1}"      \
                  -geometry +0+0 "${f_MAP_CONTENT}"

montage -tile 4x2 "${f_BASE03}"  "${f_BASE02}"    "${f_BASE01}" "${f_BASE00}"  \
                  "${f_BASE0}"   "${f_BASE1}"     "${f_BASE2}"  "${f_BASE3}"   \
                  -geometry +0+0 "${f_MAP_SCALE}"
montage -tile 4x2 "${f_YELLOW}"  "${f_ORANGE}"    "${f_RED}"    "${f_MAGENTA}" \
                  "${f_VIOLET}"  "${f_BLUE}"      "${f_CYAN}"   "${f_GREEN}"   \
                  -geometry +0+0 "${f_MAP_ACCENT}"

montage -tile 1x2 "${f_MAP_BGDARK}"  "${f_MAP_CONTENT}" -geometry +0+0 "${f_MAP_DARK}"
montage -tile 1x2 "${f_MAP_BGLIGHT}" "${f_MAP_CONTENT}" -geometry +0+0 "${f_MAP_LIGHT}"
montage -tile 1x2 "${f_MAP_SCALE}"   "${f_MAP_ACCENT}"  -geometry +0+0 "${f_MAP_ALL}"
