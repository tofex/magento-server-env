#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help                Show this message
  --databaseServerName  Name of server to use (optional)
  --databaseId          Database id, default: <databaseServerName>_database
  --databaseHost        Database host, default: localhost
  --databaseType        Database type
  --databaseVersion     Database version
  --databasePort        Database port, default: 3306
  --databaseUser        Database user
  --databasePassword    Database password
  --databaseName        Database name
  --upgradeServerName   Upgrade on server, default: server name

Example: ${scriptName} --databaseType mysql --databaseVersion 5.7 --databaseUser magento --databasePassword magento --databaseName magento
EOF
}

databaseServerName=
databaseId=
databaseHost=
databaseType=
databaseVersion=
databasePort=
databaseUser=
databasePassword=
databaseName=
upgradeServerName=

source "${currentPath}/../core/prepare-parameters.sh"

if [[ -z "${databaseHost}" ]]; then
  databaseHost="localhost"
fi

if [[ -z "${databaseType}" ]]; then
  >&2 echo "No database type specified!"
  exit 1
fi

if [[ -z "${databaseVersion}" ]]; then
  >&2 echo "No database version specified!"
  exit 1
fi

if [[ -z "${databasePort}" ]]; then
  databasePort="3306"
fi

if [[ -z "${databaseUser}" ]]; then
  >&2 echo "No database user specified!"
  exit 1
fi

if [[ -z "${databasePassword}" ]]; then
  >&2 echo "No database password specified!"
  exit 1
fi

if [[ -z "${databaseName}" ]]; then
  >&2 echo "No database name specified!"
  exit 1
fi

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  touch "${currentPath}/../env.properties"
fi

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

if [[ -z "${databaseServerName}" ]]; then
  for server in "${serverList[@]}"; do
    serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
    if { [[ "${databaseHost}" == "localhost" ]] || [[ "${databaseHost}" == "127.0.0.1" ]]; } && [[ "${serverType}" == "local" ]]; then
      databaseServerName="${server}"
    elif [[ "${serverType}" != "local" ]]; then
      serverHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "host")
      if [[ "${serverHost}" == "${databaseHost}" ]]; then
        databaseServerName="${server}"
      fi
    fi
  done
fi

if [[ -z "${databaseServerName}" ]]; then
  >&2 echo "No server found for database host!"
  exit 1
fi

if [[ -z "${databaseId}" ]]; then
  databaseId="${databaseServerName}_database"
fi

if [[ -z "${upgradeServer}" ]]; then
  upgradeServer="server"
fi

if [[ -z "${upgradeServerName}" ]]; then
  upgradeServerName="${databaseServerName}"
fi

ini-set "${currentPath}/../env.properties" yes "${databaseServerName}" database "${databaseId}"
ini-set "${currentPath}/../env.properties" yes "${databaseId}" type "${databaseType}"
ini-set "${currentPath}/../env.properties" yes "${databaseId}" version "${databaseVersion}"
ini-set "${currentPath}/../env.properties" yes "${databaseId}" port "${databasePort}"
ini-set "${currentPath}/../env.properties" yes "${databaseId}" user "${databaseUser}"
ini-set "${currentPath}/../env.properties" yes "${databaseId}" password "${databasePassword}"
ini-set "${currentPath}/../env.properties" yes "${databaseId}" name "${databaseName}"
ini-set "${currentPath}/../env.properties" yes "${upgradeServerName}" upgrade yes
