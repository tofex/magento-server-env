#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help          Show this message
  --solrId        Solr id, default: solr
  --solrHost      Solr solrHost, default: localhost
  --solrVersion   Solr solrVersion
  --solrProtocol  Solr solrProtocol, default: https
  --solrPort      Solr solrPort, default: 8983
  --solrUrlPath   Solr Url Path, default: solr
  --solrUser      Solr solrUser (optional)
  --solrPassword  Solr solrPassword (optional)

Example: ${scriptName} --solrVersion 8.6 --solrPort 8983
EOF
}

solrId=
solrHost=
solrVersion=
solrProtocol=
solrPort=
solrUrlPath=
solrUser=
solrPassword=

source "${currentPath}/../core/prepare-parameters.sh"

if [[ -z "${solrId}" ]]; then
  solrId="solr"
fi

if [[ -z "${solrHost}" ]]; then
  solrHost="localhost"
else
  remoteIpAddress="$(dig TXT -4 +short o-o.myaddr.l.google.com @ns1.google.com | awk -F'"' '{ print $2}')"
  if [[ -n "${remoteIpAddress}" ]] && [[ "${solrHost}" == "${remoteIpAddress}" ]]; then
    solrHost="localhost"
  fi
fi

if [[ -z "${solrVersion}" ]]; then
  echo "No solrVersion specified!"
  exit 1
fi

if [[ -z "${solrProtocol}" ]]; then
  solrProtocol="https"
fi

if [[ -z "${solrPort}" ]]; then
  solrPort="8983"
fi

if [[ -z "${solrUrlPath}" ]]; then
  solrUrlPath="solr"
fi


cd "${currentPath}"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  touch "${currentPath}/../env.properties"
fi

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

solrServerName=
for server in "${serverList[@]}"; do
  serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
  if [[ "${solrHost}" == "localhost" ]] && [[ "${serverType}" == "local" ]]; then
    solrServerName="${server}"
  elif [[ "${serverType}" != "local" ]]; then
    serverHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "solrHost")
    if [[ "${serverHost}" == "${solrHost}" ]]; then
      solrServerName="${server}"
    fi
  fi
done

if [[ -z "${solrServerName}" ]]; then
  echo "No server found for Solr solrHost!"
  exit 1
fi

ini-set "${currentPath}/../env.properties" yes "${solrServerName}" solr "${solrId}"
ini-set "${currentPath}/../env.properties" yes "${solrId}" solrVersion "${solrVersion}"
ini-set "${currentPath}/../env.properties" yes "${solrId}" solrProtocol "${solrProtocol}"
ini-set "${currentPath}/../env.properties" yes "${solrId}" solrPort "${solrPort}"
ini-set "${currentPath}/../env.properties" yes "${solrId}" solrUrlPath "${solrUrlPath}"
if [[ -n "${solrUser}" ]] && [[ "${solrUser}" != "-" ]]; then
  ini-set "${currentPath}/../env.properties" yes "${solrId}" solrUser "${solrUser}"
fi
if [[ -n "${solrPassword}" ]] && [[ "${solrPassword}" != "-" ]]; then
  ini-set "${currentPath}/../env.properties" yes "${solrId}" solrPassword "${solrPassword}"
fi
