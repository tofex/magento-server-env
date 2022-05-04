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

while getopts hi:p:s:d:? option; do
  case "${option}" in
    h) usage; exit 1;;
    i) redisId=$(trim "$OPTARG");;
    p) port=$(trim "$OPTARG");;
    s) password=$(trim "$OPTARG");;
    d) database=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${redisId}" ]]; then
  redisId="redis_session"
fi

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

for server in "${serverList[@]}"; do
  redisSession=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "redisSession")
  if [[ "${redisSession}" == "${redisId}" ]]; then
    if [[ -n "${port}" ]]; then
      echo "--- Updating Redis session port on server: ${server} ---"
      ini-set "${currentPath}/../env.properties" yes "${redisId}" port "${port}"
    fi
    if [[ -n "${password}" ]]; then
      echo "--- Updating Redis session password on server: ${server} ---"
      ini-set "${currentPath}/../env.properties" yes "${redisId}" password "${password}"
    fi
    if [[ -n "${database}" ]]; then
      echo "--- Updating Redis session database on server: ${server} ---"
      ini-set "${currentPath}/../env.properties" yes "${redisId}" database "${database}"
    fi
  fi
done
