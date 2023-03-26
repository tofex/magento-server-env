#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help     Show this message
  --name     Server name
  --type     Server type (local/remote/ssh), default: local
  --host     Host if type != local
  --sshUser  SSH User if type == ssh

Example: ${scriptName} --name ws --type ssh --host 1.2.3.4 --sshUser user
EOF
}

name=
type=
host=
sshUser=

source "${currentPath}/../core/prepare-parameters.sh"

if [[ -z "${name}" ]]; then
  >&2 echo "No name specified!"
  echo ""
  usage
  exit 1
fi

if [[ -z "${type}" ]]; then
  type="local"
fi

if [[ "${type}" != "local" ]] && [[ "${type}" != "remote" ]] && [[ "${type}" != "ssh" ]]; then
  >&2 echo "Invalid server type specified: ${type}!"
  exit 1
fi

if [[ "${type}" == "ssh" ]]; then
  if [[ -z "${host}" ]] || [[ "${host}" == "-" ]]; then
    >&2 echo "No host specified!"
    echo ""
    usage
    exit 1
  fi

  if [[ -z "${sshUser}" ]] || [[ "${sshUser}" == "-" ]]; then
    >&2 echo "No SSH user specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  >&2 echo "No environment specified!"
  exit 1
fi

ini-set "${currentPath}/../env.properties" no system server "${name}"
ini-set "${currentPath}/../env.properties" yes "${name}" type "${type}"

if [[ "${type}" == "remote" ]] || [[ "${type}" == "ssh" ]]; then
  ini-set "${currentPath}/../env.properties" yes "${name}" host "${host}"
fi

if [[ "${type}" == "ssh" ]]; then
  ini-set "${currentPath}/../env.properties" yes "${name}" user "${sshUser}"
fi
