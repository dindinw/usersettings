start /wait msiexec /i GoogleChromeStandaloneEnterprise.msi /qb

copy /y master_preferences "c:\Program Files\Google\Chrome\Application\master_preferences"


@rem see http://www.chromium.org/administrators/turning-off-auto-updates 
@rem Set the value of HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Update\AutoUpdateCheckPeriodMinutes to the REG_DWORD value of "0".

reg add HKLM\Software\Policies\Google\Update /f /v AutoUpdateCheckPeriodMinutes /d 0


sc stop gupdate

sc config gupdate start= disabled


sc stop gupdatem

sc config gupdatem start= disabled


@rem probably better:

@rem reg add HKLM\SOFTWARE\Policies\Google\Update /f /v DisableAutoUpdateChecksCheckboxValue /d 1 /t reg_dword

@rem schtasks /change /disable /tn GoogleUpdateTaskMachineUA

@rem schtasks /change /disable /tn GoogleUpdateTaskMachineCore
