cd ../../vbox
. mybox.sh
_get_all_vbox_used_fowarding_ports

echo get from vm test1
_get_vbox_fowarding_port test1

_get_all_vbox_fowarding_rules

echo get fowarding rule for test1
_get_vbox_fowarding_rule test1

_get_mybox_guestssh_fowarding_port test1
