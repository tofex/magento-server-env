#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -s  Server name (optional)

Example: ${scriptName}
EOF
}

trim()
{
  echo -n "$1" | xargs
}

serverName=
while getopts hs:? option; do
  case "${option}" in
    h) usage; exit 1;;
    s) serverName=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

for server in "${serverList[@]}"; do
  useServer=0
  if [[ -n "${serverName}" ]] && [[ "${serverName}" == "${server}" ]]; then
    useServer=1
  else
    webServer=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "webServer")
    if [[ -n "${webServer}" ]]; then
      useServer=1
    fi
  fi

  if [[ "${useServer}" == 1 ]]; then
    serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")

    if [[ "${serverType}" == "local" ]]; then
      if [[ -f /opt/install/env.properties ]]; then
        redisSessionVersion=$(ini-parse "/opt/install/env.properties" "no" "redis" "sessionVersion")

        if [[ -n "${redisSessionVersion}" ]]; then
          redisSessionPort=$(ini-parse "/opt/install/env.properties" "yes" "redis" "sessionPort")

          ./init-redis-session.sh \
            -o "localhost" \
            -v "${redisSessionVersion}" \
            -p "${redisSessionPort}"
        fi
      fi
    fi
  fi
done
