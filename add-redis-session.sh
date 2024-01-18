#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help                    Show this message
  --redisSessionServerName  Name of session server
  --redisSessionServerType  Type of session server (local, remote, ssh)
  --redisSessionServerUser  User of session server (only if type=ssh)
  --redisSessionHost        Redis host, default: localhost
  --redisSessionVersion     Redis version
  --redisSessionPort        Redis port, default: 6381
  --redisSessionPassword    Redis password (optional)
  --redisSessionDatabase    Database number, default: 0
  --interactive             Interactive mode if data is missing

Example: ${scriptName}
EOF
}

redisSessionServerName=
redisSessionServerType=
redisSessionServerUser=
redisSessionHost=
redisSessionVersion=
redisSessionPort=
redisSessionPassword=
redisSessionDatabase=
interactive=0

source "${currentPath}/../core/prepare-parameters.sh"

if [[ -f /opt/install/env.properties ]]; then
  if [[ -z "${redisSessionVersion}" ]] || [[ "${redisSessionVersion}" == "-" ]]; then
    redisSessionVersion=$(ini-parse "/opt/install/env.properties" "no" "redis" "sessionVersion")
  fi
  if [[ -z "${redisSessionPort}" ]] || [[ "${redisSessionPort}" == "-" ]]; then
    redisSessionPort=$(ini-parse "/opt/install/env.properties" "no" "redis" "sessionPort")
  fi
fi

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  touch "${currentPath}/../env.properties"
fi

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

if { [[ -z "${redisSessionServerName}" ]] || [[ "${redisSessionServerName}" == "-" ]]; } && [[ -n "${redisSessionHost}" ]]; then
  for server in "${serverList[@]}"; do
    serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")

    if { [[ "${redisSessionHost}" == "localhost" ]] || [[ "${redisSessionHost}" == "127.0.0.1" ]]; } && [[ "${serverType}" == "local" ]]; then
      redisSessionServerName="${server}"
      redisSessionServerType="local"
    elif [[ "${serverType}" != "local" ]]; then
      serverHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "host")

      if [[ "${serverHost}" == "${redisSessionHost}" ]]; then
        redisSessionServerName="${server}"
        redisSessionServerType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
      fi
    fi
  done
fi

if [[ -z "${redisSessionServerName}" ]] || [[ "${redisSessionServerName}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the redis session server name, followed by [ENTER]:"
    read -r -i "server" -e redisSessionServerName
  else
    >&2 echo "No redis session server name specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ -z "${redisSessionServerType}" ]] || [[ "${redisSessionServerType}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the redis session server type, followed by [ENTER]:"
    read -r -i "remote" -e redisSessionServerType
  else
    >&2 echo "No redis session server type specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ "${redisSessionServerType}" == "local" ]]; then
  if [[ -z "${redisSessionHost}" ]] || [[ "${redisSessionHost}" == "-" ]]; then
    redisSessionHost="localhost"
  fi
elif [[ "${redisSessionServerType}" == "remote" ]]; then
  if [[ -z "${redisSessionHost}" ]] || [[ "${redisSessionHost}" == "-" ]]; then
    echo ""
    echo "Please specify the redis session server host, followed by [ENTER]:"
    read -r -e redisSessionHost
  fi
elif [[ "${redisSessionServerType}" == "ssh" ]]; then
  if [[ -z "${redisSessionHost}" ]] || [[ "${redisSessionHost}" == "-" ]]; then
    echo ""
    echo "Please specify the redis session server host, followed by [ENTER]:"
    read -r -e redisSessionHost
  fi

  if [[ -z "${redisSessionServerUser}" ]] || [[ "${redisSessionServerUser}" == "-" ]]; then
    echo ""
    echo "Please specify the redis session server user, followed by [ENTER]:"
    read -r -e redisSessionServerUser
  fi
fi

if [[ -z "${redisSessionVersion}" ]] || [[ "${redisSessionVersion}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the redis session version, followed by [ENTER]:"
    read -r -e redisSessionVersion
  else
    >&2 echo "No redis session version specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ -z "${redisSessionPort}" ]] || [[ "${redisSessionPort}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the redis session port, followed by [ENTER]:"
    read -r -i "${redisSessionPort}" -e redisSessionPort
  else
    >&2 echo "No redis session port specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ -z "${redisSessionDatabase}" ]] || [[ "${redisSessionDatabase}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the redis session database, followed by [ENTER]:"
    read -r -i "0" -e redisSessionDatabase
  else
    >&2 echo "No redis session database specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ -z "${redisSessionPassword}" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the redis session password, followed by [ENTER]:"
    read -r -e redisSessionPassword
  fi
fi

generatePassword=0
if [[ -z "${redisSessionPassword}" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Do you wish to generate a password?"
    select yesNo in "Yes" "No"; do
      case "${yesNo}" in
        Yes ) generatePassword=1; break;;
        No ) break;;
      esac
    done
  fi
fi

if [[ -z "${redisSessionPassword}" ]]; then
  if [[ "${generatePassword}" == 1 ]]; then
    redisSessionPassword=$(echo "${RANDOM}" | md5sum | head -c 32)
  fi
fi
if [[ -z "${redisSessionPassword}" ]]; then
  redisSessionPassword="-"
fi

if [[ "${redisSessionServerType}" == "local" ]]; then
  "${currentPath}/init-server.sh" \
    --name "${redisSessionServerName}" \
    --type "${redisSessionServerType}"
elif [[ "${redisSessionServerType}" == "remote" ]]; then
  "${currentPath}/init-server.sh" \
    --name "${redisSessionServerName}" \
    --type "${redisSessionServerType}" \
    --host "${redisSessionHost}"
elif [[ "${redisSessionServerType}" == "ssh" ]]; then
  "${currentPath}/init-server.sh" \
    --name "${redisSessionServerName}" \
    --type "${redisSessionServerType}" \
    --host "${redisSessionHost}" \
    --sshUser "${redisSessionServerUser}"
fi

"${currentPath}/init-redis-session.sh" \
  --redisSessionHost "${redisSessionHost}" \
  --redisSessionVersion "${redisSessionVersion}" \
  --redisSessionPort "${redisSessionPort}" \
  --redisSessionDatabase "${redisSessionDatabase}" \
  --redisSessionPassword "${redisSessionPassword}"
