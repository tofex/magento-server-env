#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help                  Show this message
  --openSearchServerName  Name of server to use (optional)
  --openSearchId          OpenSearch id, default: opensearch
  --openSearchEngine      Engine of OpenSearch, default: core
  --openSearchVersion     OpenSearch version
  --openSearchHost        OpenSearch host, default: localhost
  --openSearchSsl         OpenSearch SSL (true/false), default: false
  --openSearchPort        OpenSearch port, default: 9200
  --openSearchPrefix      OpenSearch prefix, default: magento
  --openSearchUser        User name if behind basic auth
  --openSearchPassword    Password if behind basic auth

Example: ${scriptName} --openSearchVersion 2.9 --openSearchPort 9200
EOF
}

openSearchServerName=
openSearchId=
openSearchEngine=
openSearchVersion=
openSearchHost=
openSearchSsl=
openSearchPort=
openSearchPrefix=
openSearchUser=
openSearchPassword=

source "${currentPath}/../core/prepare-parameters.sh"

if [[ -z "${openSearchEngine}" ]]; then
  openSearchEngine="core"
fi

if [[ -z "${openSearchVersion}" ]]; then
  >&2 echo "No OpenSearch version specified!"
  exit 1
fi

if [[ -z "${openSearchHost}" ]]; then
  openSearchHost="localhost"
fi

if [[ -z "${openSearchSsl}" ]]; then
  openSearchSsl="false"
fi

if [[ -z "${openSearchPort}" ]]; then
  openSearchPort="9200"
fi

if [[ -z "${openSearchPrefix}" ]]; then
  openSearchPrefix="magento"
fi

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  touch "${currentPath}/../env.properties"
fi

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

if [[ -z "${openSearchServerName}" ]]; then
  for server in "${serverList[@]}"; do
    serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
    if { [[ "${openSearchHost}" == "localhost" ]] || [[ "${openSearchHost}" == "127.0.0.1" ]]; } && [[ "${serverType}" == "local" ]]; then
      openSearchServerName="${server}"
    elif [[ "${serverType}" != "local" ]]; then
      serverHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "host")
      if [[ "${serverHost}" == "${openSearchHost}" ]]; then
        openSearchServerName="${server}"
      fi
    fi
  done
fi

if [[ -z "${openSearchServerName}" ]]; then
  echo "No server found for OpenSearch host!"
  exit 1
fi

if [[ -z "${openSearchId}" ]]; then
  openSearchId="${openSearchServerName}_opensearch"
fi

ini-set "${currentPath}/../env.properties" yes "${openSearchServerName}" opensearch "${openSearchId}"
ini-set "${currentPath}/../env.properties" yes "${openSearchId}" engine "${openSearchEngine}"
ini-set "${currentPath}/../env.properties" yes "${openSearchId}" version "${openSearchVersion}"
ini-set "${currentPath}/../env.properties" yes "${openSearchId}" ssl "${openSearchSsl}"
ini-set "${currentPath}/../env.properties" yes "${openSearchId}" port "${openSearchPort}"
ini-set "${currentPath}/../env.properties" yes "${openSearchId}" prefix "${openSearchPrefix}"
if [[ -n "${openSearchUser}" ]] && [[ -n "${openSearchPassword}" ]]; then
  ini-set "${currentPath}/../env.properties" yes "${openSearchId}" user "${openSearchUser}"
  ini-set "${currentPath}/../env.properties" yes "${openSearchId}" password "${openSearchPassword}"
fi
