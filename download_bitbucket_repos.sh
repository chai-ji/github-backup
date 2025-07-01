#!/bin/bash
set -euo pipefail

# USAGE:
# ./download_bitbucket_repos.sh bitbucket_repos.txt

# bitbucket_repos.txt in the format of TSV;
# username/reponame	ProjectID	git@bitbucket.org:username/reponame.git

# TODO: figure out how to incorporate projectID

LIST="$1" # bitbucket_repos.txt
BASE_DIR=$PWD
DOMAIN=bitbucket.org

while IFS=$'\t' read -r owner_repo projectID repo_url; do
    echo "-----------"
    echo "owner_repo: $owner_repo, projectID: $projectID, repo_url: $repo_url"
    repo_path="${BASE_DIR}/${DOMAIN}/${owner_repo}.git"
    (set -x; git clone --mirror "$repo_url" "$repo_path")
done < "$LIST"