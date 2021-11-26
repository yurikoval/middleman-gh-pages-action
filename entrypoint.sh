#!/usr/bin/env bash
set -o errexit #abort if any command fails
me=$(basename "$0")

help_message="\
Usage: $me [-c FILE] [<options>]
Deploy generated files to a git branch.

Options:

  -h, --help               Show this help information.
  -v, --verbose            Increase verbosity. Useful for debugging.
  -e, --allow-empty        Allow deployment of an empty directory.
  -m, --message MESSAGE    Specify the message used when committing on the
                           deploy branch.
  -n, --no-hash            Don't append the source commit's hash to the deploy
                           commit's message.
"

parse_args() {
  # Set args from a local environment file.
  if [ -e ".env" ]; then
    source .env
  fi

  # Parse arg flags
  # If something is exposed as an environment variable, set/overwrite it
  # here. Otherwise, set/overwrite the internal variable instead.
  while : ; do
    if [[ $1 = "-h" || $1 = "--help" ]]; then
      echo "$help_message"
      return 0
    elif [[ $1 = "-v" || $1 = "--verbose" ]]; then
      verbose=true
      shift
    elif [[ $1 = "-e" || $1 = "--allow-empty" ]]; then
      allow_empty=true
      shift
    elif [[ ( $1 = "-m" || $1 = "--message" ) && -n $2 ]]; then
      commit_message=$2
      shift 2
    elif [[ $1 = "-n" || $1 = "--no-hash" ]]; then
      GIT_DEPLOY_APPEND_HASH=false
      shift
    else
      break
    fi
  done

  # Set internal option vars from the environment and arg flags. All internal
  # vars should be declared here, with sane defaults if applicable.

  # which local directory the middleman site is in
  site_directory=${INPUT_SITE_LOCATION:-}

  # test these git push changes via dry run
  git_push_dry_run=${INPUT_GIT_PUSH_DRY_RUN:-}

  # Source directory & target branch.
  deploy_directory=${INPUT_BUILD_LOCATION:-build}
  deploy_branch=${INPUT_REMOTE_BRANCH:-gh-pages}

  #if no user identity is already set in the current git environment, use this:
  default_username=${INPUT_GIT_USERNAME:-}
  default_email=${INPUT_GIT_EMAIL:-}

  #repository to deploy to. must be readable and writable.
  repo=origin

  #append commit hash to the end of message by default
  append_hash=${INPUT_GIT_DEPLOY_APPEND_HASH:-true}
}

main() {
  parse_args "$@"

  echo "Changing directory to ${site_directory}..."
  cd $site_directory

  echo 'Installing bundles...'
  # install the gems from the site dir Gemfile (middleman etc)
  bundle install

  echo 'Building clean...'
  # run a clean build
  bundle exec middleman build --clean

  enable_expanded_output

  echo 'Running git diff'
  if ! git diff --exit-code --quiet --cached; then
    echo Aborting due to uncommitted changes in the index >&2
    return 1
  fi

  commit_title=`git log -n 1 --format="%s" HEAD`
  echo "The commit title: ${commit_title}"
  commit_hash=` git log -n 1 --format="%H" HEAD`
  echo "The commit hash: ${commit_hash}"

  #default commit message uses last title if a custom one is not supplied
  if [[ -z $commit_message ]]; then
    commit_message="publish: $commit_title"
  fi

  #append hash to commit message unless no hash flag was found
  if [ $append_hash = true ]; then
    commit_message="$commit_message"$'\n\n'"generated from commit $commit_hash"
  fi

  echo "The commit message: ${commit_message}"

  previous_branch=`git rev-parse --abbrev-ref HEAD`

  if [ ! -d "$deploy_directory" ]; then
    echo "Deploy directory '$deploy_directory' does not exist. Aborting." >&2
    return 1
  fi

  # must use short form of flag in ls for compatibility with OS X and BSD
  if [[ -z `ls -A "$deploy_directory" 2> /dev/null` && -z $allow_empty ]]; then
    echo "Deploy directory '$deploy_directory' is empty. Aborting. If you're sure you want to deploy an empty tree, use the --allow-empty / -e flag." >&2
    return 1
  fi

  if git ls-remote --exit-code $repo "refs/heads/$deploy_branch" ; then
    # deploy_branch exists in $repo; make sure we have the latest version

    disable_expanded_output
    git fetch --force $repo $deploy_branch:$deploy_branch
    enable_expanded_output
  fi

  # check if deploy_branch exists locally
  if git show-ref --verify --quiet "refs/heads/$deploy_branch"
  then incremental_deploy
  else initial_deploy
  fi

  restore_head
}

initial_deploy() {
  echo 'Running the initial deploy as branch does not exist locally'
  git --work-tree "$deploy_directory" checkout --orphan $deploy_branch
  git --work-tree "$deploy_directory" add --all
  commit+push
}

incremental_deploy() {
  echo 'Running the incremental deploy as branch exists locally'
  #make deploy_branch the current branch
  git symbolic-ref HEAD refs/heads/$deploy_branch
  #put the previously committed contents of deploy_branch into the index
  git --work-tree "$deploy_directory" reset --mixed --quiet
  git --work-tree "$deploy_directory" add --all

  set +o errexit
  diff=$(git --work-tree "$deploy_directory" diff --exit-code --quiet HEAD --)$?
  set -o errexit
  case $diff in
    0) echo No changes to files in $deploy_directory. Skipping commit.;;
    1) commit+push;;
    *)
      echo git diff exited with code $diff. Aborting. Staying on branch $deploy_branch so you can debug. To switch back to master, use: git symbolic-ref HEAD refs/heads/master && git reset --mixed >&2
      return $diff
      ;;
  esac
}

commit+push() {
  echo 'Comitting changes to deploy branch'
  set_user_id
  git --work-tree "$deploy_directory" commit -m "$commit_message"

  echo "Pushing changes to remote target branch ${deploy_branch}"

  disable_expanded_output

  #--quiet is important here to avoid outputting the repo URL, which may contain a secret token
  git_push_options='--quiet'
  if [[ ! -z "${git_push_dry_run}" ]]; then
    git_push_options="--dry-run ${git_push_options}"
  fi

  echo git push $git_push_options $repo $deploy_branch
  # git push $git_push_options $repo $deploy_branch

  enable_expanded_output
}

#echo expanded commands as they are executed (for debugging)
enable_expanded_output() {
  if [ $verbose ]; then
    set -o xtrace
    set +o verbose
  fi
}

#this is used to avoid outputting the repo URL, which may contain a secret token
disable_expanded_output() {
  if [ $verbose ]; then
    set +o xtrace
    set -o verbose
  fi
}

set_user_id() {
  if [[ -z `git config user.name` ]]; then
    echo "Setting the git username ${default_username}"
    git config user.name "$default_username"
  fi
  if [[ -z `git config user.email` ]]; then
    echo "Setting the git email ${default_email}"
    git config user.email "$default_email"
  fi
}

restore_head() {
  if [[ $previous_branch = "HEAD" ]]; then
    #we weren't on any branch before, so just set HEAD back to the commit it was on
    git update-ref --no-deref HEAD $commit_hash $deploy_branch
  else
    git symbolic-ref HEAD refs/heads/$previous_branch
  fi

  git reset --mixed
}

filter() {
  sed -e "s|$repo|\$repo|g"
}

sanitize() {
  "$@" 2> >(filter 1>&2) | filter
}

[[ $1 = --source-only ]] || main "$@"
