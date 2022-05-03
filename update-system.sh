#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -p  Project id (optional)

Example: ${scriptName} -n magento
EOF
}

trim()
{
  echo -n "$1" | xargs
}

projectId=

while getopts hp:? option; do
  case "${option}" in
    h) usage; exit 1;;
    p) projectId=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

if [[ -n "${projectId}" ]] && [[ "${projectId}" != "-" ]]; then
  ini-set "${currentPath}/../env.properties" yes system projectId "${projectId}"
fi
