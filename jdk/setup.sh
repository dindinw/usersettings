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
DOWNLOAD_URL=
JDK_FILE=
JDK_FILE_CHECKSUM=
JDK_NAME=

FORCE_DOWNLOAD=false

function preparePlatform()
{
    if [[ $OS == "UNKNOWN" ]]; then echo ERROR; exit -1; fi
    
    if [[ "$OS" == "$OS_LINUX" ]]; then
        DOWNLOAD_DIR=~/Downloads
        if [[ "$MACH" == "$MACH_64" ]]; then
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

    elif [[ "$OS" == "$OS_MAC" ]]; then
        DOWNLOAD_DIR=~/Downloads
        #TODO
    elif [[ "$OS" == "$OS_WIN" ]]; then
        DOWNLOAD_DIR=~/Downloads 
        #TODO 32/64bit and Checksum
        if [[ "$MACH" == "$MACH_64" ]]; then
            # 64 bit
            JDK8_FILE_URL_WIN=$JDK8_FILE_URL_WIN_64
            JDK_FILE_CHECKSUM=$JDK8_FILE_CHECKSUM_WIN_64
            JDK_INSTALL_BASE="C:\Program Files\Java"
        else
            # 32 bit
            JDK8_FILE_URL_WIN=$JDK8_FILE_URL_WIN_32
            JDK_FILE_CHECKSUM=$JDK8_FILE_CHECKSUM_WIN_32
        fi
        DOWNLOAD_URL=$JDK8_FILE_URL_WIN
        JDK_NAME=$JDK8_NAME
        # load windows functions
        . ../lib/func_win.sh
    else
        echo "ERROR"
    fi
    JDK_FILE=$(basename $DOWNLOAD_URL)
    
    echo "====================================================================="
    echo "OS Platfrom : $OS"
    echo "    Machine : $MACH"
    echo "        URL : $DOWNLOAD_URL"
    echo "   JDK File : $JDK_FILE"
    echo "   CHECKSUM : $JDK_FILE_CHECKSUM"
    echo " Target JDK : $JDK_NAME"
    echo "install dir : $JDK_INSTALL_BASE"
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

function perpareInstallDir()
{

    if [ ! -d $INSTALL_BASE ]; then mkdir -m0755 -p $INSTALL_BASE; fi
    if [ ! -d $JDK_INSTALL_BASE ]; then mkdir -m0755 -p $JDK_INSTALL_BASE; fi
    chmod -R 755 $INSTALL_BASE
}

function installJDK_Win()
{
    # TODO, In Win7, can't install jdk to other place than C:\Program Files\Java\jdk1.8.0
    #perpareInstallDir

    # TODO (How to pass in the /s option) ?
    #
    # Acccoding to 
    #   http://docs.oracle.com/javase/8/docs/technotes/guides/install/windows_jdk_install.html#CHDEBCCJ
    # JDK, source, no JRE : 
    #    /s ADDLOCAL="ToolsFeature,SourceFeature"
    # JDK, source, with JRE :
    #    /s ADDLOCAL="ToolsFeature,SourceFeature,PublicjreFeature"
    # JRE in the specified directory C:\test\ :
    #    /s /INSTALLDIRPUBJRE=C:\test\
    wait $($DOWNLOAD_DIR/$JDK_FILE //s ADDLOCAL="ToolsFeature,SourceFeature")
}

function installJDK_Linux()
{
    perpareInstallDir
    echo "extracing $JDK_FILE..."
    if [ ! -d $JDK_INSTALL_BASE/$JDK_NAME ]; then 
        wait $(tar xzf $DOWNLOAD_DIR/$JDK_FILE -C $JDK_INSTALL_BASE)
    fi
    if [ -d $JDK_INSTALL_BASE/$JDK_NAME ]; then echo done!; fi
}

function installJDK_Mac()
{
    echo "...TODO installJDK_Mac"
}

function verifyJDKInstalled
{
    pushd "$JDK_INSTALL_BASE/$JDK_NAME/bin"  2>&1 > /dev/null 
    ./java -version
    popd  2>&1 >/dev/null 
}


function setupJDKEnv_Linux()
{

    echo "...TODO setupJDKEnv_Linux"
}

function setupJDKEnv_Mac()
{
    #TODO
    echo "...TODO setupJDKEnv_Mac"
}

###############################################################################
#
#  Setup JAVA_HOME in System enviroment
###############################################################################
function setupJDKEnv_Win()
{
     local javaHome="$JDK_INSTALL_BASE\\$JDK_NAME"
     local jdkBinPath="%JAVA_HOME%\\bin"
     setSysEnv "JAVA_HOME" "$javaHome"
     local oldPath=$(getSysEnv "PATH")
     echo "$oldPath"|grep "^%JAVA_HOME%" 2>&1 >/dev/null # Test if set before
     if [[ ! $? -eq 0 ]]; then
        setSysEnv "PATH" "$jdkBinPath;$oldPath"
     fi
     echo "====================================================================="
     echo "JAVA_HOME : $(getSysEnv "JAVA_HOME")"
     echo "     PATH : $(getSysEnv "PATH")"
     echo "====================================================================="
}

function main()
{
    echo EXECUTE DIR : $(currentDir)
    preparePlatform
    downlaodJDK
    echo "Install $JDK_FILE ..."
    #installJDK_$OS
    echo "Verify $JDK_NAME installed ..."
    verifyJDKInstalled
    echo "Setup $JDK_NAME Env ..."
    setupJDKEnv_$OS
    echo "ALL Done!"
}

. ../lib/core.sh
main
