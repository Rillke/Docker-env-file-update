#!/usr/bin/env bash
#
# Setup script for
# https://github.com/Rillke/Docker-env-file-update
# Setup scripts handling the update of .env files consumed by Docker
# during deployment when checking out a different version 

set -e

MIRROR_BASE="https://raw.githubusercontent.com/Rillke/Docker-env-file-update/master"

echo "Installation of .env updater scripts"
echo "https://github.com/Rillke/Docker-env-file-update"
echo ""
echo "Scanning the environment ..."

set +e
BASH_VERSION="$(bash -c 'echo $BASH_VERSION')"
GIT_HOOKS_PATH="$(git config core.hooksPath)"
GIT_HOOKS_PATH="${GIT_HOOKS_PATH:-hooks}"
GIT_REPO_ROOT="$(git rev-parse --git-dir)"
GIT_POST_CHECKOUT_HOOK=$GIT_REPO_ROOT/$GIT_HOOKS_PATH/post-checkout
[ -f "$GIT_POST_CHECKOUT_HOOK" ]
GIT_POST_CHECKOUT_HOOK_EXISTS=$?
ENV_FILE=""
if [ -f ".env" ] ; then
  ENV_FILE=".env"
fi
TEMPLATE_ENV=""
if [ -f ".env.example" ] ; then
  TEMPLATE_ENV=".env.example"
fi
if [ -f ".example.env" ] ; then
  TEMPLATE_ENV=".example.env"
fi
if [ -f ".env.EXAMPLE" ] ; then
  TEMPLATE_ENV=".env.EXAMPLE"
fi
if [ -f "env.example" ] ; then
  TEMPLATE_ENV="env.example"
fi
if [ -f "example.env" ] ; then
  TEMPLATE_ENV="example.env"
fi
if [ -f "EXAMPLE.env" ] ; then
  TEMPLATE_ENV="EXAMPLE.env"
fi
set -e

if [ ! -d "$GIT_REPO_ROOT" ]; then
  echo "FATAL: Current directory is not a Git repository."
  echo "Exit."
  exit 1
fi

echo "INFO: You are running Bash version $BASH_VERSION."
echo "Bash version >= 4 is required by this script."
echo "Installing to $GIT_REPO_ROOT/$GIT_HOOKS_PATH/post-checkout"
if (( GIT_POST_CHECKOUT_HOOK_EXISTS == 0 )); then
  echo "File will amended"
else
  echo "File will be created"
fi

echo "Which file would you like to keep updated by .env updater?"
echo -n "[$ENV_FILE]"
read NEW_ENV_FILE < /dev/tty
ENV_FILE="${NEW_ENV_FILE:-$ENV_FILE}"

if [ ! -f "$ENV_FILE" ] ; then
  echo "$ENV_FILE does not exist. Exit."
  exit 1
fi

echo "Which file should serve as a template?"
echo -n "[$TEMPLATE_ENV]"
read NEW_TEMPLATE_ENV < /dev/tty
TEMPLATE_ENV="${NEW_TEMPLATE_ENV:-$TEMPLATE_ENV}"

if [ ! -f "$TEMPLATE_ENV" ] ; then
  echo "$TEMPLATE_ENV does not exist. Exit."
  exit 1
fi

echo "There are two scripts, which can be installed:"
echo "One that adds new configuration to the bottom of your"
echo "$ENV_FILE file (update-env.sh)"
echo "and one that rewrites the entire file each time from"
echo "its template $TEMPLATE_ENV (prettify-env.sh)."
echo "Which one would you like to install?"
echo -n "[1: update-env.sh, 2: prettify-env.sh]:"
read SCRIPT < /dev/tty

if [[ "$SCRIPT" == "1" ]] ; then
  SCRIPT="update-env.sh"
elif [[ "$SCRIPT" == "2" ]] ; then
  SCRIPT="prettify-env.sh"
elif [[ "$SCRIPT" == "" ]] ; then
  SCRIPT="update-env.sh"
fi

echo "Obtaining script ..."
wget -O "$GIT_REPO_ROOT/$SCRIPT" "$MIRROR_BASE/$SCRIPT"
chmod +x "$GIT_REPO_ROOT/$SCRIPT"

echo "Installing ..."
if [ ! -f "$GIT_POST_CHECKOUT_HOOK" ] ; then
  echo "#!/bin/sh" > $GIT_POST_CHECKOUT_HOOK
fi

SCRIPT_ABSOLUTE="$(cd "$(dirname "$GIT_REPO_ROOT/$SCRIPT")"; pwd)/$(basename "$GIT_REPO_ROOT/$SCRIPT")"
echo "$SCRIPT_ABSOLUTE '$TEMPLATE_ENV' '$ENV_FILE'" >> $GIT_POST_CHECKOUT_HOOK
chmod +x "$GIT_POST_CHECKOUT_HOOK"
echo "Done."
