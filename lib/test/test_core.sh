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

# In trace output:
# Commands executed denoted by a plus-sign (+)"
# Commands executed in a subshell are denoted by a double plus sign (++)"

trace_begin
echo $(pwd -W)
trace_end


