. ./_test_create_vm_common.sh
function test_setup_tftp_folder()
{
    NAME=centos6
    setup_tftp_folder "" "http://10.0.2.2:8088"
}

test_setup_tftp_folder