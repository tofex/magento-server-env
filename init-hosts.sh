#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help                     Show this message
  --elasticsearchServerName  Name of server to use (optional)
  --elasticsearchId          Elasticsearch id, default: elasticsearch
  --elasticsearchVersion     Elasticsearch version
  --elasticsearchHost        Elasticsearch host, default: localhost
  --elasticsearchSsl         Elasticsearch SSL (true/false), default: false
  --elasticsearchPort        Elasticsearch port, default: 9200
  --elasticsearchPrefix      Elasticsearch prefix, default: magento
  --elasticsearchUser        User name if behind basic auth
  --elasticsearchPassword    Password if behind basic auth

Example: ${scriptName} --elasticsearchVersion 7.9 --elasticsearchPort 9200
EOF
}

systemName=
hosts=

source "${currentPath}/../core/prepare-parameters.sh"

if [[ -z "${systemName}" ]]; then
  systemName="system"
fi

if [[ -z "${hosts}" ]]; then
  echo "No hosts specified!"
  exit 1
fi

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  touch "${currentPath}/../env.properties"
fi

if [[ -n "${hosts}" ]] && [[ "${hosts}" != "-" ]]; then
  hostList=( $(echo "${hosts}" | tr "," "\n") )

  for host in "${hostList[@]}"; do
    hostName=$(echo "${host}" | cut -d: -f1)
    hostScope=$(echo "${host}" | cut -d: -f2)
    hostCode=$(echo "${host}" | cut -d: -f3)
    sslTerminated=$(echo "${host}" | cut -d: -f4)
    forceSsl=$(echo "${host}" | cut -d: -f5)

    if [[ -z "${sslTerminated}" ]]; then
      sslTerminated="no"
    fi

    if [[ -z "${forceSsl}" ]]; then
      forceSsl="yes"
    fi

    hostId=$(echo "${hostName}" | sed "s/[^[:alnum:]]/_/g")

    "${currentPath}/init-host.sh" \
      --systemName "${systemName}" \
      --hostId "${hostId}" \
      --virtualHost "${hostName}" \
      --scope "${hostScope}" \
      --code "${hostCode}" \
      --sslTerminated "${sslTerminated}" \
      --forceSsl "${forceSsl}"
  done
fi
