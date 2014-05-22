. _test_vhd_common.sh

installvm_path="/D/ISO/windows/win81/win81_wim_x86"
win81_iso_path="/d/ISO/windows/win81/9600.17050.WINBLUE_REFRESH.140317-1640_X86FRE_ENTERPRISE_EVAL_EN-US-IR3_CENA_X86FREE_EN-US_DV9.ISO"

vhd_file="${HOME}/Downloads/win81.vhd"
vhd_letter="v:"

#mkdir -p $installvm_path
#extract_installwim $win81_iso_path $installvm_path
vhd_detach $vhd_file
rm -f $vhd_file
vhd_create $vhd_file
vhd_assign $vhd_file $vhd_letter

# Apply index 1 for : Windows 8.1 Enterprise Evaluation, only one index
wim_apply $installvm_path"/install.wim" 1 $vhd_letter
#TODO not work for win8
# workaround , need copy bcdboot.exe to desktop and exectue? wired!
#vhd_makebootable $vhd_letter
vhd_active $vhd_file
vhd_detach $vhd_file