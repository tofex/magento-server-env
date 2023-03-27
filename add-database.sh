#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help                Show this message
  --databaseServerType  Type of server (local, remote, ssh)
  --databaseServerName  Name of server to use (optional)
  --databaseServerUser  User if server type is SSH
  --dabaseHost          Database host, default: localhost
  --databaseType        Database type
  --databaseVersion     Database version
  --databasePort        Database port, default: 3306
  --databaseUser        Database user
  --databasePassword    Database password
  --databaseName        Database name

Example: ${scriptName}
EOF
}

databaseServerType=
databaseServerName=
databaseServerUser=
databaseHost=
databaseType=
databaseVersion=
databasePort=
databaseUser=
databasePassword=
databaseName=
interactive=0

source "${currentPath}/../core/prepare-parameters.sh"

if [[ -f /opt/install/env.properties ]]; then
  databaseType=$(ini-parse "/opt/install/env.properties" "no" "mysql" "type")
  databaseVersion=$(ini-parse "/opt/install/env.properties" "no" "mysql" "version")
  databasePort=$(ini-parse "/opt/install/env.properties" "no" "mysql" "port")

  if [[ -z "${databaseServerType}" ]] && [[ -n "${databaseType}" ]]; then
    databaseServerType="local"
  fi
else
  databaseType="mysql"
  databaseVersion="5.7"
  databasePort="3306"
fi

systemName=
if [[ -f "${currentPath}/../env.properties" ]]; then
  systemName=$(ini-parse "${currentPath}/../env.properties" "no" "system" "name")
fi

if [[ -z "${databaseServerType}" ]] || [[ "${databaseServerType}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the database server type (local, remote, ssh), followed by [ENTER]:"
    read -r -i "local" -e databaseServerType
  else
    >&2 echo "No database server type specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ -z "${databaseServerName}" ]] || [[ "${databaseServerName}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the database server name, followed by [ENTER]:"
    read -r -i "server" -e databaseServerName
  else
    >&2 echo "No database server server name specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ "${databaseServerType}" == "local" ]]; then
  if [[ -z "${databaseHost}" ]] || [[ "${databaseHost}" == "-" ]]; then
    databaseHost="localhost"
  fi
elif [[ "${databaseServerType}" == "remote" ]]; then
  if [[ -z "${databaseHost}" ]] || [[ "${databaseHost}" == "-" ]]; then
    echo ""
    echo "Please specify the database host, followed by [ENTER]:"
    read -r -e databaseHost
  fi
elif [[ "${databaseServerType}" == "ssh" ]]; then
  if [[ -z "${databaseHost}" ]] || [[ "${databaseHost}" == "-" ]]; then
    echo ""
    echo "Please specify the database host, followed by [ENTER]:"
    read -r -e databaseHost
  fi

  if [[ -z "${databaseServerUser}" ]] || [[ "${databaseServerUser}" == "-" ]]; then
    echo ""
    echo "Please specify the database server user, followed by [ENTER]:"
    read -r -e databaseServerUser
  fi
fi

if [[ -z "${databaseType}" ]] || [[ "${databaseType}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the database type, followed by [ENTER]:"
    read -r -i "${databaseType}" -e databaseType
  else
    >&2 echo "No database type specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ -z "${databaseVersion}" ]] || [[ "${databaseVersion}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the database version, followed by [ENTER]:"
    read -r -i "${databaseVersion}" -e databaseVersion
  else
    >&2 echo "No database version specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ -z "${databasePort}" ]] || [[ "${databasePort}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the database port, followed by [ENTER]:"
    read -r -i "${databasePort}" -e databasePort
  else
    >&2 echo "No database port specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ -z "${databaseUser}" ]] || [[ "${databaseUser}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the database user, followed by [ENTER]:"
    if [[ -z "${systemName}" ]]; then
      read -r -e databaseUser
    else
      read -r -i "${systemName}" -e databaseUser
    fi
  else
    >&2 echo "No database user specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ -z "${databasePassword}" ]] || [[ "${databasePassword}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the database password (empty to generate), followed by [ENTER]:"
    read -r -e databasePassword
  else
    databasePassword=$(echo "${RANDOM}" | md5sum | head -c 32)
  fi
fi

if [[ -z "${databaseName}" ]] || [[ "${databaseName}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the database name, followed by [ENTER]:"
    if [[ -z "${systemName}" ]]; then
      read -r -e databaseName
    else
      read -r -i "${systemName}" -e databaseName
    fi
  else
    >&2 echo "No database name specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ "${databaseServerType}" == "local" ]]; then
  "${currentPath}/init-server.sh" \
    --name "${databaseServerName}" \
    --type "${databaseServerType}"
elif [[ "${databaseServerType}" == "remote" ]]; then
  "${currentPath}/init-server.sh" \
    --name "${databaseServerName}" \
    --type "${databaseServerType}" \
    --host "${databaseHost}"
elif [[ "${databaseServerType}" == "ssh" ]]; then
  "${currentPath}/init-server.sh" \
    --name "${databaseServerName}" \
    --type "${databaseServerType}" \
    --host "${databaseHost}" \
    --sshUser "${databaseServerUser}"
fi

"${currentPath}/init-database.sh" \
  --databaseServerName "${databaseServerName}" \
  --databaseHost "${databaseHost}" \
  --databaseType "${databaseType}" \
  --databaseVersion "${databaseVersion}" \
  --databasePort "${databasePort}" \
  --databaseUser "${databaseUser}" \
  --databasePassword "${databasePassword}" \
  --databaseName "${databaseName}"
