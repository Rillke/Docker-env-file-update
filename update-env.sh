#!/usr/bin/env bash
#
# Update a Docker .env file from an example/template file
# More information on docker .env files:
#    https://docs.docker.com/compose/env-file/
#
# Usage:
#   ./update-env.sh template-file file-to-update
# Example:
#   ./update-env.sh .env.example .env

set -e
echo ".env file updater"
echo "https://github.com/Rillke/Docker-env-file-update"

if [ $# -eq 0 ] || [ $1 = "-h" ] || [ $1 = "--help" ] ; then
  echo "After deployments, Docker .env files may need updates."
  echo "This updater automates that process."
fi

if [ $# -ne 2 ] ; then
        echo "Invalid number of arguments supplied. Expected 2, got $#."
	echo "Usage: $0 <template-file> <file-to-update>"
	exit 1
fi

if [ ! -f "$1" ]
then
	echo "template-file ($1) does not exist."
        echo "Usage: $0 <template-file> <file-to-update>"
	exit 1
fi

if [ ! -f "$2" ]
then
        echo "file-to-update ($2) does not exist."
        echo "Usage: $0 <template-file> <file-to-update>"
        exit 1
fi

HELP=""
declare -A VARS_IN_FILE_TO_UPDATE
declare -A VARS_IN_TEMPLATE_FILE

function extractKey {
  K="$1"
  NEW_K="${K%=*}"
  while [[ "$K" != "$NEW_K" ]]; do
    K=$NEW_K
    NEW_K="${K%=*}"
  done
  echo "$K"
}

# Collect variables currently in use
while read f; do
  if [[ "$f" != \#* ]] && [[ "$f" == *\=* ]] ; then
    K="$(extractKey $f)"
    V="${f#*=}"
    VARS_IN_FILE_TO_UPDATE["$K"]="$V"
  fi
done <"$2"

# Check for new variables
echo "Checking for new variables ..."
while read e; do
  if [[ "$e" == \#* ]] ; then
    if [ -n "$HELP" ] ; then
      HELP="$HELP\n$e"
    else
      HELP="$e"
    fi
  elif [[ "$e" == *\=* ]] ; then
    K="$(extractKey $e)"
    V="${e#*=}"
    VARS_IN_TEMPLATE_FILE["$K"]="$V"
    if ! test "${VARS_IN_FILE_TO_UPDATE[${K}]+isset}"; then
      # Variable is not in file-to-update, ask user to supply value
      echo "Please supply a value for: $K:"
      if [ -n "$HELP" ] ; then
        echo -e "$HELP"
      fi
      echo -n "New value for $K [$V]="
      read NEW_V < /dev/tty
      NEW_V="${NEW_V:-$V}"
      echo "# Added by $USER on `date`" >> $2
      echo -e "$HELP" >> $2
      echo "$K=$NEW_V" >> $2
    fi
    HELP=""
  fi
done <"$1"

echo "Checking for obsolete variables ..."
for K in "${!VARS_IN_FILE_TO_UPDATE[@]}"
do
  if ! test "${VARS_IN_TEMPLATE_FILE[${K}]+isset}"; then
    echo "Variable $K with value ${VARS_IN_FILE_TO_UPDATE[$K]} might be obsolete."
  fi
done

echo "Done."

