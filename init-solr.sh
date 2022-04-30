#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -i  Solr id, default: solr
  -o  Solr host, default: localhost
  -v  Solr version
  -t  Solr protocol, default: https
  -p  Solr port, default: 8983
  -r  Solr Url Path, default: solr
  -u  Solr user (optional)
  -s  Solr password (optional)

Example: ${scriptName} -i solr -v 8.6 -p 8983 -r solr
EOF
}

trim()
{
  echo -n "$1" | xargs
}

solrId=
host=
version=
protocol=
port=
urlPath=
user=
password=

while getopts hi:o:v:t:p:r:u:s:? option; do
  case "${option}" in
    h) usage; exit 1;;
    i) solrId=$(trim "$OPTARG");;
    o) host=$(trim "$OPTARG");;
    v) version=$(trim "$OPTARG");;
    t) protocol=$(trim "$OPTARG");;
    p) port=$(trim "$OPTARG");;
    r) urlPath=$(trim "$OPTARG");;
    u) user=$(trim "$OPTARG");;
    s) password=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${solrId}" ]]; then
  solrId="solr"
fi

if [[ -z "${host}" ]]; then
  host="localhost"
else
  remoteIpAddress="$(dig TXT -4 +short o-o.myaddr.l.google.com @ns1.google.com | awk -F'"' '{ print $2}')"
  if [[ -n "${remoteIpAddress}" ]] && [[ "${host}" == "${remoteIpAddress}" ]]; then
    host="localhost"
  fi
fi

if [[ -z "${version}" ]]; then
  echo "No version specified!"
  exit 1
fi

if [[ -z "${protocol}" ]]; then
  protocol="https"
fi

if [[ -z "${port}" ]]; then
  port="8983"
fi

if [[ -z "${urlPath}" ]]; then
  urlPath="solr"
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

solrServerName=
for server in "${serverList[@]}"; do
  serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
  if [[ "${host}" == "localhost" ]] && [[ "${serverType}" == "local" ]]; then
    solrServerName="${server}"
  elif [[ "${serverType}" != "local" ]]; then
    serverHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "host")
    if [[ "${serverHost}" == "${host}" ]]; then
      solrServerName="${server}"
    fi
  fi
done

if [[ -z "${solrServerName}" ]]; then
  echo "No server found for Solr host!"
  exit 1
fi

ini-set "${currentPath}/../env.properties" yes "${solrServerName}" solr "${solrId}"
ini-set "${currentPath}/../env.properties" yes "${solrId}" version "${version}"
ini-set "${currentPath}/../env.properties" yes "${solrId}" protocol "${protocol}"
ini-set "${currentPath}/../env.properties" yes "${solrId}" port "${port}"
ini-set "${currentPath}/../env.properties" yes "${solrId}" urlPath "${urlPath}"
if [[ -n "${user}" ]] && [[ "${user}" != "-" ]]; then
  ini-set "${currentPath}/../env.properties" yes "${solrId}" user "${user}"
fi
if [[ -n "${password}" ]] && [[ "${password}" != "-" ]]; then
  ini-set "${currentPath}/../env.properties" yes "${solrId}" password "${password}"
fi
