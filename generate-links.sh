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

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

while getopts h? option; do
  case "${option}" in
    h) usage; exit 1;;
    ?) usage; exit 1;;
  esac
done

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

for server in "${serverList[@]}"; do
  webServer=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "webServer")

  if [[ -n "${webServer}" ]]; then
    serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
    webPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webPath")

    if [[ "${serverType}" == "local" ]]; then
      echo "--- Checking current symlinks on local server: ${server} ---"
      cd "${webPath}"
      symlinkList=( $(find . -type l -not -path "./vendor/*" | sort -n | sed 's/^.\///') )

      for symlink in "${symlinkList[@]}"; do
        symlinkTarget=$(readlink -f "${symlink}")
        addLink="${symlinkTarget}:${symlink}"
        echo "Adding link: ${addLink} to deployment"
        ini-set "${currentPath}/../env.properties" "no" "${server}" "link" "${addLink}"
      done
    fi
  fi
done
