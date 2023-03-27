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

if [[ -f "${currentPath}/../env.properties" ]]; then
  echo "Do you wish to overwrite the environment properties?"
  select yesNo in "Yes" "No"; do
    case "${yesNo}" in
      Yes ) break;;
      No ) exit;;
    esac
  done
  echo ""
fi

rm -rf "${currentPath}/../env.properties"
touch "${currentPath}/../env.properties"

if [[ "${interactive}" == 1 ]]; then
  "${currentPath}/add-system.sh" \
    --name "${name}" \
    --projectId "${projectId}" \
    --interactive
  "${currentPath}/generate-web-server.sh" --interactive
  "${currentPath}/generate-links.sh"
  "${currentPath}/generate-install.sh"
  "${currentPath}/generate-database.sh" --interactive
  "${currentPath}/generate-elasticsearch.sh" --interactive
  "${currentPath}/generate-solr.sh" --interactive
  "${currentPath}/generate-cache.sh" --interactive
  "${currentPath}/generate-fpc.sh" --interactive
  "${currentPath}/generate-session.sh" --interactive
else
  "${currentPath}/add-system.sh" \
    --name "${name}" \
    --projectId "${projectId}"
  "${currentPath}/generate-web-server.sh"
  "${currentPath}/generate-links.sh"
  "${currentPath}/generate-install.sh"
  "${currentPath}/generate-database.sh"
  "${currentPath}/generate-elasticsearch.sh"
  "${currentPath}/generate-solr.sh"
  "${currentPath}/generate-cache.sh"
  "${currentPath}/generate-fpc.sh"
  "${currentPath}/generate-session.sh"
fi
