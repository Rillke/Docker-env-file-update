#!/usr/bin/env bash

cd "$(dirname "$0")"

GIT_DIR="$(git rev-parse --git-dir)"
GIT_HOOKS_PATH="$(git config core.hooksPath)"
GIT_HOOKS_PATH_REL=$GIT_HOOKS_PATH
if [ -z "$GIT_HOOKS_PATH" ] ; then
  GIT_HOOKS_PATH="$GIT_DIR/hooks"
else
  # Expand strings like $GIT_DIR/hooks
  # but GIT_HOOKS_PATH can be also relative to where
  # the hook runs or an absolute path
  GIT_HOOKS_PATH=$(eval echo $GIT_HOOKS_PATH)
fi
GIT_POST_CHECKOUT_HOOK=$GIT_HOOKS_PATH/post-checkout

function uninstall {
  rm $GIT_POST_CHECKOUT_HOOK
}

# Test installation script
echo "Testing installation script"
set +e
uninstall
set -e
../install.sh < install-input-1
uninstall
../install.sh < install-input-2
uninstall

# Test update-env
echo "Testing update-env"
../update-env.sh ./.env.example ./.env <<< "BAR3=BAZ3\n"
git checkout -- .env

# Test prettify-env
echo "Testing prettify-env"
../update-env.sh ./.env.example ./.env <<< "BAR3=BAZ3\n"
git checkout -- .env

