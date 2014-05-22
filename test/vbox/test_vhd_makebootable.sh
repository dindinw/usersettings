. _test_vhd_common.sh

vhd="${HOME}/Downloads/boot.vhd"
bootwim="${HOME}/Downloads/boot.wim"

# vhd_detach ${vhd}
# rm -f ${vhd}
# vhd_create ${vhd} 1000
vhd_assign ${vhd} "v:"
#wim_apply ${bootwim} 1 "v:"
#vhd_makebootable "v:"
vhd_active ${vhd}
vhd_detach ${vhd}


############ Test for Win7(X17-59337.iso) install.wim
# Using system default bcdboot.exe
# version : 6.1.7600.16385 7/14/2009
# C:>bcdboot.exe v:\windows /s v:
# Boot files successfully created.

# Using itself bcdboot.exe, 
# Version : 
# MD5SUm  : 3a66846f45be2e46f7ea16b2f7d2ef34
# C:>v:\windows\system32\bcdboot v:\windows /s v: 
# Boot files successfully created.

# Using Win8.1 bcdboot.exe, the vesion is 6.3.9600.17031 3/18/2014
# MD5SUM : 03f5a1b7d28443c29a493de5ff05a77f
# 
# C:>%USERPROFILE%\Desktop\bcdboot.exe v:\windows /s v:
# Boot files successfully created.
############

############ Test for Win7(X17-59337.iso) boot.wim
# Using System default bcdboot.exe 
# version : 6.1.7600.16385 7/14/2009
#
# C:>bcdboot.exe v:\windows /s v:
# BFSVC: Failed to open handle to resume object. Status = [c0000034]
#
# 
# Using itself bcdboot.exe. version 6.1.7601.17514, 11/20/2010 
# MD5SUM : 3a66846f45be2e46f7ea16b2f7d2ef34
#
# C:>v:\windows\system32\bcdboot v:\windows /s v:
# BFSVC: Failed to open handle to resume object. Status = [c0000034]
#
#
# C:>%USERPROFILE%\Desktop\bcdboot.exe v:\windows /s v:
# Boot files successfully created.

############ Test for Win8.1 (X17-59337.iso) install.wim
# C:\>bcdboot.exe v:\windows /s v:
# Boot files successfully created.
# For Win8.1 , don't use itself copy itself
# C:\>v:\windows\system32\bcdboot v:\windows /s v:
# Failure when attempting to copy boot files.

# C:\>%USERPROFILE%\Desktop\bcdboot.exe v:\windows /s v:
# Boot files successfully created.