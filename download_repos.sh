#!/bin/bash
set -euo pipefail

# downloads git mirrors of all repos in the list file provided
#
# LIST file in the format of;
# github.com/owner/repo

# USAGE:
# ./download_repos.sh deduped_repos.txt

# TODO:
# - get relative path submodules that have url that starts with ../

LIST="$1" # deduped_repos.txt
BASE_DIR=$PWD

if [ ! -f "$LIST" ]; then
echo "$LIST file does not exist"
exit 1
fi

# clone a mirror of the source repo
git_clone_mirror () {
    local repo_url="$1"
    local repo_path="$2"
    echo "-----------"
    echo ">>> Retrieving ${repo_url}, saving to ${repo_path}"
    if [ ! -d "$repo_path" ]; then
        echo "Creating mirror clone..."
        (set -x; cd $BASE_DIR; git clone --mirror "$repo_url" "$repo_path")
    else
        echo "Fetching updates for existing mirror..."
        (set -x; cd $BASE_DIR; git --git-dir="$repo_path" fetch --all --prune)
    fi
}

# inspect the bare git mirror clone for submodules and clone those too
git_check_for_submodules () {
    local repo_path="$1"
    (
        cd "$repo_path"
        # check if dir has git submodules
        if git show HEAD:.gitmodules 1>/dev/null 2>/dev/null; then
            echo ">>> there are submodules at $repo_path"
            # get the submodules
            local submodules="$(git show HEAD:.gitmodules | grep url | sed -e 's|.*url = ||g')"
            # iterate over every submodule in the list
            for submodule in $submodules; do
                echo ">>> submodule: ${submodule}"
                case "$submodule" in
                    git@*)
                        echo ">>> its a git ssh submodule: $submodule"
                        local submodule_path="$(echo "${submodule}" | sed -e 's|git@||g' -e 's|:|/|g')"
                        submodule_path="${BASE_DIR}/${submodule_path}"
                        echo ">>> submodule_path: $submodule_path"
                        git_clone_mirror "$submodule" "$submodule_path"
                        ;;
                    http*)
                        echo ">>> its http submodule: $submodule"
                        local submodule_path="$(echo "${submodule}" | sed -e 's|http.*://||g' )"
                        submodule_path="${BASE_DIR}/${submodule_path}.git"
                        echo ">>> submodule_path: $submodule_path"
                        git_clone_mirror "$submodule" "$submodule_path"
                        ;;
                    *)
                        echo ">>> dont have a handler for this type of submodule"
                        # TODO: relative path submodules that start with "../" go here
                        ;;
                esac
            done
        fi
    )
}

# clone all the repos in the list
while IFS="/" read -r domain owner repo; do
    echo "domain: $domain , owner: $owner , repo: $repo" # github.com username reponame
    repo_parent_dir="${domain}/${owner}" # github.com/username
    repo_path="${BASE_DIR}/${repo_parent_dir}/${repo}.git" # $PWD/github.com/username/reponame.git
    repo_url="git@${domain}:${owner}/${repo}.git" # git@github.com:username/reponame.git

    git_clone_mirror "$repo_url" "$repo_path"
    git_check_for_submodules "$repo_path"
done < "$LIST"