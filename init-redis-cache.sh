#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -i  Redis id, default: redis_cache
  -o  Redis host, default: localhost
  -v  Redis version
  -p  Redis port, default: 6379
  -d  Database number, default: 0
  -s  Redis password (optional)
  -r  Cache prefix (optional)
  -c  Name of PHP class (optional)

Example: ${scriptName} -v 6.0 -p 6379 -d 0
EOF
}

trim()
{
  echo -n "$1" | xargs
}

redisId=
host=
version=
port=
password=
database=
cachePrefix=
className=

while getopts hi:o:v:p:s:d:r:c:? option; do
  case "${option}" in
    h) usage; exit 1;;
    i) redisId=$(trim "$OPTARG");;
    o) host=$(trim "$OPTARG");;
    v) version=$(trim "$OPTARG");;
    p) port=$(trim "$OPTARG");;
    s) password=$(trim "$OPTARG");;
    d) database=$(trim "$OPTARG");;
    r) cachePrefix=$(trim "$OPTARG");;
    c) className=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${redisId}" ]]; then
  redisId="redis_cache"
fi

if [[ -z "${host}" ]]; then
  host="localhost"
fi

if [[ -z "${version}" ]]; then
  echo "No version specified!"
  exit 1
fi

if [[ -z "${port}" ]]; then
  port="6379"
fi

if [[ -z "${database}" ]]; then
  database="0"
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

redisServerName=
for server in "${serverList[@]}"; do
  serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
  if [[ "${host}" == "localhost" ]] || [[ "${host}" == "127.0.0.1" ]]; then
    if [[ "${serverType}" == "local" ]]; then
      redisServerName="${server}"
    fi
  elif [[ "${serverType}" != "local" ]]; then
    serverHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "host")
    if [[ "${serverHost}" == "${host}" ]]; then
      redisServerName="${server}"
    fi
  fi
done

if [[ -z "${redisServerName}" ]]; then
  echo "No server found for Redis host!"
  exit 1
fi

ini-set "${currentPath}/../env.properties" yes "${redisServerName}" redisCache "${redisId}"
ini-set "${currentPath}/../env.properties" yes "${redisId}" version "${version}"
ini-set "${currentPath}/../env.properties" yes "${redisId}" port "${port}"
if [[ -n "${password}" ]] && [[ "${password}" != "-" ]]; then
  ini-set "${currentPath}/../env.properties" yes "${redisId}" password "${password}"
fi
ini-set "${currentPath}/../env.properties" yes "${redisId}" database "${database}"
if [[ -n "${cachePrefix}" ]] && [[ "${cachePrefix}" != "-" ]]; then
  ini-set "${currentPath}/../env.properties" yes "${redisId}" prefix "${cachePrefix}"
fi
if [[ -n "${className}" ]] && [[ "${className}" != "-" ]]; then
  ini-set "${currentPath}/../env.properties" yes "${redisId}" className "${className}"
fi
