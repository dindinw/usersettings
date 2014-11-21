cd ../../vbox
. mybox.sh

function test_check_ports(){
	for p in $@ ;do
	    if _check_port_usable $p; then
	        echo $p is usable
	    else
	        echo $p not usable
	    fi
	done
}

LOG_LEVEL=5
echo current range is $MYBOX_USABLE_PORT_RANGE
test_check_ports 2210 2250 2267 2370

MYBOX_USABLE_PORT_RANGE="2200..2210"
echo current range is $MYBOX_USABLE_PORT_RANGE
test_check_ports 2200 2210 2250 2267 2370 220 22

_VBOX_USED_PORT_LIST="2200,2201"
echo but now some ports [$_VBOX_USED_PORT_LIST] has been used 
test_check_ports 2200 2201 2202 2210 2250 2267 2370 220 22

MYBOX_USABLE_PORT_RANGE="2200..2300"
echo current range is $MYBOX_USABLE_PORT_RANGE
echo but now some ports [$_VBOX_USED_PORT_LIST] has been used 
echo "Try Vagrant ports range {2200..2250}"
for p in {2200..2250};do test_check_ports $p ; done