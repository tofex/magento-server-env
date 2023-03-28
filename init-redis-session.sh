#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help                    Show this message
  --redisSessionServerName  Name of server to use (optional)
  --redisSessionId          Redis id, default: redis_session
  --redisSessionHost        Redis host, default: localhost
  --redisSessionVersion     Redis version
  --redisSessionPort        Redis port, default: 6381
  --redisSessionPassword    Redis password (optional)
  --redisSessionDatabase    Database number, default: 0

Example: ${scriptName} -v 6.0 -p 6381 -d 0
EOF
}

redisSessionId=
redisSessionHost=
redisSessionVersion=
redisSessionPort=
redisSessionPassword=
redisSessionDatabase=

if [[ -z "${redisSessionHost}" ]]; then
  redisSessionHost="localhost"
fi

if [[ -z "${redisSessionVersion}" ]]; then
  echo "No version specified!"
  exit 1
fi

if [[ -z "${redisSessionPort}" ]]; then
  redisSessionPort="6381"
fi

if [[ -z "${redisSessionDatabase}" ]]; then
  redisSessionDatabase="0"
fi

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  touch "${currentPath}/../env.properties"
fi

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

if [[ -z "${redisSessionServerName}" ]]; then
  for server in "${serverList[@]}"; do
    serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
    if [[ "${redisSessionHost}" == "localhost" ]] || [[ "${redisSessionHost}" == "127.0.0.1" ]]; then
      if [[ "${serverType}" == "local" ]]; then
        redisSessionServerName="${server}"
      fi
    elif [[ "${serverType}" != "local" ]]; then
      serverHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "host")
      if [[ "${serverHost}" == "${redisSessionHost}" ]]; then
        redisSessionServerName="${server}"
      fi
    fi
  done
fi

if [[ -z "${redisSessionServerName}" ]]; then
  echo "No server found for Redis host!"
  exit 1
fi

if [[ -z "${redisSessionId}" ]]; then
  redisSessionId="${redisSessionServerName}_redis_session"
fi

ini-set "${currentPath}/../env.properties" yes "${redisSessionServerName}" redisSession "${redisSessionId}"
ini-set "${currentPath}/../env.properties" yes "${redisSessionId}" version "${redisSessionVersion}"
ini-set "${currentPath}/../env.properties" yes "${redisSessionId}" port "${redisSessionPort}"
if [[ -n "${redisSessionPassword}" ]] && [[ "${redisSessionPassword}" != "-" ]]; then
  ini-set "${currentPath}/../env.properties" yes "${redisSessionId}" password "${redisSessionPassword}"
fi
ini-set "${currentPath}/../env.properties" yes "${redisSessionId}" database "${redisSessionDatabase}"
