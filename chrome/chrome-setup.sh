
WIN7_LINK=https://dl.google.com/tag/s/appguid%3D%7B8A69D345-D564-463C-AFF1-A69D9E530F96%7D%26iid%3D%7B4CCCCB56-E8B8-F482-D457-3DF54C9B95C0%7D%26lang%3Den%26browser%3D3%26usagestats%3D0%26appname%3DGoogle%2520Chrome%26needsadmin%3Dprefers%26installdataindex%3Ddefaultbrowser/update2/installers/ChromeSetup.exe
WIN7_STDALONE_LINK=https://dl.google.com/tag/s/appguid%3D%7B8A69D345-D564-463C-AFF1-A69D9E530F96%7D%26iid%3D%7B4CCCCB56-E8B8-F482-D457-3DF54C9B95C0%7D%26lang%3Den%26browser%3D3%26usagestats%3D0%26appname%3DGoogle%2520Chrome%26needsadmin%3Dtrue%26installdataindex%3Ddefaultbrowser/update2/installers/ChromeStandaloneSetup.exe

CURL736=http://curl.haxx.se/download/curl-7.36.0.tar.gz
WGET115=http://ftp.gnu.org/gnu/wget/wget-1.15.tar.gz

GNUTLS=ftp://ftp.gnutls.org/gcrypt/gnutls/w32/gnutls-3.2.12-w32.zip
GNUTLS_SIG=ftp://ftp.gnutls.org/gcrypt/gnutls/w32/gnutls-3.2.12-w32.zip.sig

MSI_PATH = https://dl.google.com/tag/s/appguid%3D%7B8A69D345-D564-463C-AFF1-A69D9E530F96%7D%26iid%3D%7BCA8DF948-A4C1-39A2-F252-9F2344D3C552%7D%26lang%3Den%26browser%3D4%26usagestats%3D0%26appname%3DGoogle%2520Chrome%26needsadmin%3Dprefers/edgedl/chrome/install/GoogleChromeStandaloneEnterprise.msi
#wget 1.14 mingw32
#wget $GNUTLS
#wget $GNUTLS_SIG
#wget $WGET115

#tar xvzf $(basename $WGET115)

#cd $(basename $WGET115 .tar.gz)
#./configure
#make
