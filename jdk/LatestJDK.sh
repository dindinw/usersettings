# Last Update : 2014-12 
# The lastest JDK 8 from http://www.oracle.com/technetwork/java/javase/8u-relnotes-2225394.html 

# JDK 8 8u25 b17 MAC
# The checksum list here : https://www.oracle.com/webfolder/s/digest/8u25checksum.html
JDK_8U25_B17_MAC_URL=http://download.oracle.com/otn-pub/java/jdk/8u25-b17/jdk-8u25-macosx-x64.dmg 

# The lastest JDK 7 from https://www.java.com/en/download/faq/release7_changes.xml 

# JDK 7 7u71 b14 MAC
# The checksum list here : https://www.oracle.com/webfolder/s/digest/7u71checksum.html
JDK_7U71_B14_MAC_URL=http://download.oracle.com/otn-pub/java/jdk/7u71-b14/jdk-7u71-macosx-x64.dmg 

LATEST_8_MAC_64_URL=$JDK_8U25_B17_MAC_URL
LATEST_7_MAC_64_URL=$JDK_7U71_B14_MAC_URL

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

VERSION=$1

OS=$2
if [ -z $OS ]; then
  GUESE_OS=`uname`
  case "$GUESE_OS" in
     Linux*)
       OS="LINUX" ;;
     Darwin*)
       OS="MAC";;
     *)
      echo "UNKNOWN OS TYPE : $GUESE_OS"
      exit -1 ;;
  esac
fi

ARCH=$3
if [ -z $ARCH ]; then
 ARCH=64
fi

function get_LATEST_8_MAC_64_URL(){
   echo $LATEST_8_MAC_64_URL
}
function get_LATEST_7_MAC_64_URL(){
   echo $LATEST_7_MAC_64_URL
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

curl -L --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" $DOWNLOAD_URL -o $DOWNLOAD_FOLDER/$FILE_NAME

