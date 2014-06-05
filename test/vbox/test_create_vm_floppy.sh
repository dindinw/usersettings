. ../../lib/core.sh
. _test_create_vm_common.sh

FLOPPY=$HOME/Downloads/floppy.img
FILE=$HOME/Downloads/preseed.cfg

if [[ ! -f "${FLOPPY}" ]]; then
    create_floppy_image_win $(to_win_path $FLOPPY)
fi

if [[ -f "$FILE" ]]; then
    copy_file_to_floppy_image ${FLOPPY} ${FILE}
fi
