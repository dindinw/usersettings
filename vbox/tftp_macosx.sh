#!/bin/bash -e
case "$1" in
'start')
  echo "Staring MacOSX build-in TFTP Server Required an Root Authentication."
  sudo launchctl load -F ./tftp_macosx.plist
  echo "tftpserver started..."
  ;;
'stop')
  echo "Stopping MacOSX build-in TFTP Server Required an Root Authentication."
  sudo launchctl unload -F ./tftp_macosx.plist
  echo "tftpserver stopped..."
  ;;
esac
exit 0
