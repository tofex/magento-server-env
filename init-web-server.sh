#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help                 Show this message
  --webServerServerName  Name of server to use, default: server
  --webServerId          Web server id, default: web_server
  --webServerHost        Web server host, default: localhost
  --webServerType        Web server type
  --webServerVersion     Web server version
  --webServerHttpPort    Web server HTTP port, default: 80
  --webServerSslPort     Web server SSL port, default: 443
  --webServerPath        Path of Magento installation
  --webServerUser        User of Magento installation, default: www-data
  --webServerGroup       Group of Magento installation, default: www-data

Example: ${scriptName} --webServerType apache --webServerVersion 2.4 --webServerPath /var/www/magento/htdocs
EOF
}

webServerServerName=
webServerId=
webServerHost=
webServerType=
webServerVersion=
webServerHttpPort=
webServerSslPort=
webServerPath=
webServerUser=
webServerGroup=

source "${currentPath}/../core/prepare-parameters.sh"

if [[ -z "${webServerHost}" ]]; then
  webServerHost="localhost"
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

serverList=( $(ini-parse "${currentPath}/../env.properties" "no" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  >&2 echo "No servers specified!"
  exit 1
fi

if [[ -z "${webServerServerName}" ]]; then
  webServerServerName=
  for server in "${serverList[@]}"; do
    serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
    if { [[ "${webServerHost}" == "localhost" ]] || [[ "${webServerHost}" == "127.0.0.1" ]]; } && [[ "${serverType}" == "local" ]]; then
      webServerServerName="${server}"
    elif [[ "${serverType}" != "local" ]]; then
      serverHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "host")
      if [[ "${serverHost}" == "${webServerHost}" ]]; then
        webServerServerName="${server}"
      fi
    fi
  done
fi

if [[ -z "${webServerServerName}" ]]; then
  >&2 echo "No server found for web server host!"
  exit 1
fi

if [[ -z "${webServerId}" ]]; then
  webServerId="${webServerServerName}_web_server"
fi

webServerPath=$(echo "${webServerPath}" | sed 's:/*$::')
webServerPath="${webServerPath%/}"

ini-set "${currentPath}/../env.properties" yes "${webServerServerName}" webServer "${webServerId}"
ini-set "${currentPath}/../env.properties" yes "${webServerId}" type "${webServerType}"
ini-set "${currentPath}/../env.properties" yes "${webServerId}" version "${webServerVersion}"
ini-set "${currentPath}/../env.properties" yes "${webServerId}" httpPort "${webServerHttpPort}"
ini-set "${currentPath}/../env.properties" yes "${webServerId}" sslPort "${webServerSslPort}"
ini-set "${currentPath}/../env.properties" yes "${webServerId}" path "${webServerPath}"
ini-set "${currentPath}/../env.properties" yes "${webServerId}" user "${webServerUser}"
ini-set "${currentPath}/../env.properties" yes "${webServerId}" group "${webServerGroup}"
