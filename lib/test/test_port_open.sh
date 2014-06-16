#!/bin/bash
source ../core.sh

function check_local(){
    if is_port_open "127.0.0.1" "$1"; then
        echo "$1 is open"
    else 
        echo "$1 not open"
    fi
}

time for port in {2200..2222}; do check_local $port; done