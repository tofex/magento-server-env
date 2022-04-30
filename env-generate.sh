#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ -f "${currentPath}/../env.properties" ]]; then
  echo "Do you wish to overwrite the environment properties?"
  select yesNo in "Yes" "No"; do
    case ${yesNo} in
      Yes ) break;;
      No ) exit;;
    esac
  done
  echo ""
fi

rm -rf "${currentPath}/../env.properties"
touch "${currentPath}/../env.properties"

"${currentPath}/add-system.sh"

"${currentPath}/generate-server.sh" -t local
"${currentPath}/generate-web-server.sh" -t local -c
"${currentPath}/generate-install.sh"
"${currentPath}/generate-database.sh"
"${currentPath}/generate-cache.sh"
"${currentPath}/generate-fpc.sh"
"${currentPath}/generate-session.sh"
"${currentPath}/generate-solr.sh"

"${currentPath}/add-build.sh"
"${currentPath}/add-deploy.sh"
