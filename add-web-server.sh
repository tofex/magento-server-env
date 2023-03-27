#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help                 Show this message
  --webServerServerType  Web server server type (local/ssh)
  --webServerServerName  Web server server name
  --webServerServerHost  Web server host (if webServerServerType == ssh)
  --webServerServerUser  Web server user (if webServerServerType == ssh)
  --webServerType        Type of web server
  --webServerVersion     Version of web server
  --webServerHttpPort    HTTP Port of web server
  --webServerSslPort     SSL Port of web server
  --webServerPath        Path of Magento installation
  --webServerUser        User of Magento installation
  --webServerGroup       Group of Magento installation
  --interactive          Interactive mode if data is missing

Example: ${scriptName}
EOF
}

webServerServerType=
webServerServerName=
webServerServerHost=
webServerServerUser=
webServerType=
webServerVersion=
webServerHttpPort=
webServerSslPort=
webServerPath=
webServerUser=
webServerGroup=
interactive=0

source "${currentPath}/../core/prepare-parameters.sh"

if [[ -z "${webServerServerType}" ]] || [[ "${webServerServerType}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the web server server type (local, remote, ssh), followed by [ENTER]:"
    read -r -i "local" -e webServerServerType
  else
    >&2 echo "No web server server type specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ -z "${webServerServerName}" ]] || [[ "${webServerServerName}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the web server server name, followed by [ENTER]:"
    read -r -i "server" -e webServerServerName
  else
    >&2 echo "No web server server name specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ "${webServerServerType}" == "remote" ]] || [[ "${webServerServerType}" == "ssh" ]]; then
  if [[ -z "${webServerServerHost}" ]] || [[ "${webServerServerHost}" == "-" ]]; then
    if [[ "${interactive}" == 1 ]]; then
      echo ""
      echo "Please specify the web server host, followed by [ENTER]:"
      read -r -e webServerServerHost
    else
      >&2 echo "No web server host specified!"
      echo ""
      usage
      exit 1
    fi
  fi
fi

if [[ "${webServerServerType}" == "ssh" ]]; then
  if [[ -z "${webServerServerUser}" ]] || [[ "${webServerServerUser}" == "-" ]]; then
    if [[ "${interactive}" == 1 ]]; then
      echo ""
      echo "Please specify the web server SSH user, followed by [ENTER]:"
      read -r -e webServerServerUser
    else
      >&2 echo "No web server SSH user specified!"
      echo ""
      usage
      exit 1
    fi
  fi
fi

if [[ -z "${webServerType}" ]] || [[ "${webServerType}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the web server type, followed by [ENTER]:"
    read -r -i "apache" -e webServerType
  else
    >&2 echo "No web server type specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ -z "${webServerVersion}" ]] || [[ "${webServerVersion}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the web server version, followed by [ENTER]:"
    read -r -i "2.4" -e webServerVersion
  else
    >&2 echo "No web server version specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ -z "${webServerHttpPort}" ]] || [[ "${webServerHttpPort}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the web server HTTP port, followed by [ENTER]:"
    read -r -i "80" -e webServerHttpPort
  else
    >&2 echo "No web server HTTP port specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ -z "${webServerSslPort}" ]] || [[ "${webServerSslPort}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the web server SSL port, followed by [ENTER]:"
    read -r -i "443" -e webServerSslPort
  else
    >&2 echo "No web server SSL port specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ -z "${webServerPath}" ]] || [[ "${webServerPath}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the web server path, followed by [ENTER]:"
    read -r -e webServerPath
  else
    >&2 echo "No web server path specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ -z "${webServerUser}" ]] || [[ "${webServerUser}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the web server user, followed by [ENTER]:"
    read -r -i "www-data" -e webServerUser
  else
    >&2 echo "No web server user specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ -z "${webServerGroup}" ]] || [[ "${webServerGroup}" == "-" ]]; then
  if [[ "${interactive}" == 1 ]]; then
    echo ""
    echo "Please specify the web server group, followed by [ENTER]:"
    read -r -i "www-data" -e webServerGroup
  else
    >&2 echo "No web server group specified!"
    echo ""
    usage
    exit 1
  fi
fi

if [[ "${webServerServerType}" == "local" ]]; then
  if [[ ! -f "${webServerPath}/app/Mage.php" ]] && [[ ! -f "${webServerPath}/app/bootstrap.php" ]]; then
    >&2 echo "Invalid Magento path specified!"
    exit 1
  fi

  if [[ ! -f "${webServerPath}/app/etc/local.xml" ]] && [[ ! -f "${webServerPath}/app/etc/env.php" ]]; then
    >&2 echo "No Magento configuration found!"
    exit 1
  fi
#elif [[ "${webServerServerType}" == "ssh" ]]; then
  # @todo
fi

if [[ "${webServerServerType}" == "local" ]]; then
  "${currentPath}/init-server.sh" \
    --name "${webServerServerName}" \
    --type "${webServerServerType}"
elif [[ "${webServerServerType}" == "remote" ]]; then
  "${currentPath}/init-server.sh" \
    --name "${webServerServerName}" \
    --type "${webServerServerType}" \
    --host "${webServerServerHost}"
elif [[ "${webServerServerType}" == "ssh" ]]; then
  "${currentPath}/init-server.sh" \
    --name "${webServerServerName}" \
    --type "${webServerServerType}" \
    --host "${webServerServerHost}" \
    --sshUser "${webServerServerUser}"
fi

"${currentPath}/init-web-server.sh" \
  --serverName "${webServerServerName}" \
  --webServerType "${webServerType}" \
  --webServerVersion "${webServerVersion}" \
  --webServerHttpPort "${webServerHttpPort}" \
  --webServerSslPort "${webServerSslPort}" \
  --webServerPath "${webServerPath}" \
  --webServerUser "${webServerUser}" \
  --webServerGroup "${webServerGroup}"
