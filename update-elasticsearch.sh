#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -i  Elasticsearch id, default: elasticsearch
  -p  Elasticsearch port (optional)
  -x  Elasticsearch prefix (optional)
  -u  User name if behind basic auth (optional)
  -s  Password if behind basic auth (optional)

Example: ${scriptName} -d 0
EOF
}

trim()
{
  echo -n "$1" | xargs
}

elasticsearchId=
port=
prefix=
user=
password=

while getopts hi:p:x:u:s:? option; do
  case "${option}" in
    h) usage; exit 1;;
    i) elasticsearchId=$(trim "$OPTARG");;
    p) port=$(trim "$OPTARG");;
    x) prefix=$(trim "$OPTARG");;
    u) user=$(trim "$OPTARG");;
    s) password=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${elasticsearchId}" ]]; then
  elasticsearchId="elasticsearch"
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
  elasticsearch=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "elasticsearch")
  if [[ "${elasticsearch}" == "${elasticsearchId}" ]]; then
    if [[ -n "${port}" ]]; then
      echo "--- Updating Elasticsearch port on server: ${server} ---"
      ini-set "${currentPath}/../env.properties" yes "${elasticsearchId}" port "${port}"
    fi
    if [[ -n "${prefix}" ]]; then
      echo "--- Updating Elasticsearch prefix on server: ${server} ---"
      ini-set "${currentPath}/../env.properties" yes "${elasticsearchId}" prefix "${prefix}"
    fi
    if [[ -n "${user}" ]]; then
      echo "--- Updating Elasticsearch user on server: ${server} ---"
      ini-set "${currentPath}/../env.properties" yes "${elasticsearchId}" user "${user}"
    fi
    if [[ -n "${password}" ]]; then
      echo "--- Updating Elasticsearch password on server: ${server} ---"
      ini-set "${currentPath}/../env.properties" yes "${elasticsearchId}" password "${password}"
    fi
  fi
done
