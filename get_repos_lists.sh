#!/bin/bash
set -euo pipefail

# find all git repos with commits from AUTHOR
# by search for all commits by AUTHOR
# need to step through fine-grained date filters for search
# because GitHub search commits query is NOT paginated and
# will ONLY return 1000 results, ever
# so need to use a STEP_DAYS periods small enough that no result would ever have >1000 commits
# we will retrieve the full URL to each commit, then strip it down to the repo

# also, we need to slow down the search loop because of API rate limits
# so this script might take several minutes to complete

# also, we try to skip Fork's of our repos that others have made
# but some still show up if the Fork-er got GitHub to disassociate the fork with the original repo
# this also causes our own forks of other repos to not show up in the results too

# USAGE:
# ./get_repos_lists.sh <username>


# TODO:
# - repos in other orgs that AUTHOR contributed to (which themselves might be forks of other repos)
# - repos owned by AUTHOR on their own profile that are forks of other repos
# - exclude other users' forks of author's repos
# - repos in orgs that are private or which AUTHOR has private membership
#   - this might not be possible with fine grain PAT

AUTHOR="$1"
DEFAULT_START_DATE="2015-01-01" # Joined GitHub on January 12, 2015
START_DATE="${START_DATE:-${DEFAULT_START_DATE}}"
STEP_DAYS=60 # need small step size to help avoid API rate limits
END_DATE=$(date +"%Y-%m-%d")
OUT_FILE="commit_repos.txt"
OWNER_FILE="owner_repos.txt"
SORTED_FILE="deduped_repos.txt"
printf '' > "$OUT_FILE"

get_date () {
    # get the current date plus some number of days
    local CURRENT="$1" # YYYY-MM-DD
    local DAYS="$2"

    if date --version >/dev/null 2>&1; then
        # Linux
        date -d "${CURRENT} +$DAYS days" "+%Y-%m-%d"
    else
        # macOS
        date -j -v+${DAYS}d -f "%Y-%m-%d" "$CURRENT" "+%Y-%m-%d"
    fi
}

# find repos based on commits
# this excludes repos that the AUTHOR owns which were forked from other repos
git_search_commits () {
    echo "Searching commits by $AUTHOR from $START_DATE to $END_DATE in steps of $STEP_DAYS days..."

    local current="$START_DATE"
    while [[ "$current" < "$END_DATE" ]]; do

        local next="$(get_date "$current" "$STEP_DAYS" )"
        echo "Searching from $current to $next..."

        (
            # set -x
            gh search commits \
        --author "$AUTHOR" \
        --committer-date "$current..$next" \
        --json repository \
        --limit 1000 |
        jq -r 'map(select(.repository.isFork == false)) | .[].repository.url' | sed -e 's|^https://||g' >> "$OUT_FILE" || true
        )

        current="$next"

        sleep 5 # throttle to avoid 403 errors API rate limit
    done

}

git_repo_list () {
    gh repo list "$AUTHOR" --limit 1000 --json url --jq '.[].url' | sed -e 's|^https://||g' > "$OWNER_FILE"
}

git_search_commits
git_repo_list


sort -u "$OUT_FILE" > "$SORTED_FILE"
sort -u "$OWNER_FILE" >> "$SORTED_FILE"
sort -u "$SORTED_FILE" > tmp && /bin/mv tmp "$SORTED_FILE"