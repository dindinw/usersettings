. ./_test_create_vm_common.sh

# May a bind error if the port is occupied.
function test_setup_kickstart_service() 
{
setup_kickstart_service 10.0.2.2 8081 ks_centos.cfg
if [ $? -eq 1 ]; then
    echo "kickstart_service start error"
    exit 1
fi 
}

test_setup_kickstart_service