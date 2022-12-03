#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -i  Elasticsearch id, default: elasticsearch
  -o  Elasticsearch host, default: localhost
  -v  Elasticsearch version
  -p  Elasticsearch port, default: 9200
  -x  Elasticsearch prefix, default: magento
  -u  User name if behind basic auth
  -s  Password if behind basic auth

Example: ${scriptName} -v 7.9 -p 9200
EOF
}

trim()
{
  echo -n "$1" | xargs
}

elasticsearchId=
version=
host=
port=
prefix=
user=
password=

while getopts hi:v:o:p:x:u:s:? option; do
  case "${option}" in
    h) usage; exit 1;;
    i) elasticsearchId=$(trim "$OPTARG");;
    v) version=$(trim "$OPTARG");;
    o) host=$(trim "$OPTARG");;
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

if [[ -z "${version}" ]]; then
  echo "No version specified!"
  exit 1
fi

if [[ -z "${host}" ]]; then
  host="localhost"
fi

if [[ -z "${port}" ]]; then
  port="9200"
fi

if [[ -z "${prefix}" ]]; then
  port="magento"
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

elasticsearchServerName=
for server in "${serverList[@]}"; do
  serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
  if [[ "${host}" == "localhost" ]] || [[ "${host}" == "127.0.0.1" ]]; then
    if [[ "${serverType}" == "local" ]]; then
      elasticsearchServerName="${server}"
    fi
  elif [[ "${serverType}" != "local" ]]; then
    serverHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "host")
    if [[ "${serverHost}" == "${host}" ]]; then
      elasticsearchServerName="${server}"
    fi
  fi
done

if [[ -z "${elasticsearchServerName}" ]]; then
  echo "No server found for Elasticsearch host!"
  exit 1
fi

ini-set "${currentPath}/../env.properties" yes "${elasticsearchServerName}" elasticsearch "${elasticsearchId}"
ini-set "${currentPath}/../env.properties" yes "${elasticsearchId}" version "${version}"
ini-set "${currentPath}/../env.properties" yes "${elasticsearchId}" port "${port}"
ini-set "${currentPath}/../env.properties" yes "${elasticsearchId}" prefix "${prefix}"
if [[ -n "${user}" ]] && [[ -n "${password}" ]]; then
  ini-set "${currentPath}/../env.properties" yes "${elasticsearchId}" user "${user}"
  ini-set "${currentPath}/../env.properties" yes "${elasticsearchId}" password "${password}"
fi
