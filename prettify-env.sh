#!/usr/bin/env bash
#
# Reformat a Docker .env file according to a example/template file
# More information on docker .env files:
#    https://docs.docker.com/compose/env-file/
#
# Reads environment variables from a target file, formats them
# as in the template file supplied and finally replaces the
# target file with the formatted file.
#
# Note: Any custom comments are lost after running this script
#
# Usage:
#   ./update-env.sh template-file file-to-beautify
# Example:
#   ./update-env.sh .env.example .env

set -e
echo ".env file prettifier"
echo "https://github.com/Rillke/Docker-env-file-update"

if [ $# -eq 0 ] || [ $1 = "-h" ] || [ $1 = "--help" ] ; then
  echo "Reformat a Docker .env file according to a example/template file."
  echo "More information on docker .env files:"
  echo "   https://docs.docker.com/compose/env-file/"
  echo ""
  echo "When contineously adding environment variables to a Docker .env file"
  echo "that file can become hard to read. .env file prettifier formats the"
  echo "target file according to a template."
  echo ""
  echo "Note: Any custom comments in <file-to-beautify> are lost after"
  echo "running this script"
  echo ""
fi

if [ $# -ne 2 ] ; then
        echo "Invalid number of arguments supplied. Expected 2, got $#."
	echo "Usage: $0 <template-file> <file-to-beautify>"
	exit 1
fi

if [ ! -f "$1" ]
then
	echo "template-file ($1) does not exist."
        echo "Usage: $0 <template-file> <file-to-beautify>"
	exit 1
fi

if [ ! -f "$2" ]
then
        echo "file-to-beautify ($2) does not exist."
        echo "Usage: $0 <template-file> <file-to-beautify>"
        exit 1
fi

declare -A VARS_IN_FILE_TO_UPDATE
declare -A VARS_IN_TEMPLATE_FILE
echo "Creating a temporary file ..."
tmp_file=$(mktemp)

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
echo "Collecting variables and their values in the current version of the target file ..."
while read f; do
  if [[ "$f" != \#* ]] && [[ "$f" == *\=* ]] ; then
    K="$(extractKey $f)"
    V="${f#*=}"
    VARS_IN_FILE_TO_UPDATE["$K"]="$V"
  fi
done <"$2"

# Write prettified file
echo "Writing prettified file ..."
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
      echo "New variable $K in template detected."
      echo "Please supply a value for: $K:"
      if [ -n "$HELP" ] ; then
        echo -e "$HELP"
      fi
      echo -n "New value for $K [$V]="
      read NEW_V < /dev/tty
      NEW_V="${NEW_V:-$V}"
      echo "$K=$NEW_V" >> ${tmp_file}
    else
      echo "$K=${VARS_IN_FILE_TO_UPDATE[${K}]}" >> ${tmp_file}
    fi
    HELP=""
  fi
  if [[ "$e" != *\=* ]] || [[ "$e" == \#* ]] ; then
    echo "$e" >> ${tmp_file}
  fi
done <"$1"

echo "Checking for obsolete variables ..."
echo "" >> ${tmp_file}
echo "# POSSIBLY OBSOLETE VARIABLES" >> ${tmp_file}
for K in "${!VARS_IN_FILE_TO_UPDATE[@]}"
do
  if ! test "${VARS_IN_TEMPLATE_FILE[${K}]+isset}"; then
    echo "$K=${VARS_IN_FILE_TO_UPDATE[$K]}" >> ${tmp_file}
  fi
done

mv ${tmp_file} $2

echo "Done."

