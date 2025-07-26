#!/bin/bash
set -euo pipefail

# USAGE:
# ./download_bitbucket_repos.sh bitbucket_repos.txt

# bitbucket_repos.txt in the format of TSV;
# username/reponame	ProjectID	git@bitbucket.org:username/reponame.git

# TODO: figure out how to incorporate projectID

LIST="$1" # bitbucket_repos.txt
DOMAIN=bitbucket.org

BASE_DIR="${PWD}/repos"
mkdir -p "${BASE_DIR}"

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

while IFS=$'\t' read -r owner_repo projectID repo_url; do
    echo "-----------"
    echo "owner_repo: $owner_repo, projectID: $projectID, repo_url: $repo_url"
    repo_path="${BASE_DIR}/${DOMAIN}/${owner_repo}.git"
    git_clone_mirror "$repo_url" "$repo_path"
done < "$LIST"