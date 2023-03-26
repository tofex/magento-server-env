#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help         Show this message
  --name         Name of system
  --projectId    Id of project
  --interactive  Interactive mode if data is missing

Example: ${scriptName}
EOF
}

name=
projectId=
interactive=0

source "${currentPath}/../core/prepare-parameters.sh"

if [[ -z "${name}" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the name of the system, followed by [ENTER]:"
    read -r -e name
  else
    >&2 echo "No name specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ -z "${projectId}" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the id of the project, followed by [ENTER]:"
    read -r -e projectId
  else
    >&2 echo "No project Id specified!"
    echo ""
    usage
    exit 1
  fi
fi

"${currentPath}/init-system.sh" \
  --name "${name}" \
  --projectId "${projectId}"
