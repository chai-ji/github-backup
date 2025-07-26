#!/bin/bash
set -euo pipefail

# Create an app password ; https://bitbucket.org/account/settings/app-passwords/
#
# Permissions;
#
# Account: Read
# Repository: Read
#
# save it as TOKEN to file ~/.bitbucket/token.txt

# USAGE:
# ./get_bitbucket_repos_list.sh <username> "$(cat ~/.bitbucket/token.txt)"

# NOTE:
# https://bitbucket.status.atlassian.com/
# https://support.atlassian.com/bitbucket-cloud/docs/api-request-limits/

USERNAME="$1"
DEFAULT_WORKSPACE="$USERNAME"
WORKSPACE="${WORKSPACE:-${DEFAULT_WORKSPACE}}"
TOKEN="$2"
OUT_FILE="bitbucket_repos.txt"
printf '' > "$OUT_FILE"
mkdir -p json

# test the API with this request
# JSON="$(curl -u "$USERNAME:$TOKEN" https://api.bitbucket.org/2.0/user)"

echo "Getting repos from ${WORKSPACE}"

# the API is really lousy so do small pages or it might break...
page=1
NEXT="https://api.bitbucket.org/2.0/repositories/${WORKSPACE}?pagelen=10"
while [[ -n "$NEXT" ]]; do
    echo "getting page $page"
    RESPONSE=$(curl -s -u "$USERNAME:$TOKEN" "$NEXT")
    echo "$RESPONSE" | jq . > "json/bitbucket.${page}.json"
    echo "$RESPONSE" | jq -r '.values[] | . as $repo | $repo.links.clone[] | select(.name == "ssh") | [$repo.full_name, $repo.project.name, .href] | @tsv' >> "$OUT_FILE"
    NEXT=$(echo "$RESPONSE" | jq -r '.next // empty')
    ((page++))
    sleep 1
done


