#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help               Show this message
  --serverName         Name of server to use, default: server
  --webServerId        Web server id, default: <serverName>_web_server
  --webServerType      Web server type
  --webServerVersion   Web server version
  --webServerHttpPort  Web server HTTP port, default: 80
  --webServerSslPort   Web server SSL port, default: 443
  --webServerPath      Path of Magento installation
  --webServerUser      User of Magento installation, default: www-data
  --webServerGroup     Group of Magento installation, default: www-data

Example: ${scriptName} --webServerType apache --webServerVersion 2.4 --webServerPath /var/www/magento/htdocs
EOF
}

serverName=
webServerId=
webServerType=
webServerVersion=
webServerHttpPort=
webServerSslPort=
webServerPath=
webServerUser=
webServerGroup=

source "${currentPath}/../core/prepare-parameters.sh"

if [[ -z "${serverName}" ]]; then
  serverName="server"
fi

if [[ -z "${webServerId}" ]]; then
  webServerId="${serverName}_web_server"
fi

if [[ -z "${webServerType}" ]]; then
  >&2 echo "No web server type specified!"
  echo ""
  usage
  exit 1
fi

if [[ -z "${webServerVersion}" ]]; then
  >&2 echo "No web server version specified!"
  echo ""
  usage
  exit 1
fi

if [[ -z "${webServerHttpPort}" ]]; then
  webServerHttpPort="80"
fi

if [[ -z "${webServerSslPort}" ]]; then
  webServerSslPort="443"
fi

if [[ -z "${webServerPath}" ]]; then
  >&2 echo "No web server path specified!"
  echo ""
  usage
  exit 1
fi

if [[ -z "${webServerUser}" ]]; then
  webServerUser="www-data"
fi

if [[ -z "${webServerGroup}" ]]; then
  webServerGroup="www-data"
fi

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  >&2 echo "No environment specified!"
  exit 1
fi

serverFound=0

serverList=( $(ini-parse "${currentPath}/../env.properties" "no" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  >&2 echo "No servers specified!"
  exit 1
fi

for server in "${serverList[@]}"; do
  if [[ "${server}" == "${serverName}" ]]; then
    serverFound=1
  fi
done

if [[ "${serverFound}" == 0 ]]; then
  echo "No server with name: ${serverName} found for web server!"
  exit 1
fi

webServerPath=$(echo "${webServerPath}" | sed 's:/*$::')
webServerPath="${webServerPath%/}"

ini-set "${currentPath}/../env.properties" yes "${serverName}" webServer "${webServerId}"
ini-set "${currentPath}/../env.properties" yes "${webServerId}" type "${webServerType}"
ini-set "${currentPath}/../env.properties" yes "${webServerId}" version "${webServerVersion}"
ini-set "${currentPath}/../env.properties" yes "${webServerId}" httpPort "${webServerHttpPort}"
ini-set "${currentPath}/../env.properties" yes "${webServerId}" sslPort "${webServerSslPort}"
ini-set "${currentPath}/../env.properties" yes "${webServerId}" path "${webServerPath}"
ini-set "${currentPath}/../env.properties" yes "${webServerId}" user "${webServerUser}"
ini-set "${currentPath}/../env.properties" yes "${webServerId}" group "${webServerGroup}"
