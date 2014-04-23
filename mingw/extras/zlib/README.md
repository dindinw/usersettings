

offical site (http://zlib.net/)

MinGW Build
```
make -f win32/Makefile.gcc
```

You may have to edit Makefile.gcc if some headers can't be found.

```
CC = $(PREFIX)gcc -I/mingw/include
RC = $(PREFIX)windres -I/mingw/include
```