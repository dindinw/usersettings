. _test_vhd_common.sh
#extract_installwim "/d/ISO/windows/X17-59337.iso" "${HOME}/Downloads"
vhd_detach "${HOME}/Downloads/win7.vhd"
rm -f "${HOME}/Downloads/win7.vhd"
vhd_create "${HOME}/Downloads/win7.vhd" 
vhd_assign "${HOME}/Downloads/win7.vhd" "v:"
# Apply index 4 : win7 ultimate
wim_apply "${HOME}/Downloads/install.wim" 4 "v:"
vhd_makebootable "v:"
vhd_active "${HOME}/Downloads/win7.vhd"
vhd_detach "${HOME}/Downloads/win7.vhd"