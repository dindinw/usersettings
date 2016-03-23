#!/usr/bin/env bash
USAGE="mygit.sh <folder> [parameters]
    -a,--action  sync|push
                 sync: sync local with upstream commit
                 push: push to origin if local ahead
    -f           force
"
function confirm(){
    local msg="$1"
    read -r -p "$msg ? [yes/no] " -s confirm
    echo
    case "${confirm}" in 
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}
function die(){
    echo "Error: $*"
    exit 1
}
function usage() {
    echo "$USAGE"
    exit 0
}
function push_origin() {
    local folder=$1
    local force=$2
    cd $folder
    if [[ ! -d .git ]]; then
        cd ..
        die "$folder is not a git repository."
    fi
    commits=`git rev-list --left-right origin/master...HEAD 2>/dev/null`
    commit=
    behind=0
    ahead=0
    if [[ ! -z "$commits" ]]; then
        for commit in $commits; do
            case "$commit" in
                ">"*) ((ahead ++)) ;;
                *) ((behind ++)) ;;
            esac
        done
        if [ ${ahead} -gt 0 ]; then
            echo "$folder is ahead of 'origin/master' by $ahead commits."
            if [[ "$force" -eq 1 ]] || confirm "are you want to push"; then
                echo "push $folder..."
                git push origin
            fi
        fi
        if [ ${behind} -gt 0 ]; then
            echo "$folder is behind of 'origin/master' by $behind commits."
        fi
    else
        echo "$folder is even."
    fi
    cd ..
}
function sync_upstream(){
    local folder=$1
    cd ${folder}
    echo "Sync with upstream for $folder ..."
    git checkout master
    git fetch upstream
    git merge upstream/master
    cd ..
}
force=0
if [ -z $1 ]; then usage; fi;
while (( "$#" )); do
    case $1 in
        [./a-zA-Z]*)
            if [[ ! -d $1 ]]; then
                die "$1 not a folder"
            fi
            folders="$folders $1"
            shift;;
        -a|--action)
            shift
            action=$1
            shift;;
        -f)
            force=1 
            shift;;
        -h|--help)
            usage;;
        *)
            die "Unknown parameter: $1"
    esac
done
# echo "force=$force"
if [[ ! -z $folders ]]; then
    for folder in $folders; do
        case "$action" in
            push)
                push_origin $folder $force ;;
            sync)
                sync_upstream $folder ;;
            *)
                die "Unknown action : $action"
        esac
    done
else
    usage
fi


