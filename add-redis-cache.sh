#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help                  Show this message
  --redisCacheServerName  Name of cache server
  --redisCacheServerType  Type of cache server (local, remote, ssh)
  --redisCacheServerUser  User of cache server (only if type=ssh)
  --redisCacheHost        Redis host, default: localhost
  --redisCacheVersion     Redis version
  --redisCachePort        Redis port, default: 6379
  --redisCachePassword    Redis password (optional)
  --redisCacheDatabase    Database number, default: 0
  --redisCachePrefix      Cache prefix (optional)
  --redisCacheClassName   Name of PHP class (optional)
  --interactive           Interactive mode if data is missing

Example: ${scriptName}
EOF
}

redisCacheServerName=
redisCacheServerType=
redisCacheServerUser=
redisCacheHost=
redisCacheVersion=
redisCachePort=
redisCachePassword=
redisCacheDatabase=
redisCachePrefix=
redisCacheClassName=
interactive=0

source "${currentPath}/../core/prepare-parameters.sh"

if [[ -f /opt/install/env.properties ]]; then
  if [[ -z "${redisCacheVersion}" ]] || [[ "${redisCacheVersion}" == "-" ]]; then
    redisCacheVersion=$(ini-parse "/opt/install/env.properties" "no" "redis" "cacheVersion")
  fi
  if [[ -z "${redisCachePort}" ]] || [[ "${redisCachePort}" == "-" ]]; then
    redisCachePort=$(ini-parse "/opt/install/env.properties" "no" "redis" "cachePort")
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

if { [[ -z "${redisCacheServerName}" ]] || [[ "${redisCacheServerName}" == "-" ]]; } && [[ -n "${redisCacheHost}" ]]; then
  for server in "${serverList[@]}"; do
    serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")

    if { [[ "${redisCacheHost}" == "localhost" ]] || [[ "${redisCacheHost}" == "127.0.0.1" ]]; } && [[ "${serverType}" == "local" ]]; then
      redisCacheServerName="${server}"
      redisCacheServerType="local"
    elif [[ "${serverType}" != "local" ]]; then
      serverHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "host")

      if [[ "${serverHost}" == "${redisCacheHost}" ]]; then
        redisCacheServerName="${server}"
        redisCacheServerType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
      fi
    fi
  done
fi

if [[ -z "${redisCacheServerName}" ]] || [[ "${redisCacheServerName}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the redis cache server name, followed by [ENTER]:"
    read -r -i "${redisCacheHost}" -e redisCacheServerName
  else
    >&2 echo "No redis cache server name specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ -z "${redisCacheServerType}" ]] || [[ "${redisCacheServerType}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the redis cache server type, followed by [ENTER]:"
    read -r -i "remote" -e redisCacheServerType
  else
    >&2 echo "No redis cache server type specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ "${redisCacheServerType}" == "local" ]]; then
  if [[ -z "${redisCacheHost}" ]] || [[ "${redisCacheHost}" == "-" ]]; then
    redisCacheHost="localhost"
  fi
elif [[ "${redisCacheServerType}" == "remote" ]]; then
  if [[ -z "${redisCacheHost}" ]] || [[ "${redisCacheHost}" == "-" ]]; then
    echo ""
    echo "Please specify the redis cache server host, followed by [ENTER]:"
    read -r -e redisCacheHost
  fi
elif [[ "${redisCacheServerType}" == "ssh" ]]; then
  if [[ -z "${redisCacheHost}" ]] || [[ "${redisCacheHost}" == "-" ]]; then
    echo ""
    echo "Please specify the redis cache server host, followed by [ENTER]:"
    read -r -e redisCacheHost
  fi

  if [[ -z "${redisCacheServerUser}" ]] || [[ "${redisCacheServerUser}" == "-" ]]; then
    echo ""
    echo "Please specify the redis cache server user, followed by [ENTER]:"
    read -r -e redisCacheServerUser
  fi
fi

if [[ -z "${redisCacheVersion}" ]] || [[ "${redisCacheVersion}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the redis cache version, followed by [ENTER]:"
    read -r -e redisCacheVersion
  else
    >&2 echo "No redis cache version specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ -z "${redisCachePort}" ]] || [[ "${redisCachePort}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the redis cache port, followed by [ENTER]:"
    read -r -i "${redisCachePort}" -e redisCachePort
  else
    >&2 echo "No redis cache port specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ -z "${redisCacheDatabase}" ]] || [[ "${redisCacheDatabase}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the redis cache database, followed by [ENTER]:"
    read -r -i "0" -e redisCacheDatabase
  else
    >&2 echo "No redis cache database specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ -z "${redisCachePassword}" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the redis cache password, followed by [ENTER]:"
    read -r -e redisCachePassword
  fi
fi

generatePassword=0
if [[ -z "${redisCachePassword}" ]]; then
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

if [[ -z "${redisCachePassword}" ]]; then
  if [[ "${generatePassword}" == 1 ]]; then
    redisCachePassword=$(echo "${RANDOM}" | md5sum | head -c 32)
  fi
fi
if [[ -z "${redisCachePassword}" ]]; then
  redisCachePassword="-"
fi

if [[ -z "${redisCachePrefix}" ]] || [[ "${redisCachePrefix}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the redis cache prefix, followed by [ENTER]:"
    read -r -e redisCachePrefix
  fi
fi
if [[ -z "${redisCachePrefix}" ]]; then
  redisCachePrefix="-"
fi

if [[ "${redisCacheServerType}" == "local" ]]; then
  "${currentPath}/init-server.sh" \
    --name "${redisCacheServerName}" \
    --type "${redisCacheServerType}"
elif [[ "${redisCacheServerType}" == "remote" ]]; then
  "${currentPath}/init-server.sh" \
    --name "${redisCacheServerName}" \
    --type "${redisCacheServerType}" \
    --host "${redisCacheHost}"
elif [[ "${redisCacheServerType}" == "ssh" ]]; then
  "${currentPath}/init-server.sh" \
    --name "${redisCacheServerName}" \
    --type "${redisCacheServerType}" \
    --host "${redisCacheHost}" \
    --sshUser "${redisCacheServerUser}"
fi

"${currentPath}/init-redis-cache.sh" \
  --redisCacheHost "${redisCacheHost}" \
  --redisCacheVersion "${redisCacheVersion}" \
  --redisCachePort "${redisCachePort}" \
  --redisCacheDatabase "${redisCacheDatabase}" \
  --redisCachePassword "${redisCachePassword}" \
  --redisCachePrefix "${redisCachePrefix}" \
  --redisCacheClassName "${redisCacheClassName}"
