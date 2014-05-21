. _test_vhd_common.sh

#extract_installwim "/d/ISO/windows/X17-59337.iso" "${HOME}/Downloads"

#extract_bootwim "/d/ISO/windows/X17-59337.iso" "${HOME}/Downloads"

#extract_installwim "/d/ISO/Windows/Win7/X17-59337.iso" "${HOME}/Downloads"

#extract_bootwim "/d/ISO/Windows/Win7/X17-59337.iso" "${HOME}/Downloads"

vhd_detach "${HOME}/Downloads/test2.vhd"
rm -f "${HOME}/Downloads/test2.vhd"
vhd_create "${HOME}/Downloads/test2.vhd" "100" 
vhd_assign "${HOME}/Downloads/test2.vhd" "v:"
wim_apply "${HOME}/Downloads/boot.wim" 1 "V:"
vhd_makebootable "v:"
vhd_active "${HOME}/Downloads/test2.vhd"
vhd_detach "${HOME}/Downloads/test2.vhd"



#vhd_assign "${HOME}/Downloads/test2.vhd" "z"
#z:\windows\system32\bcdboot z:\windows /s z:
# v:\windows\system32\bcdboot v:\windows /s v:
# bcdedit /store v:\boot\BCD
# bootsect /nt60 v: /mbr

# vhd_detach "${HOME}/Downloads/test2.vhd"

#echo imagex /apply $(to_win_path ${HOME}/Downloads/install.wim) 4 V:

# bootsect /nt60 v: /force /mbr

# cd v:\windows\system32

# add boot
#bootsect /nt60 v: /force

# add bootmagr and BCD
#v:\windows\system32\bcdboot v:\windows\ /s v:

#vhd_makebootable "v:"