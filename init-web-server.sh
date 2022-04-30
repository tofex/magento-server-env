#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -i  Web server id, default: web_server
  -o  Web server host, default: localhost
  -t  Web server type
  -v  Web server version
  -p  Web server HTTP port, default: 80
  -s  Web server SSL port, default: 443

Example: ${scriptName} -t apache -v 2.4
EOF
}

trim()
{
  echo -n "$1" | xargs
}

webServerId=
host=
type=
version=
httpPort=
sslPort=

while getopts hi:o:t:v:p:s:? option; do
  case "${option}" in
    h) usage; exit 1;;
    i) webServerId=$(trim "$OPTARG");;
    o) host=$(trim "$OPTARG");;
    t) type=$(trim "$OPTARG");;
    v) version=$(trim "$OPTARG");;
    p) httpPort=$(trim "$OPTARG");;
    s) sslPort=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${webServerId}" ]]; then
  webServerId="web_server"
fi

if [[ -z "${host}" ]]; then
  host="localhost"
fi

if [[ -z "${type}" ]]; then
  echo "No type specified!"
  exit 1
fi

if [[ -z "${version}" ]]; then
  echo "No version specified!"
  exit 1
fi

if [[ -z "${httpPort}" ]]; then
  httpPort="80"
fi

if [[ -z "${sslPort}" ]]; then
  sslPort="443"
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
  serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
  if [[ "${host}" == "localhost" ]] && [[ "${serverType}" == "local" ]]; then
    serverName="${server}"
  elif [[ "${serverType}" != "local" ]]; then
    serverHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "host")
    if [[ "${serverHost}" == "${host}" ]]; then
      serverName="${server}"
    fi
  fi
done

if [[ -z "${serverName}" ]]; then
  echo "No server found for web server host!"
  exit 1
fi

ini-set "${currentPath}/../env.properties" yes "${serverName}" webServer "${webServerId}"
ini-set "${currentPath}/../env.properties" yes "${webServerId}" type "${type}"
ini-set "${currentPath}/../env.properties" yes "${webServerId}" version "${version}"
ini-set "${currentPath}/../env.properties" yes "${webServerId}" httpPort "${httpPort}"
ini-set "${currentPath}/../env.properties" yes "${webServerId}" sslPort "${sslPort}"
