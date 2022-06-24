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
type=
version=
httpPort=
sslPort=

while getopts hi:t:v:p:s:? option; do
  case "${option}" in
    h) usage; exit 1;;
    i) webServerId=$(trim "$OPTARG");;
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
  webServer=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "webServer")
  if [[ "${webServer}" == "${webServerId}" ]]; then
    if [[ -n "${type}" ]]; then
      echo "--- Updating web server type on server: ${server} ---"
      ini-set "${currentPath}/../env.properties" yes "${webServerId}" type "${type}"
    fi
    if [[ -n "${version}" ]]; then
      echo "--- Updating web server version on server: ${server} ---"
      ini-set "${currentPath}/../env.properties" yes "${webServerId}" version "${version}"
    fi
    if [[ -n "${httpPort}" ]]; then
      echo "--- Updating web server HTTP port on server: ${server} ---"
      ini-set "${currentPath}/../env.properties" yes "${webServerId}" httpPort "${httpPort}"
    fi
    if [[ -n "${sslPort}" ]]; then
      echo "--- Updating web server SSL port on server: ${server} ---"
      ini-set "${currentPath}/../env.properties" yes "${webServerId}" sslPort "${sslPort}"
    fi
  fi
done
