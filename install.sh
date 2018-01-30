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
GIT_VERSION="$(git --version)"
GIT_DIR="$(git rev-parse --git-dir)"
GIT_WORKING_DIR="$(git rev-parse --show-toplevel)"
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
GIT_POST_MERGE_HOOK=$GIT_HOOKS_PATH/post-merge
[ -f "$GIT_POST_CHECKOUT_HOOK" ]
GIT_POST_CHECKOUT_HOOK_EXISTS=$?
[ -f "$GIT_POST_POST_MERGE_HOOK" ]
GIT_POST_MERGE_HOOK_EXISTS=$?
ENV_FILE=""
if [ -f "$GIT_WORKING_DIR/.env" ] ; then
  ENV_FILE=".env"
fi
TEMPLATE_ENV=""
if [ -f "$GIT_WORKING_DIR/.env.example" ] ; then
  TEMPLATE_ENV=".env.example"
fi
if [ -f "$GIT_WORKING_DIR/.example.env" ] ; then
  TEMPLATE_ENV=".example.env"
fi
if [ -f "$GIT_WORKING_DIR/.env.EXAMPLE" ] ; then
  TEMPLATE_ENV=".env.EXAMPLE"
fi
if [ -f "$GIT_WORKING_DIR/env.example" ] ; then
  TEMPLATE_ENV="env.example"
fi
if [ -f "$GIT_WORKING_DIR/example.env" ] ; then
  TEMPLATE_ENV="example.env"
fi
if [ -f "$GIT_WORKING_DIR/EXAMPLE.env" ] ; then
  TEMPLATE_ENV="EXAMPLE.env"
fi
set -e

if [ ! -d "$GIT_DIR" ]; then
  echo "FATAL: Current directory is not a Git repository."
  echo "Exit."
  exit 1
fi

echo "INFO: You are running Bash version $BASH_VERSION."
echo "INFO: Bash version >= 4 is required by this script."
if [[ "$GIT_HOOKS_PATH_REL" != "" ]] ; then
  echo "INFO: $GIT_VERSION detected. If you are running"
  echo "INFO: a version < 2.9 and have the core.hooksPath"
  echo "INFO: configuration set, changes might not have the"
  echo "INFO: effect desired."
fi
echo "INFO: Installing to $GIT_HOOKS_PATH/post-checkout and /post-merge"
if (( GIT_POST_CHECKOUT_HOOK_EXISTS == 0 )) ; then
  if [ -x "$(command -v grep)" ] ; then
    if grep -q -e "prettify-env.sh" -e "update-env.sh" "$GIT_HOOKS_PATH/post-checkout" ; then
      echo ".env file updater seems already being installed in post-checkout hook."
      echo "Please uninstall prior to re-installing. Exit."
      exit 1
    fi
  fi
  echo "File post-checkout will amended"
else
  echo "File post-checkout will be created"
  mkdir -p $GIT_HOOKS_PATH
fi
if (( GIT_POST_MERGE_HOOK_EXISTS == 0 )) ; then
  if [ -x "$(command -v grep)" ] ; then
    if grep -q -e "prettify-env.sh" -e "update-env.sh" "$GIT_HOOKS_PATH/post-merge" ; then
      echo ".env file updater seems already being installed in post-merge hook."
      echo "Please uninstall prior to re-installing. Exit."
      exit 1
    fi
  fi
  echo "File post-merge will amended"
else
  echo "File post-merge will be created"
  mkdir -p $GIT_HOOKS_PATH
fi

echo "Which file would you like to keep updated by .env updater?"
if [[ "$1" != "test_run" ]]; then
  read -e -p "File to keep updated: " -i "$ENV_FILE" NEW_ENV_FILE </dev/tty
else
  read -e -p "File to keep updated: " -i "$ENV_FILE" NEW_ENV_FILE
fi
ENV_FILE="${NEW_ENV_FILE:-$ENV_FILE}"

if [ ! -f "$GIT_WORKING_DIR/$ENV_FILE" ] ; then
  echo "$GIT_WORKING_DIR/$ENV_FILE does not exist. Exit."
  exit 1
fi

echo "Which file should serve as a template?"
if [[ "$1" != "test_run" ]]; then
  read -e -p "Template: " -i "$TEMPLATE_ENV" NEW_TEMPLATE_ENV </dev/tty
else
  read -e -p "Template: " -i "$TEMPLATE_ENV" NEW_TEMPLATE_ENV
fi
TEMPLATE_ENV="${NEW_TEMPLATE_ENV:-$TEMPLATE_ENV}"

if [ ! -f "$GIT_WORKING_DIR/$TEMPLATE_ENV" ] ; then
  echo "$GIT_WORKING_DIR/$TEMPLATE_ENV does not exist. Exit."
  exit 1
fi

echo "There are two scripts, which can be installed:"
echo "One that adds new configuration to the bottom of your"
echo "$ENV_FILE file (update-env.sh)"
echo "and one that rewrites the entire file each time from"
echo "its template $TEMPLATE_ENV (prettify-env.sh)."
echo "Which one would you like to install?"
echo "1: update-env.sh, 2: prettify-env.sh"
if [[ "$1" != "test_run" ]]; then
  read -e -p "Install: " -i "1" SCRIPT </dev/tty
else
  read -e -p "Install: " -i "1" SCRIPT
fi

if [[ "$SCRIPT" == "1" ]] ; then
  SCRIPT="update-env.sh"
elif [[ "$SCRIPT" == "2" ]] ; then
  SCRIPT="prettify-env.sh"
elif [[ "$SCRIPT" == "" ]] ; then
  SCRIPT="update-env.sh"
fi

echo "Obtaining script ..."
wget -O "$GIT_HOOKS_PATH/$SCRIPT" "$MIRROR_BASE/$SCRIPT"
chmod +x "$GIT_HOOKS_PATH/$SCRIPT"

echo "Installing ..."

for HOOK_SCRIPT in "$GIT_POST_CHECKOUT_HOOK" "$GIT_POST_MERGE_HOOK"; do
  echo "Doing $HOOK_SCRIPT ..."
  if [ ! -f "$HOOK_SCRIPT" ] ; then
  cat >$HOOK_SCRIPT <<EOL
#!/bin/sh
#
# After you run a successful git checkout, the post-checkout hook runs;
# you can use it to set up your working directory properly for your
# project environment. This may mean moving in large binary files that
# you don’t want source controlled, auto-generating documentation, or
# something along those lines.
EOL
  fi

  SCRIPT_ABSOLUTE="$(cd "$(dirname "$GIT_HOOKS_PATH/$SCRIPT")"; pwd)/$(basename "$GIT_HOOKS_PATH/$SCRIPT")"
  echo "" >> $HOOK_SCRIPT
  echo "# https://github.com/Rillke/Docker-env-file-update" >> $HOOK_SCRIPT
  echo "# Whenever checking out a different version, make sure, .env files are up-to-date" >> $HOOK_SCRIPT
  echo "# Fixing Git not allowing input from STDIN: https://stackoverflow.com/a/10015707/2683737" >> $HOOK_SCRIPT
  echo "exec < /dev/tty" >> $HOOK_SCRIPT
  echo "$SCRIPT_ABSOLUTE '$TEMPLATE_ENV' '$ENV_FILE'" >> $HOOK_SCRIPT
  echo "exec <&-" >> $HOOK_SCRIPT
  chmod +x "$HOOK_SCRIPT"
done
echo "Done."

