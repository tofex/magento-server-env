#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help                     Show this message
  --elasticsearchServerName  Name of server to use (optional)
  --elasticsearchServerType  Type of server (local, remote, ssh)
  --elasticsearchServerUser  User if server type is SSH
  --elasticsearchHost        Elasticsearch host, default: localhost
  --elasticsearchSsl         Elasticsearch SSL (true/false), default: false
  --elasticsearchVersion     Elasticsearch version
  --elasticsearchPort        Elasticsearch port, default: 9200
  --elasticsearchPrefix      Elasticsearch prefix
  --elasticsearchUser        User name if behind basic auth
  --elasticsearchPassword    Password if behind basic auth

Example: ${scriptName}
EOF
}

elasticsearchServerName=
elasticsearchServerType=
elasticsearchServerUser=
elasticsearchHost=
elasticsearchSsl=
elasticsearchVersion=
elasticsearchPort=
elasticsearchPrefix=
interactive=0

source "${currentPath}/../core/prepare-parameters.sh"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  touch "${currentPath}/../env.properties"
fi

if [[ -z "${elasticsearchVersion}" ]] || [[ "${elasticsearchVersion}" == "-" ]]; then
  if [[ -f /opt/install/env.properties ]]; then
    elasticsearchVersion=$(ini-parse "/opt/install/env.properties" "no" "elasticsearch" "version")
  else
    elasticsearchVersion="7.9"
  fi
fi

if [[ -z "${elasticsearchPort}" ]] || [[ "${elasticsearchPort}" == "-" ]]; then
  if [[ -f /opt/install/env.properties ]]; then
    elasticsearchPort=$(ini-parse "/opt/install/env.properties" "no" "elasticsearch" "port")
  else
    elasticsearchPort="9200"
  fi
fi

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

if { [[ -z "${elasticsearchServerName}" ]] || [[ "${elasticsearchServerName}" == "-" ]]; } && [[ -n "${elasticsearchHost}" ]]; then
  for server in "${serverList[@]}"; do
    serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")

    if { [[ "${elasticsearchHost}" == "localhost" ]] || [[ "${elasticsearchHost}" == "127.0.0.1" ]]; } && [[ "${serverType}" == "local" ]]; then
      elasticsearchServerName="${server}"
    elif [[ "${serverType}" != "local" ]]; then
      serverHost=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "host")
      if [[ "${serverHost}" == "${elasticsearchHost}" ]]; then
        elasticsearchServerName="${server}"
      fi
    fi
  done
fi

if [[ -z "${elasticsearchServerName}" ]] || [[ "${elasticsearchServerName}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the Elasticsearch server name, followed by [ENTER]:"
    read -r -i "${elasticsearchHost}" -e elasticsearchServerName
  else
    >&2 echo "No Elasticsearch server name specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ -z "${elasticsearchServerType}" ]] || [[ "${elasticsearchServerType}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the Elasticsearch server user, followed by [ENTER]:"
    read -r -i "local" -e elasticsearchServerType
  else
    >&2 echo "No Elasticsearch server type specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ "${elasticsearchServerType}" == "local" ]]; then
  elasticsearchHost="localhost"
elif [[ "${elasticsearchServerType}" == "remote" ]]; then
  echo ""
  echo "Please specify the elasticsearch server host, followed by [ENTER]:"
  read -r -e elasticsearchHost
elif [[ "${elasticsearchServerType}" == "ssh" ]]; then
  echo ""
  echo "Please specify the elasticsearch server host, followed by [ENTER]:"
  read -r -e elasticsearchHost

  echo ""
  echo "Please specify the elasticsearch server user, followed by [ENTER]:"
  read -r -e elasticsearchServerUser
fi

if [[ -z "${elasticsearchSsl}" ]] || [[ "${elasticsearchSsl}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Is Elasticsearch using SSL?"
    select yesNo in "Yes" "No"; do
      case "${yesNo}" in
        Yes ) elasticsearchSsl="true"; break;;
        No ) elasticsearchSsl="false"; break;;
      esac
    done
  else
    >&2 echo "No Elasticsearch version specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ -z "${elasticsearchVersion}" ]] || [[ "${elasticsearchVersion}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the Elasticsearch version, followed by [ENTER]:"
    read -r -i "${elasticsearchVersion}" -e elasticsearchVersion
  else
    >&2 echo "No Elasticsearch version specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ -z "${elasticsearchPort}" ]] || [[ "${elasticsearchPort}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the Elasticsearch port, followed by [ENTER]:"
    read -r -i "${elasticsearchPort}" -e elasticsearchPort
  else
    >&2 echo "No Elasticsearch port specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ -z "${elasticsearchPrefix}" ]] || [[ "${elasticsearchPrefix}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the elasticsearch prefix, followed by [ENTER]:"
    read -r -i "magento" -e elasticsearchPrefix
  else
    >&2 echo "No Elasticsearch prefix specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ "${interactive}" == 1 ]]; then
  useBasicAuth=0
  echo ""
  echo "Is Elasticsearch behind basic auth?"
  select yesNo in "Yes" "No"; do
    case "${yesNo}" in
      Yes ) useBasicAuth=1; break;;
      No ) break;;
    esac
  done

  if [[ "${useBasicAuth}" == 1 ]]; then
    echo ""
    echo "Please specify the Elasticsearch user, followed by [ENTER]:"
    read -r -e elasticsearchUser

    echo ""
    echo "Please specify the Elasticsearch password, followed by [ENTER]:"
    read -r -e elasticsearchPassword
  else
    elasticsearchUser=
    elasticsearchPassword=
  fi
fi

if [[ "${elasticsearchServerType}" == "local" ]]; then
  "${currentPath}/init-server.sh" \
    --name "${elasticsearchServerName}" \
    --type "${elasticsearchServerType}"
elif [[ "${elasticsearchServerType}" == "remote" ]]; then
  "${currentPath}/init-server.sh" \
    --name "${elasticsearchServerName}" \
    --type "${elasticsearchServerType}" \
    --host "${elasticsearchHost}"
elif [[ "${elasticsearchServerType}" == "ssh" ]]; then
  "${currentPath}/init-server.sh" \
    --name "${elasticsearchServerName}" \
    --type "${elasticsearchServerType}" \
    --host "${elasticsearchHost}" \
    --sshUser "${elasticsearchServerUser}"
fi

if [[ -n "${elasticsearchUser}" ]] && [[ -n "${elasticsearchPassword}" ]]; then
  "${currentPath}/init-elasticsearch.sh" \
    --elasticsearchHost "${elasticsearchHost}" \
    --elasticsearchSsl "${elasticsearchSsl}" \
    --elasticsearchVersion "${elasticsearchVersion}" \
    --elasticsearchPort "${elasticsearchPort}" \
    --elasticsearchPrefix "${elasticsearchPrefix}" \
    --elasticsearchUser "${elasticsearchUser}" \
    --elasticsearchPassword "${elasticsearchPassword}"
else
  "${currentPath}/init-elasticsearch.sh" \
    --elasticsearchHost "${elasticsearchHost}" \
    --elasticsearchSsl "${elasticsearchSsl}" \
    --elasticsearchVersion "${elasticsearchVersion}" \
    --elasticsearchPort "${elasticsearchPort}" \
    --elasticsearchPrefix "${elasticsearchPrefix}"
fi
