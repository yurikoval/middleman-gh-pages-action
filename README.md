# A GitHub Action to Build and Deploy Middleman to Github Pages

A GitHub Action for building and deploying a Middleman repo to its `gh-pages` branch.

## Inputs

* `GITHUB_REPOSITORY`: Repo where built website will be published to (optional, defaults to repo name)
* `BUILD_LOCATION`: Location where Middleman builds your website (optional, defaults to `build`)
* `GITHUB_ACTOR`: Name of the deploy actor (optional, defaults to `deploy`)
* `REMOTE_BRANCH`: Name of the branch to push the project to (optional, detaults to `gh-pages`)
* `SITE_LOCATION`: Location of your Middleman project within the repo (optional, defaults to project root)
* `CUSTOM_DOMAIN`: Custom domain used to create the CNAME file in the root directory (optional, no CNAME is created if value is not set)

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
        uses: yurikoval/middleman-gh-pages-action@master
```
