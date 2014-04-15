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

Javascript
==========

* NodeJs

Editors
=======

* VIM
* Sublime


IDE
===

* Eclipse
