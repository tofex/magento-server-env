#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help                          Show this message
  --redisFullPageCacheServerName  Name of server to use (optional)
  --redisFullPageCacheId          Redis id, default: redis_fpc
  --redisFullPageCacheHost        Redis host, default: localhost
  --redisFullPageCacheVersion     Redis version
  --redisFullPageCachePort        Redis port, default: 6380
  --redisFullPageCachePassword    Redis password (optional)
  --redisFullPageCacheDatabase    Database number, default: 0
  --redisFullPageCachePrefix      Cache prefix (optional)
  --redisFullPageCacheClassName   Name of PHP class (optional)

Example: ${scriptName} --redisFullPageCacheVersion 6.0 --redisFullPageCachePort 6380 --redisFullPageCacheDatabase 0
EOF
}

redisFullPageCacheServerName=
redisFullPageCacheId=
redisFullPageCacheHost=
redisFullPageCacheVersion=
redisFullPageCachePort=
redisFullPageCachePassword=
redisFullPageCacheDatabase=
redisFullPageCachePrefix=
redisFullPageCacheClassName=

source "${currentPath}/../core/prepare-parameters.sh"

if [[ -z "${redisFullPageCacheHost}" ]]; then
  redisFullPageCacheHost="localhost"
fi

if [[ -z "${redisFullPageCacheVersion}" ]]; then
  echo "No version specified!"
  exit 1
fi

if [[ -z "${redisFullPageCachePort}" ]]; then
  redisFullPageCachePort="6380"
fi

if [[ -z "${redisFullPageCacheDatabase}" ]]; then
  redisFullPageCacheDatabase="0"
fi

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  touch "${currentPath}/../env.properties"
fi

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

if [[ -z "${redisFullPageCacheServerName}" ]]; then
  for server in "${serverList[@]}"; do
    serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
    if [[ "${redisFullPageCacheHost}" == "localhost" ]] || [[ "${redisFullPageCacheHost}" == "127.0.0.1" ]]; then
      if [[ "${serverType}" == "local" ]]; then
        redisFullPageCacheServerName="${server}"
      fi
    elif [[ "${serverType}" != "local" ]]; then
      serverHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "host")
      if [[ "${serverHost}" == "${redisFullPageCacheHost}" ]]; then
        redisFullPageCacheServerName="${server}"
      fi
    fi
  done
fi

if [[ -z "${redisFullPageCacheServerName}" ]]; then
  echo "No server found for Redis FPC host!"
  exit 1
fi

if [[ -z "${redisFullPageCacheId}" ]]; then
  redisFullPageCacheId="${redisFullPageCacheServerName}_redis_fpc"
fi

ini-set "${currentPath}/../env.properties" yes "${redisFullPageCacheServerName}" redisFPC "${redisFullPageCacheId}"
ini-set "${currentPath}/../env.properties" yes "${redisFullPageCacheId}" version "${redisFullPageCacheVersion}"
ini-set "${currentPath}/../env.properties" yes "${redisFullPageCacheId}" port "${redisFullPageCachePort}"
if [[ -n "${redisFullPageCachePassword}" ]] && [[ "${redisFullPageCachePassword}" != "-" ]]; then
  ini-set "${currentPath}/../env.properties" yes "${redisFullPageCacheId}" password "${redisFullPageCachePassword}"
fi
ini-set "${currentPath}/../env.properties" yes "${redisFullPageCacheId}" database "${redisFullPageCacheDatabase}"
if [[ -n "${redisFullPageCachePrefix}" ]] && [[ "${redisFullPageCachePrefix}" != "-" ]]; then
  ini-set "${currentPath}/../env.properties" yes "${redisFullPageCacheId}" prefix "${redisFullPageCachePrefix}"
fi
if [[ -n "${redisFullPageCacheClassName}" ]] && [[ "${redisFullPageCacheClassName}" != "-" ]]; then
  ini-set "${currentPath}/../env.properties" yes "${redisFullPageCacheId}" className "${redisFullPageCacheClassName}"
fi
