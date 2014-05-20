. ../lib/core.sh

function extract_bootwim()
{
    local iso="$1"
    local output_dir="$2"
    7z_extract $iso "sources/boot.wim" $output_dir

}

function extract_installwim()
{
    local iso="$1"
    local output_dir="$2"
    7z_extract $iso "sources/install.wim" $output_dir
}

function 7z_extract() 
{
    local archive_name="$1"
    local extract_file_name="$2"
    local output_dir="$3"
    7z e $archive_name $extract_file_name -o$output_dir -y #2>&1>/dev/null
}


function wim_apply()
{
    local wim_file="$1"
    local img_index="$2"
    local apply_to="$3"
    local imagex_cmd="c:\Windows\Setup\Scripts\imagex /apply $(to_win_path $wim_file) ${img_index} $(to_win_path $apply_to) /check /verify"
    echo excuting ${imagex_cmd} ...
    start //wait cmd //c "$imagex_cmd"
}

# using diskpart to do this
function vhd_create()
{
    local vhd_name="$1"
    local size=${2:~25000}
    echo "vhd name : ${vhd_name}"
    echo "size : ${size}"

cat <<EOF > vhd_create.txt
create vdisk file="$(to_win_path ${vhd_name})" maximum=25000 type=expandable
     select vdisk file"$(to_win_path ${vhd_name})"
     attach vdisk
     create partition primary
     format quick FS=NTFS label=VHD
     detach vdisk
exit
EOF
    call_diskpart vhd_create.txt
}

function vhd_detach()
{
    local vhd_name="$1"

cat <<EOF > vhd_detach.txt
select vdisk file"$(to_win_path ${vhd_name})"
detach vdisk
exit
EOF
     call_diskpart vhd_detach.txt
}


function vhd_assign()
{
    local vhd_name="$1"
    local letter="$2"

#Note: the several recan commands after attach command to let diskpart wait for secs, 
#otherwise, the assign dirver letter may fail to 'no volume' error

cat <<EOF > vhd_assign.txt
select vdisk file"$(to_win_path ${vhd_name})"
    attach vdisk
    rescan
    rescan
    rescan
    rescan
    rescan
    rescan
    select partition 1
    assign letter=${letter}
    list vdisk
    list volume
exit
EOF
    call_diskpart vhd_assign.txt
}


function call_diskpart()
{
    local script="$1"
    Diskpart //s $script
    rm $script
}