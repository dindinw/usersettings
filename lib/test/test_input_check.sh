#!/bin/bash
source ../core.sh

function test_number_check(){
	if is_number $1; then
		echo "$1 is a number"
	else
		echo "$1 not a number."
	fi
}

function test_port_check(){
	if is_port $1; then
		echo "$1 is a port number"
	else
		echo "$1 not a port number"
	fi
}

for n in 1 3 5 sdf s12.34 13.2 -12 323; do test_number_check $n ; done;
for n in 1 3 5 sdf s12.34 13.2 -12 323 65536 65535; do test_port_check $n ; done;