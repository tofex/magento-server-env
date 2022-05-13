#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -i  Database id, default: database
  -o  Database host, default: localhost
  -t  Database type
  -v  Database version
  -p  Database port, default: 3306
  -u  Database user
  -s  Database password
  -d  Database name
  -g  Upgrade on server, default: server

Example: ${scriptName} -t mysql -v 5.7 -p 3306 -u magento -p magento -d magento
EOF
}

trim()
{
  echo -n "$1" | xargs
}

databaseId=
host=
type=
version=
port=
user=
password=
name=
upgradeServer=

while getopts hi:o:t:v:p:u:s:d:g:? option; do
  case "${option}" in
    h) usage; exit 1;;
    i) databaseId=$(trim "$OPTARG");;
    o) host=$(trim "$OPTARG");;
    t) type=$(trim "$OPTARG");;
    v) version=$(trim "$OPTARG");;
    p) port=$(trim "$OPTARG");;
    u) user=$(trim "$OPTARG");;
    s) password=$(trim "$OPTARG");;
    d) name=$(trim "$OPTARG");;
    g) upgradeServer=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${databaseId}" ]]; then
  databaseId="database"
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

if [[ -z "${port}" ]]; then
  port="3306"
fi

if [[ -z "${user}" ]]; then
  echo "No user specified!"
  exit 1
fi

if [[ -z "${password}" ]]; then
  echo "No password specified!"
  exit 1
fi

if [[ -z "${name}" ]]; then
  echo "No name specified!"
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

databaseServerName=
upgradeServerName=
for server in "${serverList[@]}"; do
  serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
  if { [[ "${host}" == "localhost" ]] || [[ "${host}" == "127.0.0.1" ]]; } && [[ "${serverType}" == "local" ]]; then
    databaseServerName="${server}"
  elif [[ "${serverType}" != "local" ]]; then
    serverHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "host")
    if [[ "${serverHost}" == "${host}" ]]; then
      databaseServerName="${server}"
    fi
  fi
  if [[ "${upgradeServer}" == "${server}" ]]; then
    upgradeServerName="${server}"
  fi
done

if [[ -z "${databaseServerName}" ]]; then
  echo ""
  echo "No server found for database host!"

  addServer=0
  echo ""
  echo "Do you wish to add a new server with the host name ${host}?"
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

    sshUser=$(whoami)
    echo ""
    echo "Please specify the SSH user, followed by [ENTER]:"
    read -r -i "${sshUser}" -e sshUser

    if [[ -z "${databaseServerName}" ]]; then
      echo "No server name specified!"
      exit 1
    fi

    if [[ -z "${sshUser}" ]]; then
      echo "No SSH user specified!"
      exit 1
    fi

    "${currentPath}/init-server.sh" \
      -n "${databaseServerName}" \
      -t ssh \
      -o "${host}" \
      -s "${sshUser}"
  fi
fi

if [[ -z "${databaseServerName}" ]]; then
  echo "No server found for database host!"
  exit 1
fi

if [[ -z "${upgradeServer}" ]]; then
  upgradeServer="server"
fi

if [[ -z "${upgradeServerName}" ]]; then
  upgradeServerName="${databaseServerName}"
fi

ini-set "${currentPath}/../env.properties" yes "${databaseServerName}" database "${databaseId}"
ini-set "${currentPath}/../env.properties" yes "${databaseId}" type "${type}"
ini-set "${currentPath}/../env.properties" yes "${databaseId}" version "${version}"
ini-set "${currentPath}/../env.properties" yes "${databaseId}" port "${port}"
ini-set "${currentPath}/../env.properties" yes "${databaseId}" user "${user}"
ini-set "${currentPath}/../env.properties" yes "${databaseId}" password "${password}"
ini-set "${currentPath}/../env.properties" yes "${databaseId}" name "${name}"
ini-set "${currentPath}/../env.properties" yes "${upgradeServerName}" upgrade yes
