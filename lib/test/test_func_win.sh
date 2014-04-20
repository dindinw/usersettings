#!/bin/bash
source ../core.sh
source ../func_win.sh

echo "========================================================================="
echo "Test getAllUserEnv..."
echo "========================================================================="
getAllUserEnv

echo
echo "========================================================================="
echo "Test getAllSysEnv..."
echo "========================================================================="
getAllSysEnv

echo
echo "========================================================================="
echo "Test getUserEnv..."
echo "========================================================================="
getUserEnv "JAVA_HOM"
echo execute return value is $?
getUserEnv "JAVA_HOME"
echo execute return value is $?
JAVA_HOME=$(getUserEnv "JAVA_HOME")
echo JAVAHOME=$JAVA_HOME

echo 
echo "========================================================================="
echo "Test getSysEnv..."
echo "========================================================================="
MYPATH=$(getSysEnv "PATH")
echo MYPATH=$PATH
echo

echo "========================================================================="
echo "Test setUserEnv and delUserEnv..."
echo "========================================================================="
setUserEnv "FOO" "BAR"
getUserEnv "FOO"
getAllUserEnv
delUserEnv "FOO"
getAllUserEnv


echo "========================================================================="
echo "Test setSysEnv and delSysEnv..."
echo "========================================================================="
setSysEnv "FOO" "BAR"
getSysEnv "FOO"
getAllSysEnv
delSysEnv "FOO"
getAllSysEnv

rm -f "TempWmicBatchFile.bat" &> /dev/null