. ../../lib/core.sh
. _test_create_vm_common.sh

FLOPPY=$HOME/Downloads/floppy.img
FILE=$HOME/Downloads/preseed.cfg

if [[ ! -f "${FLOPPY}" ]]; then
    floppy_create_win $(to_win_path $FLOPPY)
fi

if [[ -f "$FILE" ]]; then
    floppy_copy_file_win ${FLOPPY} ${FILE}
fi
