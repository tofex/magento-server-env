#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help       Show this message
  --name       Name of system
  --projectId  Id of project

Example: ${scriptName} --name live --projectId 12345
EOF
}

name=
projectId=

source "${currentPath}/../core/prepare-parameters.sh"

if [[ -z "${name}" ]]; then
  >&2 echo "No name specified!"
  echo ""
  usage
  exit 1
fi

if [[ -z "${projectId}" ]]; then
  >&2 echo "No project Id specified!"
  echo ""
  usage
  exit 1
fi

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  touch "${currentPath}/../env.properties"
fi

ini-set "${currentPath}/../env.properties" yes system name "${name}"
ini-set "${currentPath}/../env.properties" yes system projectId "${projectId}"
