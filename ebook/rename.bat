@rem
call :amazonIsdn 111879429X
call :amazonIsdn 0321942051
call :amazonIsdn 012408138X
goto:eof

:amazonIsdn
@echo input ISDN is %~1
@set isdn=%~1
@curl -s -L http://www.amazon.com/dp/%isdn% | findstr /R "btAsinTitle" 2>NUL 1>tmpFile
@rem type tmpFile
@for /f "tokens=1 delims=<" %%a in ('type tmpFile') do @set title="%%a"
@rem echo %title%
@for /f "tokens=2 delims=>" %%b in ('echo %title%') do @set title="%%b"
@echo Title : %title:~,-1%
@del tmpFile

