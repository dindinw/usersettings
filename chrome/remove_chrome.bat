
@rem "C:\Program Files\Google\Chrome\Application\34.0.1847.116\Installer\setup.exe" --uninstall

@rem start /wait msiexec /qn /x {8A69D345-D564-463C-AFF1-A69D9E530F96} 

@rem "C:\WINDOWS\system32\rundll32.exe" C:\WINDOWS\system32\shell32.dll,Control_RunDLL "C:\WINDOWS\system32\appwiz.cpl"

start /wait msiexec /x GoogleChromeStandaloneEnterprise.msi /qb /norestart


@rem del C:\WINDOWS\system32\GroupPolicy\Machine\Registry.pol
rmdir /s /q "C:\Documents and Settings\Administrator\Local Settings\Application Data\Google\Chrome"