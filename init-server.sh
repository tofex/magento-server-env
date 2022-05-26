#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -n  Server name
  -t  Type, default: local
  -o  Host if type != local
  -p  Web path
  -u  Web user, default: www-data
  -g  Web group, default: www-data
  -s  SSH User if type == ssh

Example: ${scriptName} -n server
EOF
}

trim()
{
  echo -n "$1" | xargs
}

serverName=
type=
host=
sshUser=
webPath=
webUser=
webGroup=

while getopts hn:t:o:s:p:u:g:? option; do
  case "${option}" in
    h) usage; exit 1;;
    n) serverName=$(trim "$OPTARG");;
    t) type=$(trim "$OPTARG");;
    o) host=$(trim "$OPTARG");;
    s) sshUser=$(trim "$OPTARG");;
    p) webPath=$(trim "$OPTARG");;
    u) webUser=$(trim "$OPTARG");;
    g) webGroup=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${serverName}" ]]; then
  echo "No server name specified!"
  exit 1
fi

if [[ -z "${type}" ]]; then
  type="local"
fi

if [[ "${type}" != "local" ]]; then
  if [[ -z "${host}" ]] || [[ "${host}" == "-" ]]; then
    echo "No host specified!"
    exit 1
  fi
fi

if [[ "${type}" == "ssh" ]]; then
  if [[ -z "${sshUser}" ]] || [[ "${sshUser}" == "-" ]]; then
    echo "No SSH user specified!"
    exit 1
  fi
fi

if [[ -z "${webUser}" ]]; then
  webUser="www-data"
fi

if [[ -z "${webGroup}" ]]; then
  webGroup="www-data"
fi

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  touch "${currentPath}/../env.properties"
fi

ini-set "${currentPath}/../env.properties" no system server "${serverName}"
ini-set "${currentPath}/../env.properties" yes "${serverName}" type "${type}"
if [[ "${type}" != "local" ]]; then
  ini-set "${currentPath}/../env.properties" yes "${serverName}" host "${host}"
fi
if [[ "${type}" == "ssh" ]]; then
  ini-set "${currentPath}/../env.properties" yes "${serverName}" user "${sshUser}"
fi
if [[ -n "${webPath}" ]] && [[ "${webPath}" != "-" ]]; then
  ini-set "${currentPath}/../env.properties" yes "${serverName}" webPath "${webPath}"
  ini-set "${currentPath}/../env.properties" yes "${serverName}" webUser "${webUser}"
  ini-set "${currentPath}/../env.properties" yes "${serverName}" webGroup "${webGroup}"
fi
