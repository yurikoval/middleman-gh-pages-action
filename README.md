# A GitHub Action to Build and Deploy Middleman to Github Pages

A GitHub Action for building and deploying a Middleman repo to its `gh-pages` branch.

## Inputs

* `GITHUB_ACTOR`: Name of the deploy actor (optional, defaults to `deploy`)
* `GIT_PUSH_DRY_RUN`: Test the git push action, (optional, defaults to `''`)
* `SITE_LOCATION`: Location of your Middleman project within the repo (optional, defaults to project root)
* `BUILD_LOCATION`: Location where Middleman builds your website (optional, defaults to `build`)
* `REMOTE_BRANCH`: Branch to push the built docs to (optional, defaults to `gh-pages`)

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
          REMOTE_BRANCH: gh-pages
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        uses: zooniverse/middleman-gh-pages-action@master
```
