#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -i  Redis id, default: redis_cache
  -p  Redis port (optional)
  -d  Database number (optional)
  -c  Class name (optional)
  -s  Redis password (optional)
  -r  Cache prefix (optional)
  -c  Name of PHP class (optional)

Example: ${scriptName} -d 0
EOF
}

trim()
{
  echo -n "$1" | xargs
}

redisId=
port=
password=
database=
cachePrefix=
className=

while getopts hi:p:s:d:r:c:? option; do
  case "${option}" in
    h) usage; exit 1;;
    i) redisId=$(trim "$OPTARG");;
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

for server in "${serverList[@]}"; do
  redisCache=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "redisCache")
  if [[ "${redisCache}" == "${redisId}" ]]; then
    if [[ -n "${port}" ]]; then
      echo "--- Updating Redis cache port on server: ${server} ---"
      ini-set "${currentPath}/../env.properties" yes "${redisId}" port "${port}"
    fi
    if [[ -n "${password}" ]]; then
      echo "--- Updating Redis cache password on server: ${server} ---"
      ini-set "${currentPath}/../env.properties" yes "${redisId}" password "${password}"
    fi
    if [[ -n "${database}" ]]; then
      echo "--- Updating Redis cache database on server: ${database} ---"
      ini-set "${currentPath}/../env.properties" yes "${redisId}" database "${database}"
    fi
    if [[ -n "${cachePrefix}" ]]; then
      echo "--- Updating Redis cache prefix on server: ${database} ---"
      ini-set "${currentPath}/../env.properties" yes "${redisId}" prefix "${cachePrefix}"
    fi
    if [[ -n "${className}" ]]; then
      echo "--- Updating Redis cache class name on server: ${database} ---"
      ini-set "${currentPath}/../env.properties" yes "${redisId}" prefix "${className}"
    fi
  fi
done
