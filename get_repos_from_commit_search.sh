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
# ./get_repos_from_commit_search.sh <username>

AUTHOR="$1"
START_DATE="2015-01-01" # Joined GitHub on January 12, 2015
STEP_DAYS=60 # need small step size to help avoid API rate limits
END_DATE=$(date +"%Y-%m-%d")
OUT_FILE="commit_repos.txt"
SORTED_FILE="deduped_repos.txt"
printf '' > "$OUT_FILE"

get_date () {
    local CURRENT="$1"
    local DAYS="$2"

    if date --version >/dev/null 2>&1; then
        # Linux
        date -d "${CURRENT} +$DAYS days" "+%Y-%m-%d"
    else
        # macOS
        date -j -v+${DAYS}d -f "%Y-%m-%d" "$CURRENT" "+%Y-%m-%d"
    fi
}

echo "Searching commits by $AUTHOR from $START_DATE to $END_DATE in steps of $STEP_DAYS days..."

current="$START_DATE"
while [[ "$current" < "$END_DATE" ]]; do

    next="$(get_date "$current" "$STEP_DAYS" )"
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

sort -u "$OUT_FILE" > "$SORTED_FILE"

