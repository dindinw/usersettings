#!/usr/bin/env bash
USAGE="mygit.sh <folder> [parameters]
    -a,--action  sync|push|add
                 sync: sync local with upstream commit
                 push: push to origin if local ahead
                 add : add upstream url by origin's parent
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
function add_upstream() {
    # local all_urls=`curl -s https://api.github.com`
    # echo "$all_urls"
    # local current_user_url=`echo "$all_urls" |jq -r .current_user_url`
    # echo $current_user_url
    local add_upstream=0;
    local origin_url=`git remote get-url origin 2>/dev/null`
    if [[ ! -z ${origin_url} ]]; then
        local upstream_url=$(git remote get-url upstream 2>/dev/null)
        if [[ ! -z ${upstream_url} ]]; then
            echo "upstream already exist"
            add_upstream=1;
        else
            case ${origin_url} in
                *github.com*)
                    echo "origin_url  : ${origin_url}"
                    local repo=$(basename $origin_url|sed s'/.git//')
                    local owner=$(basename $(dirname $origin_url))
                    echo "owner       : $owner"
                    echo "repository  : $repo"
                    local repository_url="https://api.github.com/repos/{owner}/{repo}"
                    local repo_info_url=$(echo "$repository_url" | sed s/\{owner\}/$owner/ | sed s/\{repo\}/$repo/)
                    upstream_url=$(curl -s ${repo_info_url} | jq -r .parent.clone_url)
                    ;;
                *)
                    die "Unknown git vendor : $origin_url" ;;
            esac
        fi
        echo "upstream_url: $upstream_url"
        if [[ ${add_upstream} -eq 0 ]]; then
            git remote add upstream $upstream_url
        fi
    else
        die "No remote origin found"
    fi
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
    local cur_branch=$(git branch |sed -n '/\* /s///p')
    if [[ ! $cur_branch == "master" ]]; then
        echo "Current branch is not in master but in $cur_branch"
        git checkout master;
    fi
    git fetch upstream
    git merge upstream/master
    cd ..
}
force=0
if [ -z $1 ]; then usage; fi;
while (( "$#" )); do
    case $1 in
        .)
            folders="$folders `pwd`"
            shift;;
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
            push|push_orgin)
                push_origin $folder $force ;;
            sync|sync_upstream)
                sync_upstream $folder ;;
            add|add_upstream)
                add_upstream $folder;;
            *)
                die "Unknown action : $action"
        esac
    done
else
    usage
fi


