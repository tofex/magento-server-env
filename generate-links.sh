#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help         Show this message

Example: ${scriptName} --interactive
EOF
}

source "${currentPath}/../core/prepare-parameters.sh"

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

for server in "${serverList[@]}"; do
  serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
  webServer=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "webServer")

  if [[ -n "${webServer}" ]]; then
    webPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${webServer}" "path")

    if [[ "${serverType}" == "local" ]]; then
      cd "${webPath}"
      symlinkList=( $(find . -type l -not -path "./vendor/*" -not -path "./update/vendor/*" | sort -n | sed 's/^.\///') )

      for symlink in "${symlinkList[@]}"; do
        symlinkTarget=$(readlink -f "${symlink}")
        addLink="${symlinkTarget}:${symlink}"
        echo "Adding link: ${addLink} to deployment"
        ini-set "${currentPath}/../env.properties" "no" "${server}" "link" "${addLink}"
      done
    fi
  fi
done
