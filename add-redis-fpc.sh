#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help                          Show this message
  --redisFullPageCacheServerName  Name of full page cache server
  --redisFullPageCacheServerType  Type of full page cache server (local, remote, ssh)
  --redisFullPageCacheServerUser  User of full page cache server (only if type=ssh)
  --redisFullPageCacheHost        Redis host, default: localhost
  --redisFullPageCacheVersion     Redis version
  --redisFullPageCachePort        Redis port, default: 6380
  --redisFullPageCachePassword    Redis password (optional)
  --redisFullPageCacheDatabase    Database number, default: 0
  --redisFullPageCachePrefix      Cache prefix (optional)
  --redisFullPageCacheClassName   Name of PHP class (optional)
  --interactive                   Interactive mode if data is missing

Example: ${scriptName}
EOF
}

redisFullPageCacheServerName=
redisFullPageCacheServerType=
redisFullPageCacheServerUser=
redisFullPageCacheHost=
redisFullPageCacheVersion=
redisFullPageCachePort=
redisFullPageCachePassword=
redisFullPageCacheDatabase=
redisFullPageCachePrefix=
redisFullPageCacheClassName=
interactive=0

source "${currentPath}/../core/prepare-parameters.sh"

if [[ -f /opt/install/env.properties ]]; then
  if [[ -z "${redisFullPageCacheVersion}" ]] || [[ "${redisFullPageCacheVersion}" == "-" ]]; then
    redisFullPageCacheVersion=$(ini-parse "/opt/install/env.properties" "no" "redis" "fullPageCacheVersion")
  fi
  if [[ -z "${redisFullPageCachePort}" ]] || [[ "${redisFullPageCachePort}" == "-" ]]; then
    redisFullPageCachePort=$(ini-parse "/opt/install/env.properties" "no" "redis" "fullPageCachePort")
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

if { [[ -z "${redisFullPageCacheServerName}" ]] || [[ "${redisFullPageCacheServerName}" == "-" ]]; } && [[ -n "${redisFullPageCacheHost}" ]]; then
  for server in "${serverList[@]}"; do
    serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")

    if { [[ "${redisFullPageCacheHost}" == "localhost" ]] || [[ "${redisFullPageCacheHost}" == "127.0.0.1" ]]; } && [[ "${serverType}" == "local" ]]; then
      redisFullPageCacheServerName="${server}"
      redisFullPageCacheServerType="local"
    elif [[ "${serverType}" != "local" ]]; then
      serverHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "host")

      if [[ "${serverHost}" == "${redisFullPageCacheHost}" ]]; then
        redisFullPageCacheServerName="${server}"
        redisFullPageCacheServerType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
      fi
    fi
  done
fi

if [[ -z "${redisFullPageCacheServerName}" ]] || [[ "${redisFullPageCacheServerName}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the redis full page cache server name, followed by [ENTER]:"
    read -r -i "server" -e redisFullPageCacheServerName
  else
    >&2 echo "No redis full page cache server name specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ -z "${redisFullPageCacheServerType}" ]] || [[ "${redisFullPageCacheServerType}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the redis full page cache server type, followed by [ENTER]:"
    read -r -i "remote" -e redisFullPageCacheServerType
  else
    >&2 echo "No redis full page cache server type specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ "${redisFullPageCacheServerType}" == "local" ]]; then
  if [[ -z "${redisFullPageCacheHost}" ]] || [[ "${redisFullPageCacheHost}" == "-" ]]; then
    redisFullPageCacheHost="localhost"
  fi
elif [[ "${redisFullPageCacheServerType}" == "remote" ]]; then
  if [[ -z "${redisFullPageCacheHost}" ]] || [[ "${redisFullPageCacheHost}" == "-" ]]; then
    echo ""
    echo "Please specify the redis full page cache server host, followed by [ENTER]:"
    read -r -e redisFullPageCacheHost
  fi
elif [[ "${redisFullPageCacheServerType}" == "ssh" ]]; then
  if [[ -z "${redisFullPageCacheHost}" ]] || [[ "${redisFullPageCacheHost}" == "-" ]]; then
    echo ""
    echo "Please specify the redis full page cache server host, followed by [ENTER]:"
    read -r -e redisFullPageCacheHost
  fi

  if [[ -z "${redisFullPageCacheServerUser}" ]] || [[ "${redisFullPageCacheServerUser}" == "-" ]]; then
    echo ""
    echo "Please specify the redis full page cache server user, followed by [ENTER]:"
    read -r -e redisFullPageCacheServerUser
  fi
fi

if [[ -z "${redisFullPageCacheVersion}" ]] || [[ "${redisFullPageCacheVersion}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the redis full page cache version, followed by [ENTER]:"
    read -r -e redisFullPageCacheVersion
  else
    >&2 echo "No redis full page cache version specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ -z "${redisFullPageCachePort}" ]] || [[ "${redisFullPageCachePort}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the redis full page cache port, followed by [ENTER]:"
    read -r -i "${redisFullPageCachePort}" -e redisFullPageCachePort
  else
    >&2 echo "No redis full page cache port specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ -z "${redisFullPageCacheDatabase}" ]] || [[ "${redisFullPageCacheDatabase}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the redis full page cache database, followed by [ENTER]:"
    read -r -i "0" -e redisFullPageCacheDatabase
  else
    >&2 echo "No redis full page cache database specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ -z "${redisFullPageCachePassword}" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the redis full page cache password (empty to generate), followed by [ENTER]:"
    read -r -e redisFullPageCachePassword
  fi
fi

generatePassword=0
if [[ -z "${redisFullPageCachePassword}" ]]; then
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

if [[ -z "${redisFullPageCachePassword}" ]]; then
  if [[ "${generatePassword}" == 1 ]]; then
    redisFullPageCachePassword=$(echo "${RANDOM}" | md5sum | head -c 32)
  fi
fi
if [[ -z "${redisFullPageCachePassword}" ]]; then
  redisFullPageCachePassword="-"
fi

if [[ -z "${redisFullPageCachePrefix}" ]] || [[ "${redisFullPageCachePrefix}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the redis full page cache prefix, followed by [ENTER]:"
    read -r -e redisFullPageCachePrefix
  fi
fi
if [[ -z "${redisFullPageCachePrefix}" ]]; then
  redisFullPageCachePrefix="-"
fi

if [[ "${redisFullPageCacheServerType}" == "local" ]]; then
  "${currentPath}/init-server.sh" \
    --name "${redisFullPageCacheServerName}" \
    --type "${redisFullPageCacheServerType}"
elif [[ "${redisFullPageCacheServerType}" == "remote" ]]; then
  "${currentPath}/init-server.sh" \
    --name "${redisFullPageCacheServerName}" \
    --type "${redisFullPageCacheServerType}" \
    --host "${redisFullPageCacheHost}"
elif [[ "${redisFullPageCacheServerType}" == "ssh" ]]; then
  "${currentPath}/init-server.sh" \
    --name "${redisFullPageCacheServerName}" \
    --type "${redisFullPageCacheServerType}" \
    --host "${redisFullPageCacheHost}" \
    --sshUser "${redisFullPageCacheServerUser}"
fi

"${currentPath}/init-redis-fpc.sh" \
  --redisFullPageCacheHost "${redisFullPageCacheHost}" \
  --redisFullPageCacheVersion "${redisFullPageCacheVersion}" \
  --redisFullPageCachePort "${redisFullPageCachePort}" \
  --redisFullPageCacheDatabase "${redisFullPageCacheDatabase}" \
  --redisFullPageCachePassword "${redisFullPageCachePassword}" \
  --redisFullPageCachePrefix "${redisFullPageCachePrefix}" \
  --redisFullPageCacheClassName "${redisFullPageCacheClassName}"
