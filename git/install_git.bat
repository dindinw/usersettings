@rem Download msysgit from GitHub
@rem https://github.com/msysgit/msysgit/releases for more detals ...

@set GITHUB=https://github.com
@set MSYSGIT_LATEST_RELEASE_URL=%GITHUB%/msysgit/msysgit/releases/latest 

@curl -s -L %MSYSGIT_LATEST_RELEASE_URL% > tmpFile

@for /f "tokens=2" %%a in ('findstr /R "\/msysgit\/msysgit\/releases\/download\/.*/Git.*" tmpFile') do @set link_git="%%a"
@for /f "tokens=2" %%b in ('findstr /R "\/msysgit\/msysgit\/releases\/download\/.*/.*fullinstall.*" tmpFile') do @set link_msysgit_full="%%b"
@for /f "tokens=2" %%c in ('findstr /R "\/msysgit\/msysgit\/releases\/download\/.*/.*netinstall.*" tmpFile') do @set link_msysgit_net="%%c"
@for /f "tokens=2" %%d in ('findstr /R "\/msysgit\/msysgit\/releases\/download\/.*/Portable.*" tmpFile') do @set link_git_portable="%%d"

@set link_git=%GITHUB%%link_git:~7,-2%
@set link_git_portable=%GITHUB%%link_git_portable:~7,-2%
@set link_msysgit_full=%GITHUB%%link_msysgit_full:~7,-2%
@set link_msysgit_net=%GITHUB%%link_msysgit_net:~7,-2%

@echo --------------------------------------------------------------------------
@echo link_git          : %link_git%
@echo link_git_portable : %link_git_portable%
@echo link_msysgit_full : %link_msysgit_full%
@echo link_msysgit_net  : %link_msysgit_net%
@echo --------------------------------------------------------------------------


@rem ---------------------------------------------------------------------------
goto comment
@del tmpFile
@for /f "tokens=8 delims=/" %%e in ( "%link_msysgit_net%" ) do @set msysgit_net_file=%%e
@echo Download : %msysgit_net_file%
@curl -s -L %link_msysgit_net% -O
@echo Download : %msysgit_net_file% done!
%msysgit_net_file%
:comment
@rem ---------------------------------------------------------------------------

@del tmpFile
@for /f "tokens=8 delims=/" %%e in ( "%link_git%" ) do @set wingit_file=%%e
@echo Download : %wingit_file%
@curl -s -L %link_git% -O
@echo Download : %wingit_file% done!




