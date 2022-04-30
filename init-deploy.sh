#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -n  Server name, default: server
  -d  Deploy path
  -c  History count, default: 5
  -u  Upgrade database from this server (yes or no), default: yes

Example: ${scriptName} -n server -d /var/www/magento/releases
EOF
}

trim()
{
  echo -n "$1" | xargs
}

serverName=
path=
historyCount=
upgrade=

while getopts hn:d:c:u:? option; do
  case "${option}" in
    h) usage; exit 1;;
    n) serverName=$(trim "$OPTARG");;
    d) path=$(trim "$OPTARG");;
    c) historyCount=$(trim "$OPTARG");;
    u) upgrade=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${serverName}" ]]; then
  serverName="server"
fi

if [[ -z "${path}" ]]; then
  echo "No build path specified!"
  exit 1
fi

if [[ -z "${historyCount}" ]]; then
  historyCount=5
fi

if [[ -z "${upgrade}" ]]; then
  upgrade="yes"
fi

if [[ "${upgrade}" != "yes" ]] && [[ "${upgrade}" != "no" ]]; then
  echo "Invalid upgrade (yes or no) specified!"
  exit 1
fi

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  touch "${currentPath}/../env.properties"
fi

ini-set "${currentPath}/../env.properties" yes "${serverName}" deployPath "${path}"
ini-set "${currentPath}/../env.properties" yes "${serverName}" upgrade "${upgrade}"
ini-set "${currentPath}/../env.properties" yes deploy server "${serverName}"
ini-set "${currentPath}/../env.properties" yes deploy deployHistoryCount "${historyCount}"
