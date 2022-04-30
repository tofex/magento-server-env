#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -n  System name, default: system
  -p  Project id (optional)

Example: ${scriptName} -n magento
EOF
}

trim()
{
  echo -n "$1" | xargs
}

systemName=
projectId=

while getopts hn:p:? option; do
  case "${option}" in
    h) usage; exit 1;;
    n) systemName=$(trim "$OPTARG");;
    p) projectId=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${systemName}" ]]; then
  systemName="system"
fi

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  touch "${currentPath}/../env.properties"
fi

ini-set "${currentPath}/../env.properties" yes system name "${systemName}"

if [[ -n "${projectId}" ]] && [[ "${projectId}" != "-" ]]; then
  ini-set "${currentPath}/../env.properties" yes system projectId "${projectId}"
fi
