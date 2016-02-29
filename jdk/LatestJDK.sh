#!/usr/bin/env bash

# Last Update : 2016-02

# JDK 8 8u73
# The  release page : http://www.oracle.com/technetwork/java/javase/documentation/8u-relnotes-2225394.html
# The download page : http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html
# The checksum page : https://www.oracle.com/webfolder/s/digest/8u73checksum.html
# jdk-8u73-windows-x64.exe  sha256: a4e2f75ead7c5ab09a58b6d77ff98da4b1343caaab383c4b93479dd5866212ea
# jdk-8u73-macosx-x64.dmg  sha256: a96efc6aad18e3b49dd41f4b7a955f9ef2e01ee390987c63f5a6347026fcc336
JDK_8U73_WIN64_URL=http://download.oracle.com/otn-pub/java/jdk/8u73-b02/jdk-8u73-windows-x64.exe
JDK_8U73_MAC_URL=http://download.oracle.com/otn-pub/java/jdk/8u73-b02/jdk-8u73-macosx-x64.dmg

# The latest JDK 7
#  release page : https://www.java.com/en/download/faq/release7_changes.xml
# download page : http://www.oracle.com/technetwork/java/javase/downloads/jdk7-downloads-1880260.html
# checksum page : https://www.oracle.com/webfolder/s/digest/7u79checksum.html
#   jdk-7u79-windows-x64.exe	6c0ea86f9c2b3c1e7d95c513785f1f55
#   jdk-7u79-macosx-x64.dmg	e085660e60ed1325143ac5e15391ebb9
JDK_7U79_WIN_URL=http://download.oracle.com/otn-pub/java/jdk/7u79-b15/jdk-7u79-windows-x64.exe
JDK_7U79_MAC_URL=http://download.oracle.com/otn-pub/java/jdk/7u79-b15/jdk-7u79-macosx-x64.dmg

latest_8_mac_64_url=${JDK_8U73_MAC_URL}
latest_8_win_64_url=${JDK_8U73_WIN64_URL}
latest_7_mac_64_url=${JDK_7U79_MAC_URL}
latest_7_win_64_url=${JDK_7U79_WIN_URL}

function usage()
{
  echo "8"
  echo "8 MAC"
  echo "7 WIN 64"
}
if [ ${#@} -ne 1 ]; then
  echo "error input"
  usage
  exit -1
fi

version=$1

os=$2
if [ -z $os ]; then
  guese_os=`uname`
  case "$guese_os" in
     Linux*)
       os="LINUX" ;;
     Darwin*)
       os="MAC";;
     MINGW*)
       os="WIN";;
     *)
      echo "Unknown OS Type : $GUESE_OS"
      exit -1 ;;
  esac
fi

arch=$3
if [ -z ${arch} ]; then
 arch=64
fi

function get_latest_8_mac_64_url(){
    echo ${latest_8_mac_64_url}
}
function get_latest_7_mac_64_url(){
    echo ${latest_7_mac_64_url}
}
function get_latest_8_win_64_url(){
    echo ${latest_8_win_64_url}
}

DOWNLOAD_FOLDER=.
if [ -e ~/Downloads ]; then
  DOWNLOAD_FOLDER=~/Downloads
fi

DOWNLOAD_URL=`eval get_LATEST_${VERSION}_${OS}_${ARCH}_URL`
if [ -z $DOWNLOAD_URL ]; then
  echo "ERROR when get_LATEST_${VERSION}_${OS}_${ARCH}_URL"
  echo "re-check your input: $@"
  exit -1
fi
FILE_NAME=`basename $DOWNLOAD_URL`
if [ -z $FILE_NAME ]; then
  echo "ERROR when extract download file name form url: $DOWNLOAD_URL."
  echo "re-check your input: $@"
fi

if [ -e $DOWNLOAD_FOLDER/$FILE_NAME ]; then
  echo "File existed in $DOWNLOAD_FOLDER/$FILE_NAME"
  echo "Please remove or rename it before start."
  md5 $DOWNLOAD_FOLDER/$FILE_NAME
  exit 0
fi

echo "-------------------------------"
echo DOWNLOAD_URL=$DOWNLOAD_URL
echo DOWNLOAD_FOLDER=$DOWNLOAD_FOLDER
echo DOWNLOAD_FILE_NAME=$FILE_NAME

echo curl -L --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" $DOWNLOAD_URL -o $DOWNLOAD_FOLDER/$FILE_NAME

