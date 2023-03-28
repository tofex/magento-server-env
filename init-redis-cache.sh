#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help                  Show this message
  --redisCacheServerName  Name of server to use (optional)
  --redisCacheId          Redis id, default: redis_cache
  --redisCacheHost        Redis host, default: localhost
  --redisCacheVersion     Redis version
  --redisCachePort        Redis port, default: 6379
  --redisCachePassword    Redis password (optional)
  --redisCacheDatabase    Database number, default: 0
  --redisCachePrefix      Cache prefix (optional)
  --redisCacheClassName   Name of PHP class (optional)

Example: ${scriptName} --redisCacheVersion 6.0 --redisCachePort 6379 --redisCacheDatabase 0
EOF
}

redisCacheServerName=
redisCacheId=
redisCacheHost=
redisCacheVersion=
redisCachePort=
redisCachePassword=
redisCacheDatabase=
redisCachePrefix=
redisCacheClassName=

source "${currentPath}/../core/prepare-parameters.sh"

if [[ -z "${redisCacheHost}" ]]; then
  redisCacheHost="localhost"
fi

if [[ -z "${redisCacheVersion}" ]]; then
  echo "No version specified!"
  exit 1
fi

if [[ -z "${redisCachePort}" ]]; then
  redisCachePort="6379"
fi

if [[ -z "${redisCacheDatabase}" ]]; then
  redisCacheDatabase="0"
fi

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  touch "${currentPath}/../env.properties"
fi

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

if [[ -z "${redisCacheServerName}" ]]; then
  for server in "${serverList[@]}"; do
    serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
    if [[ "${redisCacheHost}" == "localhost" ]] || [[ "${redisCacheHost}" == "127.0.0.1" ]]; then
      if [[ "${serverType}" == "local" ]]; then
        redisCacheServerName="${server}"
      fi
    elif [[ "${serverType}" != "local" ]]; then
      serverHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "host")
      if [[ "${serverHost}" == "${redisCacheHost}" ]]; then
        redisCacheServerName="${server}"
      fi
    fi
  done
fi

if [[ -z "${redisCacheServerName}" ]]; then
  echo "No server found for Redis cache host!"
  exit 1
fi

if [[ -z "${redisCacheId}" ]]; then
  redisCacheId="${redisCacheServerName}_redis_cache"
fi

ini-set "${currentPath}/../env.properties" yes "${redisCacheServerName}" redisCache "${redisCacheId}"
ini-set "${currentPath}/../env.properties" yes "${redisCacheId}" version "${redisCacheVersion}"
ini-set "${currentPath}/../env.properties" yes "${redisCacheId}" port "${redisCachePort}"
if [[ -n "${redisCachePassword}" ]] && [[ "${redisCachePassword}" != "-" ]]; then
  ini-set "${currentPath}/../env.properties" yes "${redisCacheId}" password "${redisCachePassword}"
fi
ini-set "${currentPath}/../env.properties" yes "${redisCacheId}" database "${redisCacheDatabase}"
if [[ -n "${redisCachePrefix}" ]] && [[ "${redisCachePrefix}" != "-" ]]; then
  ini-set "${currentPath}/../env.properties" yes "${redisCacheId}" prefix "${redisCachePrefix}"
fi
if [[ -n "${redisCacheClassName}" ]] && [[ "${redisCacheClassName}" != "-" ]]; then
  ini-set "${currentPath}/../env.properties" yes "${redisCacheId}" className "${redisCacheClassName}"
fi
