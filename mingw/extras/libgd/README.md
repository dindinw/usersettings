offical site : http://libgd.bitbucket.org/
lastest version 2.1.0 

MinGW build
```
./configure --with-png=/mingw --with-freetype=/mingw --prefix=/mingw


CMake build

```
cmake -G "MSYS Makefiles" -PNG_PNG_INCLUDE_DIR=C:\msysgit\msysgit\mingw -DENABLE_PNG=1 -DENABLE_JPEG=1 -DENABLE_TIFF=0 -DENABLE_FREETYPE=1 -DENABLE_FONTCONFIG=0 -DCMAKE_INSTALL_PREFIX=C:\msysgit\msysgit\mingw

cmake -G"MSYS Makefiles" -DCMAKE_LIBRARY_PATH=c:\msysgit\msysgit\mingw\lib -DCMAKE_INCLUDE_PATH=c:\msysgit\msysgit\include -DENABLE_JPEG=On -DBUILD_TEST=On -DCMAKE_RELEASE_TYPE=DEBUG  -ZLIB_INCLUDE_DIR=c:\msysgit\msysgit\include


cmake -G"MSYS Makefiles" -DCMAKE_LIBRARY_PATH=c:\msysgit\msysgit\mingw\lib -DCMAKE_INCLUDE_PATH=c:\msysgit\msysgit\include -DENABLE_JPEG=On -DBUILD_TEST=On -DCMAKE_RELEASE_TYPE=DEBUG -DZLIB_INCLUDE_DIR=c:\msysgit\msysgit\mingw\include -DPNG_PNG_INCLUDE_DIR=c:\msysgit\msysgit\include -DJPEG_INCLUDE_DIR=c:\msysgit\msysgit\include

set MINGW=c:\msysgit\msysgit\mingw
cmake -G"MSYS Makefiles" -DCMAKE_LIBRARY_PATH=%MINGW%\lib -DCMAKE_INCLUDE_PATH=%MINGW%\include -DENABLE_JPEG=On -DBUILD_TEST=On -DCMAKE_RELEASE_TYPE=DEBUG -DZLIB_INCLUDE_DIR=%MINGW%\include -DPNG_PNG_INCLUDE_DIR=%MINGW%\include -DJPEG_INCLUDE_DIR=%MINGW%\include -DFREETYPE_INCLUDE_DIRS=%MINGW%\include

```