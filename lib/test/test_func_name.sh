function call2(){
    call1
}

function call1(){
    call
}

function call(){
    echo "callstack      : ${FUNCNAME[@]}"
    echo "callstack size : ${#FUNCNAME[@]}"
    echo "functions name : $FUNCNAME"
    echo -1 ${FUNCNAME[@]: -1}
    echo 0 ${FUNCNAME[0]}
    echo 1 ${FUNCNAME[1]}
    echo 2 ${FUNCNAME[2]}
    echo 3 ${FUNCNAME[3]}
    echo 4 ${FUNCNAME[4]}
    echo 5 ${FUNCNAME[5]}
}

call2 "test"