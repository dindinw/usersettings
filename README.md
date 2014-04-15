 The instructions of how to set up developer environment under various platform and a collection of useful developer environment setting script and files.





Basic Build Env
===============


Per-requirement
---------------

### Curl 

Offical Page (http://curl.haxx.se/)

Documentation (http://curl.haxx.se/docs/manpage.html)

Installation

   * Windows : [curl.exe][d_curl_1] [libcrypto.dll][d_curl_2] [libssl.dll][d_curl_3] [curl-ca-bundle.crt][d_curl_4] [libcurl.dll*][d_curl_5]

     (  * Note : libcurl.dll is not need for using command-line curl.)
     ( Version : curl 7.30.0 (i386-pc-win32) libcurl/7.30.0 OpenSSL/0.9.8y zlib/1.2.7)
     (   build : see https://github.com/dindinw/msysgit/blob/master/src/curl/release.sh )

   * Linux 

        sudo apt-get install curl
   
   * Mac (shipped)

[d_curl_1]:https://github.com/dindinw/msysgit/raw/master/mingw/bin/curl.exe
[d_curl_2]:https://github.com/dindinw/msysgit/raw/master/mingw/bin/libcrypto.dll
[d_curl_3]:https://github.com/dindinw/msysgit/raw/master/mingw/bin/libssl.dll
[d_curl_4]:https://github.com/dindinw/msysgit/raw/master/mingw/bin/curl-ca-bundle.crt
[d_curl_5]:https://github.com/dindinw/msysgit/raw/master/mingw/bin/libcurl.dll

### Git

* Windows : [install_git.bat][d_git_1]

Notice: When check out git rep. keep using the `git@github.com:<Username>/<Project>.git`, not https to make your SSH key works.

[d_git_1]:https://github.com/dindinw/usersettings/raw/master/git/install_git.bat

### Chrome

Windows

* [Standalone Download][chrome_win] 
* [MSI Downlaod][chrome_win_msi]

Release site : (http://googlechromereleases.blogspot.com/)

Home Page Location  : (http://www.chromium.org/administrators/policy-list-3#Homepage)
    
* ~~Software\Policies\Google\Chrome\HomepageLocation~~
* ~~HKEY_CURRENT_USER\Software\Policies\Google\Chrome\HomepageLocation~~ 

simply create reg key will not work since 28

Policy Template : (http://dl.google.com/dl/edgedl/chrome/policy/policy_templates.zip)
  
The [documentation][chrome_master_perf_doc] for master_preferences. and an [example][chrome_master_perf_example].

[chrome_win]:https://dl.google.com/tag/s/appguid%3D%7B8A69D345-D564-463C-AFF1-A69D9E530F96%7D%26iid%3D%7B4CCCCB56-E8B8-F482-D457-3DF54C9B95C0%7D%26lang%3Den%26browser%3D3%26usagestats%3D0%26appname%3DGoogle%2520Chrome%26needsadmin%3Dtrue%26installdataindex%3Ddefaultbrowser/update2/installers/ChromeStandaloneSetup.exe
[chrome_win_msi]:https://dl.google.com/tag/s/appguid%3D%7B8A69D345-D564-463C-AFF1-A69D9E530F96%7D%26iid%3D%7BCA8DF948-A4C1-39A2-F252-9F2344D3C552%7D%26lang%3Den%26browser%3D4%26usagestats%3D0%26appname%3DGoogle%2520Chrome%26needsadmin%3Dprefers/edgedl/chrome/install/GoogleChromeStandaloneEnterprise.msi

[chrome_master_perf_doc]:https://support.google.com/chrome/a/answer/187948
[chrome_master_perf_example]:http://www.chromium.org/administrators/configuring-other-preferences#TOC-Preferences-List

Linux
-----
### Gcc/make

    sudo apt-get install build-essential 

Mac
---

### Xcode
### Homebrew

Win
---

### Cgwin
### VC Express

Java
====

Linux
-----
### JDK
 

#### OpenJDK 
    sudo apt-get install openjdk-7-jdk openjdk-7-source
    sudo update-java-alternatives -s java-1.7.0-openjdk-i386    
#### Oracle JDK
* NOTE: JDK 8 released on 18 March 2013.
    wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8-b132/jdk-8-linux-i586.tar.gz"
    tar xzvf jdk-8-linux-i586.tar.gz 
    sudo mv ./

* Maven

Javascript
==========

* NodeJs

Editors
=======

* VIM
* Sublime


IDE
===

Eclipse
-------

The very useful plugin [workspace mechanic][1]

[1]:https://code.google.com/a/eclipselabs.org/p/workspacemechanic/
