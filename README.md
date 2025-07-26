# Github Backup Scripts

Scripts to help you backup your repos from GitHub.

## Requirements

Install dependencies and log in with a PAT from GitHub

```bash
brew install jq gh

# login to gh with fine-grained personal access token;
# generate PAT https://github.com/settings/personal-access-tokens
# - Repository access: All repositories
# - Repository permissions: contents - read only ; metadata - read only
# - Account permissions: Profile - read only ; Git ssh keys - read only
gh auth login

# check login status
git auth status

```

- Note the GitHub API Limits described [here](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api?apiVersion=2022-11-28#primary-rate-limit-for-authenticated-users)

## Usage

Create a list of all your repos

```bash
./get_repos_lists.sh <username>
```
- this script will search all your commits to find repos, this might take several minutes to complete
- see notes about which repos are retrievable this way

Use the output file to download clones of all repos in the list

```bash
./download_repos.sh deduped_repos.txt
```

## NOTES

Fine Grained PAT cannot see membership in private Orgs, or private membership in some public Orgs. Need Classic Token for that (read:org).

- https://github.com/settings/tokens

need this for `gh api user/orgs` ; `gh api users/<username>/orgs` only shows public memberships