@rem
@call :amazonIsdn 1626710104
@call :amazonIsdn 0321942051
@call :amazonIsdn 012408138X
@call :amazonIsdn B00BFWI6CG
@goto:eof

:amazonIsdn
@echo input ISDN is %~1
@set isdn=%~1
@curl -s -L http://www.amazon.com/dp/%isdn% 1>tmpFile%isdn%
@curl -s -L http://www.amazon.com/dp/%isdn% 1>tmpFile
@rem do check first

@findstr /R "btAsinTitle" tmpFile > tempfindoutput
@rem Notice 'findstr /R /N "^" tempfindoutput ^| find /C ":"' is count of fileline.
@for /f %%i in ('findstr /R /N "^" tempfindoutput ^| find /C ":"') do @set FINDOUTPUT=%%i 
@IF %FINDOUTPUT%==0 @goto:notFoundExit

@for /f "tokens=1 delims="  %%a in ('findstr /R "btAsinTitle" tmpFile') do @set title="%%a"
@rem echo %title%
@for /f "tokens=2 delims=>" %%b in ('echo %title%') do @set title="%%b"
@rem echo %title%
@for /f "tokens=1 delims=<" %%c in ('echo %title%') do @set title="%%c"

@for /f "tokens=1 delims=" %%d in ('findstr /R "Publication.*Date.*ISBN-10.*%isbn%.*Edition.*" tmpFile') do @set details="%%d"
@rem echo Details : %details%

@for /f "tokens=1 delims=|" %%e in ('echo %details%') do @set publishdate='%%e'
@for /f "tokens=2 delims=|" %%f in ('echo %details%') do @set isbn-10=%%f
@for /f "tokens=3 delims=|" %%f in ('echo %details%') do @set isbn-13=%%f
@for /f "tokens=4 delims=|" %%f in ('echo %details%') do @set edition="%%f"

@set title=%title:~2,-1%
@set publishdate=%publishdate:~105,-35%
@set isbn-10=%isbn-10:~50,-35%
@set isbn-13=%isbn-13:~50,-35%
@set edition=%edition:~51,-17%
@echo Title   : %title%
@echo Publish : %publishdate%
@echo ISBN-10 : %isbn-10%
@echo ISBN-13 : %isbn-13%
@echo Edition : %edition%
@goto :cleanExit

:notFoundExit
@echo Error: No result found for %isdn%
:cleanExit
@rem clean varibles
@set title=
@set details=
@del tempfindoutput
@del tmpFile


