# Globle Var
DOWNLOAD_URL=
JDK_FILE=

function prepareByPlatform()
{
    OS=$(uname -s)
    echo "OS Platfrom : $OS"

    JDK7_FILE_URL_LINUX_64=http://download.oracle.com/otn-pub/java/jdk/7u45-b18/jdk-7u45-linux-x64.tar.gz
    JDK7_FILE_URL_WIN_64=http://download.oracle.com/otn-pub/java/jdk/7u45-b18/jdk-7u45-windows-x64.exe
    
    JDK8_FILE_URL_LINUX_64=http://download.oracle.com/otn-pub/java/jdk/8-b132/jdk-8-linux-x64.tar.gz
    JDK8_FILE_URL_MAC_64=http://download.oracle.com/otn-pub/java/jdk/8-b132/jdk-8-macosx-x64.dmg
    JDK8_FILE_URL_WIN_64=http://download.oracle.com/otn-pub/java/jdk/8-b132/jdk-8-windows-x64.exe
    

    if [[ "$OS" == "Linux" ]]; then
        JDK8_FILE_URL_LINUX=$JDK8_FILE_URL_LINUX_64
        echo "JDK8 Linux URL : $JDK8_FILE_URL_LINUX"
        DOWNLOAD_URL=$JDK8_FILE_URL_LINUX

    elif [[ "$OS" == "Mac" ]]; then
        echo "JDK8 Mac URL : $JDK8_FILE_URL_MAC"
        #TODO

    else #WIN
        JDK8_FILE_URL_WIN=$JDK8_FILE_URL_WIN_64
        echo "JDK8 Win URL : $JDK8_FILE_URL_WIN"
        DOWNLOAD_URL=$JDK8_FILE_URL_WIN
    fi
    JDK_FILE=$(basename $DOWNLOAD_URL)
}

function callWget()
{
    echo "Download URL  : $DOWNLOAD_URL"
    echo "Download File : $JDK_FILE"
    wget --no-cookies --no-check-certificate \
        --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
        "$DOWNLOAD_URL" \
        -O $JDK_FILE
}

function downlaodJDK()
{
    echo "Download JDK" 
    echo "Download JDK8" 
    callWget $DOWNLOAD_URL
}
function installJDK()
{
    #TODO (How to pass in the /s option)
    echo "Install $JDK_FILE..."
    wait $(./$JDK_FILE //s)
}

function setupJDKEnv()
{
    #TODO
    echo test
}

function main()
{
    prepareByPlatform
    #downlaodJDK
    installJDK
    setupJDKEnv
}

main
