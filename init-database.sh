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
  --upgradeServer       Upgrade on server, default: server name

Example: ${scriptName} --databaseType mysql --databaseVersion 5.7 --databaseUser magento --databasePassword magento --databaseName magento
EOF
}

serverName=
databaseId=
databaseHost=
databaseType=
databaseVersion=
databasePort=
databaseUser=
databasePassword=
databaseName=
upgradeServer=

source "${currentPath}/../core/prepare-parameters.sh"

if [[ -z "${databaseHost}" ]]; then
  databaseHost="localhost"
fi

if [[ -z "${databaseType}" ]]; then
  >&2 echo "No databaseType specified!"
  exit 1
fi

if [[ -z "${databaseVersion}" ]]; then
  >&2 echo "No databaseVersion specified!"
  exit 1
fi

if [[ -z "${databasePort}" ]]; then
  databasePort="3306"
fi

if [[ -z "${databaseUser}" ]]; then
  >&2 echo "No user specified!"
  exit 1
fi

if [[ -z "${databasePassword}" ]]; then
  >&2 echo "No password specified!"
  exit 1
fi

if [[ -z "${databaseName}" ]]; then
  >&2 echo "No name specified!"
  exit 1
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

if [[ -z "${serverName}" ]]; then
  databaseServerName=
  upgradeServerName=
  for server in "${serverList[@]}"; do
    serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "databaseType")
    if { [[ "${databaseHost}" == "localhost" ]] || [[ "${databaseHost}" == "127.0.0.1" ]]; } && [[ "${serverType}" == "local" ]]; then
      databaseServerName="${server}"
    elif [[ "${serverType}" != "local" ]]; then
      serverHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "host")
      if [[ "${serverHost}" == "${databaseHost}" ]]; then
        databaseServerName="${server}"
      fi
    fi
    if [[ "${upgradeServer}" == "${server}" ]]; then
      upgradeServerName="${server}"
    fi
  done
else
  databaseServerName="${serverName}"
fi

if [[ -z "${databaseServerName}" ]]; then
  echo ""
  echo "No server found for database databaseHost!"

  addServer=0
  echo ""
  echo "Do you wish to add a new server with the host name ${databaseHost}?"
  select yesNo in "Yes" "No"; do
    case "${yesNo}" in
      Yes ) addServer=1; break;;
      No ) break;;
    esac
  done

  if [[ "${addServer}" == 1 ]]; then
    echo ""
    echo "Please specify the server name, followed by [ENTER]:"
    read -r -i "database_server" -e databaseServerName

    if [[ -z "${databaseServerName}" ]]; then
      echo "No server name specified!"
      exit 1
    fi

    databaseServerType=0
    echo ""
    echo "What databaseType is the new server (ssh or remote)?"
    select selection in "ssh" "remote"; do
      case "${selection}" in
        Yes ) databaseServerType="ssh"; break;;
        No ) databaseServerType="remote"; break;;
      esac
    done

    if [[ "${databaseServerType}" == "remote" ]]; then
      "${currentPath}/init-server.sh" \
        --name "${databaseServerName}" \
        --databaseType remote \
        --databaseHost "${databaseHost}"
    elif [[ "${databaseServerType}" == "ssh" ]]; then
      sshUser=$(whoami)
      echo ""
      echo "Please specify the SSH user, followed by [ENTER]:"
      read -r -i "${sshUser}" -e sshUser

      if [[ -z "${sshUser}" ]]; then
        echo "No SSH user specified!"
        exit 1
      fi

      "${currentPath}/init-server.sh" \
        --name "${databaseServerName}" \
        --databaseType ssh \
        --databaseHost "${databaseHost}" \
        --sshUser "${sshUser}"
    fi
  fi
fi

if [[ -z "${databaseServerName}" ]]; then
  >&2 echo "No server found for database host!"
  exit 1
fi

if [[ -z "${databaseId}" ]]; then
  databaseId="${serverName}_database"
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
ini-set "${currentPath}/../env.properties" yes "${databaseServerName}" upgrade yes
