. _test_vhd_common.sh

#extractInstallWim "/d/ISO/windows/X17-59337.iso" "${HOME}/Downloads"

#extract_bootwim "/d/ISO/windows/X17-59337.iso" "${HOME}/Downloads"

vhd_detach "${HOME}/Downloads/test2.vhd"
rm -f "${HOME}/Downloads/test2.vhd"
vhd_create "${HOME}/Downloads/test2.vhd" "100" 
vhd_assign "${HOME}/Downloads/test2.vhd" "z"
wim_apply "${HOME}/Downloads/boot.wim" 1 "Z:"
vhd_detach "${HOME}/Downloads/test2.vhd"