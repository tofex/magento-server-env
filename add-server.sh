#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help         Show this message
  --name         Server name
  --type         Server type (local/ssh), default: local
  --host         Host if type != local
  --sshUser      SSH User if type == ssh
  --interactive  Interactive mode if data is missing

Example: ${scriptName} --name ws --type ssh --host 1.2.3.4 --sshUser user
EOF
}

name=
type=
host=
sshUser=
interactive=0

source "${currentPath}/../core/prepare-parameters.sh"

if [[ -z "${type}" ]] || [[ "${type}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the server type (local, remote, ssh), followed by [ENTER]:"
    read -r -i "local" -e type
  else
    >&2 echo "No server type specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ -z "${name}" ]] || [[ "${name}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the server name, followed by [ENTER]:"
    read -r -i "server" -e name
  else
    >&2 echo "No server name specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ "${type}" == "local" ]]; then
  "${currentPath}/init-server.sh" \
    --name "${name}" \
    --type "${type}"
else
  if [[ -z "${host}" ]] || [[ "${host}" == "-" ]]; then
    if [[ "${interactive}" == 1 ]]; then
      echo ""
      echo "Please specify the host, followed by [ENTER]:"
      read -r -e host
    else
      >&2 echo "No SSH specified!"
      echo ""
      usage
      exit 1
    fi
  fi

  if [[ "${type}" == "remote" ]]; then
    "${currentPath}/init-server.sh" \
      --name "${name}" \
      --type "${type}" \
      --host "${host}"
  elif [[ "${type}" == "ssh" ]]; then
    if [[ -z "${sshUser}" ]] || [[ "${sshUser}" == "-" ]]; then
      if [[ "${interactive}" == 1 ]]; then
        echo ""
        echo "Please specify the SSH user, followed by [ENTER]:"
        read -r -e sshUser
      else
        >&2 echo "No SSH user specified!"
        echo ""
        usage
        exit 1
      fi
    fi

    "${currentPath}/init-server.sh" \
      --name "${name}" \
      --type "${type}" \
      --host "${host}" \
      --sshUser "${sshUser}"
  fi
fi
