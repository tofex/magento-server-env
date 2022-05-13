#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

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

phpExecutable=$(which php)
availablePhpExecutables=( $(locate bin/php | cat | grep -E php$ | cat) )

if [[ "${#availablePhpExecutables[@]}" -gt 1 ]]; then
  echo "Found multiple PHP executables:"
  printf '%s\n' "${availablePhpExecutables[@]}"

  usePhpExecutable=0
  echo ""
  echo "Do you wish to use the current PHP executable at: ${phpExecutable}?"
  select yesNo in "Yes" "No"; do
    case "${yesNo}" in
      Yes ) usePhpExecutable=1; break;;
      No ) break;;
    esac
  done

  if [[ "${usePhpExecutable}" == 0 ]]; then
    echo ""
    echo "Please specify the PHP executable to use, followed by [ENTER]:"
    read -r phpExecutable
  fi
fi

if [[ -z "${phpExecutable}" ]]; then
  echo "PHP executable not found"
  exit 1
fi

"${currentPath}/add-system.sh"

"${currentPath}/generate-server.sh" -t local
"${currentPath}/generate-web-server.sh" -t local -c
"${currentPath}/generate-links.sh" -t local -c
"${currentPath}/generate-install.sh" -e "${phpExecutable}"
"${currentPath}/generate-database.sh"
"${currentPath}/generate-cache.sh"
"${currentPath}/generate-fpc.sh"
"${currentPath}/generate-session.sh"
"${currentPath}/generate-solr.sh"

"${currentPath}/add-build.sh"
"${currentPath}/add-deploy.sh"
