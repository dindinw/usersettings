#!/bin/bash
source ../core.sh

echo "====================================================================="
echo "OS Platfrom : $OS"
echo "       Name : $OS_NAME"
echo "    Version : $OS_VERSION"
echo "    Machine : $MACH"
echo "   File Ext : $FILE_EXT"
echo "====================================================================="

currentDir

rm -f "TempWmicBatchFile.bat" &> /dev/null

