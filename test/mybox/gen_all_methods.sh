cd ../../vbox
. mybox.sh

function _to_upper_case()
{
    echo $1 | tr '[:lower:]' '[:upper:]'
}
function gen(){
    #gen help
echo 
echo "################################################################################"
echo "#" 
echo "# MYBOX HELPS COMMMANDS"
echo "#"
echo "################################################################################"
echo 
    for cmd_user in $MYBOX_CMDS; do
        echo "#=================================="
        echo "# FUNCTION help_mybox_${cmd_user} "
        echo "#=================================="
        gen_help1 $cmd_user
    done
    for cmd_subs in $MYBOX_SUBCMDS; do
        echo "#=================================="
        echo "# FUNCTION help_mybox_${cmd_subs} "
        echo "#=================================="
        gen_help1 $cmd_subs
        for subcmd in $(__get_subcommands $cmd_subs); do
            echo "#----------------------------------"
            echo "# FUNCTION help_mybox_${cmd_subs}_${subcmd} "
            echo "#----------------------------------"
            gen_help2 $cmd_subs $subcmd
        done
    done
    # gen func
echo
echo "################################################################################"
echo "#" 
echo "# MYBOX USER COMMMANDS"
echo "#"
echo "################################################################################"
echo
    
    for cmd_user in $MYBOX_CMDS; do
        echo "#=================================="
        echo "# FUNCTION mybox_$cmd_user "
        echo "#=================================="
        gen_func1 $cmd_user
    done
    for cmd_subs in $MYBOX_SUBCMDS; do
        echo
        echo '################################################################################'
        echo '#'
        echo "# MYBOX $(_to_upper_case $cmd_subs) COMMMANDS"
        echo '#'
        echo '################################################################################'
        echo
        echo "#=================================="
        echo "# FUNCTION mybox_${cmd_subs}"
        echo "#=================================="
        gen_func1 $cmd_subs
        echo
        for subcmd in $(__get_subcommands $cmd_subs); do
            echo "#----------------------------------"
            echo "# FUNCTION mybox_${cmd_subs}_${subcmd} "
            echo "#----------------------------------"
            gen_func2 $cmd_subs $subcmd
        done
    done
}

function gen_func1(){
    echo "function mybox_$1(){"
    echo '    _print_not_support $FUNCNAME $@'
    echo "}"
}
function gen_func2(){
    echo "function mybox_$1_$2(){"
    echo '    _print_not_support $FUNCNAME $@'
    echo "}"
}
$@
function gen_help1()
{
    echo "function help_mybox_$1(){"
    echo '    _print_not_support $FUNCNAME $@'
    echo "}"
}

function gen_help2()
{
    echo "function help_mybox_$1_$2(){"
    echo '    _print_not_support $FUNCNAME $@'
    echo "}"
}

gen