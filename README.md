# A GitHub Action to Build and Deploy Middleman to Github Pages

A GitHub Action for building and deploying a Middleman repo to its `gh-pages` branch.

## Inputs

* `GITHUB_REPOSITORY`: Repo where built website will be published to
* `GITHUB_ACTOR`: Name of the deploy actor (defaults to `deploy`)
* `SITE_LOCATION`: Location of your Middleman project within the repo (defaults to project root)
* `REMOTE_BRANCH`: Name of the branch to push the project to (detaults to `gh-pages`)

## Example

Add this to `.github/workflows/gh-pages.yml` of your project.

```yaml
name: Middleman

on:
  push:
    branches: [master]

jobs:
  build_and_deploy:
    name: Build & Deploy
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v1
      - name: Build & Deploy to GitHub Pages
        with:
          GITHUB_REPOSITORY: me/my_repo
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        uses: yurikoval/middleman-gh-pages-action@master
```
