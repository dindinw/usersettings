. _test_vhd_common.sh


iso_path="/d/ISO/windows/win7/X17-59337.iso"
installvm_path="/D/ISO/windows/win7/wim_X17-59337"

vhd_file="${HOME}/Downloads/win7_x64.vhd"
vhd_letter="v:"

mkdir -p $installvm_path
extract_installwim $iso_path $installvm_path
vhd_detach $vhd_file
rm -f $vhd_file
vhd_create $vhd_file
vhd_assign $vhd_file $vhd_letter

# Apply index 4 : win7 ultimate
wim_apply $installvm_path"/install.wim" 4 $vhd_letter
#TODO not work for win8
# workaround , need copy bcdboot.exe to desktop and exectue? wired!
vhd_makebootable $vhd_letter
vhd_active $vhd_file
vhd_detach $vhd_file