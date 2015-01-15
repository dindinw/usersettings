#!/bin/bash -e
 
# This script is for controlling OSX v5.7.4 tftpserver
 
case "$1" in
'start')
  launchctl load -F ./tftp_macosx.plist
  echo "tftpserver started..."
  ;;
'stop')
  launchctl unload -F ./tftp_macosx.plist
  echo "tftpserver stopped..."
  ;;
esac
exit 0
