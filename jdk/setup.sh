# Links

# JDK 7
JDK7_FILE_URL_LINUX_64=http://download.oracle.com/otn-pub/java/jdk/7u45-b18/jdk-7u45-linux-x64.tar.gz
JDK7_FILE_URL_WIN_64=http://download.oracle.com/otn-pub/java/jdk/7u45-b18/jdk-7u45-windows-x64.exe

# JDK 8
JDK8_NAME=jdk1.8.0
# Linux 
JDK8_FILE_URL_LINUX_32=http://download.oracle.com/otn-pub/java/jdk/8-b132/jdk-8-linux-i586.tar.gz
JDK8_FILE_CHECKSUM_LINUX_32=45556e463a561b470bd9d0c07a73effb

JDK8_FILE_URL_LINUX_64=http://download.oracle.com/otn-pub/java/jdk/8-b132/jdk-8-linux-x64.tar.gz
JDK8_FILE_CHECKSUM_LINUX_64=7e9e5e5229c6603a4d8476050bbd98b1

# Mac    
JDK8_FILE_URL_MAC_64=http://download.oracle.com/otn-pub/java/jdk/8-b132/jdk-8-macosx-x64.dmg

# Windows
JDK8_FILE_URL_WIN_64=http://download.oracle.com/otn-pub/java/jdk/8-b132/jdk-8-windows-x64.exe
JDK8_FILE_CHECKSUM_WIN_64=0a577a15cbd9ec7af37ee288e324965e

JDK8_FILE_URL_WIN_32=http://download.oracle.com/otn-pub/java/jdk/8-b132/jdk-8-windows-i586.exe
JDK8_FILE_CHECKSUM_WIN_32=37d905bfda93619465d63e82b77dbb0e

# Default Download Place
DOWNLOAD_DIR=

# Install Place
INSTALL_BASE=~/_devtools
JDK_INSTALL_BASE=$INSTALL_BASE/java/jdk

# Globle Var
OS=
MACH=
FILE_EXT=
DOWNLOAD_URL=
JDK_FILE=
JDK_FILE_CHECKSUM=
JDK_NAME=

FORCE_DOWNLOAD=false

function preparePlatform()
{
    OS=$(uname)
    MACH=$(uname -m)
    #echo "OS Platfrom : $OS"
    #echo "    Machine : $MACH"
    if [[ "$OS" == "Linux" ]]; then
        DOWNLOAD_DIR=~/Downloads
        if [[ "$MACH" == "x86_64" ]]; then
            #64 bit
            JDK8_FILE_URL_LINUX=$JDK8_FILE_URL_LINUX_64
            JDK_FILE_CHECKSUM=$JDK8_FILE_CHECKSUM_LINUX_64
        else
            #32 bit
            JDK8_FILE_URL_LINUX=$JDK8_FILE_URL_LINUX_32
            JDK_FILE_CHECKSUM=$JDK8_FILE_CHECKSUM_LINUX_32
        fi
        DOWNLOAD_URL=$JDK8_FILE_URL_LINUX
        JDK_NAME=$JDK8_NAME

    elif [[ "$OS" == "Darwin" ]]; then
        OS="Mac"
        DOWNLOAD_DIR=~/Downloads
        #TODO

    else #WIN
        OS="Win"
        DOWNLOAD_DIR=~/Downloads 

        #TODO 32/64bit and Checksum
        if [[ "$(wmic cpu get addresswidth|awk '$1 ~/64/ {print $1}')" == "64" ]]; then
            # 64 bit
            MACH=x86_64
            JDK8_FILE_URL_WIN=$JDK8_FILE_URL_WIN_64
            JDK_FILE_CHECKSUM=$JDK8_FILE_CHECKSUM_WIN_64
        else
            # 32 bit
            MACH=x86_32
            JDK8_FILE_URL_WIN=$JDK8_FILE_URL_WIN_32
            JDK_FILE_CHECKSUM=$JDK8_FILE_CHECKSUM_WIN_32
        fi
        DOWNLOAD_URL=$JDK8_FILE_URL_WIN
        JDK_NAME=$JDK8_NAME
    fi
    JDK_FILE=$(basename $DOWNLOAD_URL)
    
    echo "====================================================================="
    echo "OS Platfrom : $OS"
    echo "    Machine : $MACH"
    echo "        URL : $DOWNLOAD_URL"
    echo "   JDK File : $JDK_FILE"
    echo "   CHECKSUM : $JDK_FILE_CHECKSUM"
    echo " Target JDK : $JDK_NAME"
    echo "====================================================================="
    
}

function callWget()
{
    echo "Download URL  : $DOWNLOAD_URL"
    echo "Download File : $JDK_FILE"
    wget --no-cookies --no-check-certificate \
        --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
        "$DOWNLOAD_URL" \
        -O $DOWNLOAD_DIR/$JDK_FILE
}

function checkMD5SUM_Linux()
{
    local result=$(md5sum $DOWNLOAD_DIR/$JDK_FILE| awk '{ print $1 }')
    echo $result 
}

function checkMD5SUM_Mac()
{
    local result=$(md5 -q $DOWNLOAD_DIR/$JDK_FILE)
    echo $result
}

function checkMD5SUM_Win()
{
    checkMD5SUM_Linux
}


function downlaodJDK()
{
    echo "Download $JDK_FILE..."
    #echo $(checkMD5SUM_$OS) $JDK_FILE_CHECKSUM
    local executeDownload=false
    if [[ "$FORCE_DOWNLOAD" == true ]]; then
        echo "Force Download is set, download starting..."
        executeDownload=true
    elif [[ ! -e $DOWNLOAD_DIR/$JDK_FILE ]]; then
        echo "$DOWNLOAD_DIR/$JDK_FILE not found, download starting..."
        executeDownload=true
    elif [[ ! "$(checkMD5SUM_$OS)" == "$JDK_FILE_CHECKSUM" ]]; then
        
        echo "$DOWNLOAD_DIR/$JDK_FILE found, Checksum FAILED. re-download..."
        executeDownload=true
    else
        echo "$DOWNLOAD_DIR/$JDK_FILE found, Checksum OK, download cancaled."
    fi
    if [[ $executeDownload == true ]]; then
        callWget
    fi
}

function installJDK_Win()
{
    #TODO (How to pass in the /s option)
    wait $($DOWNLOAD_DIR/$JDK_FILE //s)
}

function installJDK_Linux()
{
    echo "extracing $JDK_FILE..."
    if [ ! -d $INSTALL_BASE ]; then mkdir -m0755 -p $INSTALL_BASE; fi
    if [ ! -d $JDK_INSTALL_BASE ]; then mkdir -m0755 -p $JDK_INSTALL_BASE; fi
    chmod -R 755 $INSTALL_BASE
    if [ ! -d $JDK_INSTALL_BASE/$JDK_NAME ]; then 
        wait $(tar xzf $DOWNLOAD_DIR/$JDK_FILE -C $JDK_INSTALL_BASE)
    fi
    if [ -d $JDK_INSTALL_BASE/$JDK_NAME ]; then echo done!; fi
}

function installJDK_Mac()
{
    echo "...TODO installJDK_Mac"
}

function setupJDKEnv_Linux()
{
    eval $(echo export JAVA_HOME=$JDK_INSTALL_BASE/$JDK_NAME)
    eval $(echo export PATH=$JAVA_HOME/bin:$PATH)
    printenv|grep JAVA_HOME
    printenv|grep ^PATH
    java -version
    
}

function setupJDKEnv_Mac()
{
    #TODO
    echo "...TODO setupJDKEnv_Mac"
}

function setupJDKEnv_Win()
{
    #TODO
    echo "...TODO setupJDKEnv_Win"
}

function main()
{
    preparePlatform
    downlaodJDK
    echo "Install $JDK_FILE ..."
    #installJDK_$OS
    echo "Setup $JDK_NAME ..."
    setupJDKEnv_$OS
}

main
