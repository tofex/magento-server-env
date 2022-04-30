#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message

Example: ${scriptName}
EOF
}

trim()
{
  echo -n "$1" | xargs
}

while getopts h? option; do
  case "${option}" in
    h) usage; exit 1;;
    ?) usage; exit 1;;
  esac
done

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

echo ""
echo "Please specify the name of the system, followed by [ENTER]:"
read -r -i server -e systemName

echo ""
echo "Please specify the id of the project, followed by [ENTER]:"
read -r -e projectId

./init-system.sh \
  -n "${systemName}" \
  -p "${projectId}"
