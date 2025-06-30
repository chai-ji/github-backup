# github backups


```bash
brew install jq gh

# login to gh with fine-grained personal access token;
# generate PAT https://github.com/settings/personal-access-tokens
# # Repository: contents - read only ; metadata - read only
# # Account: Profile - read only ; Git ssh keys - read only
gh auth login
git auth status

```