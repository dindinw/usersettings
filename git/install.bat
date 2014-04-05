@rem In GitHub
@rem https://github.com/msysgit/msysgit/releases

@set MSYSGIT_LATEST_PAGE_URL=https://github.com/msysgit/msysgit/releases/latest
@set MSYSGIT_LATEST_DOWN_URL=

curl -L %MSYSGIT_LATEST_PAGE_URL%
findstr /R "https" tmpFile
@for /f %%i in ('findstr /R "https://" tmpFile') do @echo %%i

@rem curl --help
@for /f "tokens=2 delims==" %%i in ('curl -s %MSYSGIT_LATEST_PAGE_URL%') do @set link="%%i"
@set latest=%link:~50,-32%
@echo The latest version : %latest%
@set MSYSGIT_LATEST_DOWN_URL=
@echo The download url   : 


