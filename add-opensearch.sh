#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help                  Show this message
  --openSearchServerName  Name of server to use (optional)
  --openSearchServerType  Type of server (local, remote, ssh)
  --openSearchServerUser  User if server type is SSH
  --openSearchHost        OpenSearch host, default: localhost
  --openSearchSsl         OpenSearch SSL (true/false), default: false
  --openSearchVersion     OpenSearch version
  --openSearchPort        OpenSearch port, default: 9200
  --openSearchPrefix      OpenSearch prefix
  --openSearchUser        User name if behind basic auth
  --openSearchPassword    Password if behind basic auth

Example: ${scriptName}
EOF
}

openSearchServerName=
openSearchServerType=
openSearchServerUser=
openSearchHost=
openSearchSsl=
openSearchVersion=
openSearchPort=
openSearchPrefix=
interactive=0

source "${currentPath}/../core/prepare-parameters.sh"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  touch "${currentPath}/../env.properties"
fi

if [[ -f /opt/install/env.properties ]]; then
  if [[ -z "${openSearchVersion}" ]] || [[ "${openSearchVersion}" == "-" ]]; then
    openSearchVersion=$(ini-parse "/opt/install/env.properties" "no" "opensearch" "version")
  fi
  if [[ -z "${openSearchPort}" ]] || [[ "${openSearchPort}" == "-" ]]; then
    openSearchPort=$(ini-parse "/opt/install/env.properties" "no" "opensearch" "port")
  fi
fi

if [[ -z "${openSearchPort}" ]] || [[ "${openSearchPort}" == "-" ]]; then
  if [[ -f /opt/install/env.properties ]]; then
    openSearchPort=$(ini-parse "/opt/install/env.properties" "no" "opensearch" "port")
  else
    openSearchPort="9200"
  fi
fi

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

if { [[ -z "${openSearchServerName}" ]] || [[ "${openSearchServerName}" == "-" ]]; } && [[ -n "${openSearchHost}" ]]; then
  for server in "${serverList[@]}"; do
    serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")

    if { [[ "${openSearchHost}" == "localhost" ]] || [[ "${openSearchHost}" == "127.0.0.1" ]]; } && [[ "${serverType}" == "local" ]]; then
      openSearchServerName="${server}"
    elif [[ "${serverType}" != "local" ]]; then
      serverHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "host")
      if [[ "${serverHost}" == "${openSearchHost}" ]]; then
        openSearchServerName="${server}"
      fi
    fi
  done
fi

if [[ -z "${openSearchServerName}" ]] || [[ "${openSearchServerName}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the OpenSearch server name, followed by [ENTER]:"
    read -r -i "${openSearchHost}" -e openSearchServerName
  else
    >&2 echo "No OpenSearch server name specified!"
    echo ""
    usage
    exit 1
  fi
fi

if { [[ -z "${openSearchServerName}" ]] || [[ "${openSearchServerName}" == "-" ]]; } && [[ -n "${openSearchHost}" ]]; then
  for server in "${serverList[@]}"; do
    serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")

    if { [[ "${openSearchHost}" == "localhost" ]] || [[ "${openSearchHost}" == "127.0.0.1" ]]; } && [[ "${serverType}" == "local" ]]; then
      openSearchServerName="${server}"
      openSearchServerType="local"
    elif [[ "${serverType}" != "local" ]]; then
      serverHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "host")

      if [[ "${serverHost}" == "${openSearchHost}" ]]; then
        openSearchServerName="${server}"
        openSearchServerType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
      fi
    fi
  done
fi

if [[ -z "${openSearchServerType}" ]] || [[ "${openSearchServerType}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the OpenSearch server user, followed by [ENTER]:"
    read -r -i "remote" -e openSearchServerType
  else
    >&2 echo "No OpenSearch server type specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ "${openSearchServerType}" == "local" ]]; then
  if [[ -z "${openSearchHost}" ]] || [[ "${openSearchHost}" == "-" ]]; then
    openSearchHost="localhost"
  fi
elif [[ "${openSearchServerType}" == "remote" ]]; then
  if [[ -z "${openSearchHost}" ]] || [[ "${openSearchHost}" == "-" ]]; then
    echo ""
    echo "Please specify the OpenSearch server host, followed by [ENTER]:"
    read -r -e openSearchHost
  fi
elif [[ "${openSearchServerType}" == "ssh" ]]; then
  if [[ -z "${openSearchHost}" ]] || [[ "${openSearchHost}" == "-" ]]; then
    echo ""
    echo "Please specify the OpenSearch server host, followed by [ENTER]:"
    read -r -e openSearchHost
  fi

  if [[ -z "${openSearchServerUser}" ]] || [[ "${openSearchServerUser}" == "-" ]]; then
    echo ""
    echo "Please specify the OpenSearch server user, followed by [ENTER]:"
    read -r -e openSearchServerUser
  fi
fi

if [[ -z "${openSearchSsl}" ]] || [[ "${openSearchSsl}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Is OpenSearch using SSL?"
    select yesNo in "Yes" "No"; do
      case "${yesNo}" in
        Yes ) openSearchSsl="true"; break;;
        No ) openSearchSsl="false"; break;;
      esac
    done
  else
    >&2 echo "No OpenSearch version specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ -z "${openSearchVersion}" ]] || [[ "${openSearchVersion}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the OpenSearch version, followed by [ENTER]:"
    read -r -i "${openSearchVersion}" -e openSearchVersion
  else
    >&2 echo "No OpenSearch version specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ -z "${openSearchPort}" ]] || [[ "${openSearchPort}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the OpenSearch port, followed by [ENTER]:"
    read -r -i "${openSearchPort}" -e openSearchPort
  else
    >&2 echo "No OpenSearch port specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ -z "${openSearchPrefix}" ]] || [[ "${openSearchPrefix}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the OpenSearch prefix, followed by [ENTER]:"
    read -r -i "magento" -e openSearchPrefix
  else
    >&2 echo "No OpenSearch prefix specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ "${interactive}" == 1 ]]; then
  useBasicAuth=0
  echo ""
  echo "Is OpenSearch behind basic auth?"
  select yesNo in "Yes" "No"; do
    case "${yesNo}" in
      Yes ) useBasicAuth=1; break;;
      No ) break;;
    esac
  done

  if [[ "${useBasicAuth}" == 1 ]]; then
    echo ""
    echo "Please specify the OpenSearch user, followed by [ENTER]:"
    read -r -e openSearchUser

    echo ""
    echo "Please specify the OpenSearch password, followed by [ENTER]:"
    read -r -e openSearchPassword
  else
    openSearchUser=
    openSearchPassword=
  fi
fi

if [[ "${openSearchServerType}" == "local" ]]; then
  "${currentPath}/init-server.sh" \
    --name "${openSearchServerName}" \
    --type "${openSearchServerType}"
elif [[ "${openSearchServerType}" == "remote" ]]; then
  "${currentPath}/init-server.sh" \
    --name "${openSearchServerName}" \
    --type "${openSearchServerType}" \
    --host "${openSearchHost}"
elif [[ "${openSearchServerType}" == "ssh" ]]; then
  "${currentPath}/init-server.sh" \
    --name "${openSearchServerName}" \
    --type "${openSearchServerType}" \
    --host "${openSearchHost}" \
    --sshUser "${openSearchServerUser}"
fi

if [[ -n "${openSearchUser}" ]] && [[ -n "${openSearchPassword}" ]]; then
  "${currentPath}/init-opensearch.sh" \
    --openSearchHost "${openSearchHost}" \
    --openSearchSsl "${openSearchSsl}" \
    --openSearchVersion "${openSearchVersion}" \
    --openSearchPort "${openSearchPort}" \
    --openSearchPrefix "${openSearchPrefix}" \
    --openSearchUser "${openSearchUser}" \
    --openSearchPassword "${openSearchPassword}"
else
  "${currentPath}/init-opensearch.sh" \
    --openSearchHost "${openSearchHost}" \
    --openSearchSsl "${openSearchSsl}" \
    --openSearchVersion "${openSearchVersion}" \
    --openSearchPort "${openSearchPort}" \
    --openSearchPrefix "${openSearchPrefix}"
fi
