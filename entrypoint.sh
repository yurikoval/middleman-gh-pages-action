#!/bin/bash

set -e

echo 'Installing bundles...'
cd ${INPUT_SITE_LOCATION}
gem install bundler
bundle install
bundle list | grep "middleman ("

echo 'Building site...'
bundle exec middleman build

echo 'Publishing site...'
cd ${INPUT_BUILD_LOCATION}

if [[ -n "${INPUT_CUSTOM_DOMAIN}" ]]; then
  echo 'Creating CNAME file using the custom domain variable'
  echo  ${INPUT_CUSTOM_DOMAIN} > CNAME
fi

remote_repo="https://${INPUT_GITHUB_ACTOR}:${INPUT_GITHUB_TOKEN}@github.com/${INPUT_GITHUB_REPOSITORY}.git" && \
remote_branch=${INPUT_REMOTE_BRANCH}
git init
git config user.name "${INPUT_GITHUB_ACTOR}"
git config user.email "${INPUT_GITHUB_ACTOR}@users.noreply.github.com"
git add .
echo -n 'Files to Commit:'
ls -l | wc -l
echo 'Committing files...'
git commit -m'Middleman build' > /dev/null 2>&1

default_branch=`git rev-parse --abbrev-ref HEAD`

echo "Pushing... to $remote_repo $default_branch:$remote_branch"
git push --force $remote_repo $default_branch:$remote_branch > /dev/null 2>&1
echo "Removing git..."
rm -fr .git
cd -
echo 'Done'
