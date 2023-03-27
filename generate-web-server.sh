#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help         Show this message
  --interactive  Interactive mode if data is missing

Example: ${scriptName} --interactive
EOF
}

interactive=0

source "${currentPath}/../core/prepare-parameters.sh"

webServerServerType="-"
webServerServerName="-"
webServerType="-"
webServerVersion="-"
webServerHttpPort="-"
webServerSslPort="-"
webServerPath="-"
webServerUser="-"
webServerGroup="-"

if [[ -f /opt/install/env.properties ]]; then
  webServerServerType="local"
  webServerServerName="server"
  webServerApacheVersion=$(ini-parse "/opt/install/env.properties" "no" "apache" "version")
  if [[ -n "${webServerApacheVersion}" ]]; then
    webServerType="apache"
    webServerVersion="${webServerApacheVersion}"
    webServerHttpPort=$(ini-parse "/opt/install/env.properties" "no" "apache" "httpPort")
    webServerSslPort=$(ini-parse "/opt/install/env.properties" "no" "apache" "sslPort")
  fi
fi

if [[ "${webServerType}" == "-" ]]; then
  echo -n "Extracting web server type: "
  if [[ $(which netstat 2>/dev/null | wc -l) -gt 0 ]]; then
    isApache2=$(sudo -n netstat -tulpn 2>/dev/null | grep ":443 " | awk '{print $7}' | uniq | grep -oPc "/apache2$" | cat)
    isNginx=$(sudo -n netstat -tulpn 2>/dev/null | grep ":443 " | awk '{print $7}' | uniq | grep -oPc "/nginx" | cat)
  elif [[ $(which ps 2>/dev/null | wc -l) -gt 0 ]]; then
    if [[ $(ps -acx | grep apache | wc -l) -gt 0 ]]; then
      isApache2=1
    else
      isApache2=0
    fi
    if [[ $(ps -acx | grep nginx | wc -l) -gt 0 ]]; then
      isNginx=1
    else
      isNginx=0
    fi
  else
    isApache2=0
    isNginx=0
  fi
  if [[ "${isApache2}" == 1 ]]; then
    echo "Apache2"
    webServerServerType="local"
    webServerServerName="server"
    webServerType="apache"
    echo -n "Checking web server script: "
    webServerScript=$(which apache2 2>/dev/null | cat)
    if [[ -z "${webServerScript}" ]]; then
      webServerScript=$(which apache2-rc 2>/dev/null | cat)
    fi
    if [[ -n "${webServerScript}" ]]; then
      echo "${webServerScript}"
      echo -n "Extracting web server version: "
      webServerVersion=$("${webServerScript}" -v | grep "Server version:" | awk '{print $3}' | sed 's/^Apache\///')
      echo "${webServerVersion}"
      echo -n "Extracting web server ports: "
      if [[ $(which netstat 2>/dev/null | wc -l) -gt 0 ]]; then
        ports=( $(sudo -n netstat -anp 2>/dev/null | grep apache | grep LISTEN | awk '{print $4}' | grep -oP "[0-9]+$") )
      else
        ports=()
      fi
      echo "${ports[@]}"
      for port in "${ports[@]}"; do
        echo -n "Checking SSL on port: ${port}: "
        isSSL=$(echo ^D | openssl s_client -connect "localhost:${port}" 2>/dev/null | grep -c "Certificate chain" | cat)
        if [[ "${isSSL}" == 1 ]]; then
          echo "yes"
          webServerSslPort="${port}"
        else
          echo "no"
          webServerHttpPort="${port}"
        fi
      done
    else
      echo "Unknown"
    fi
  elif [[ "${isNginx}" == 1 ]]; then
    echo "Nginx"
    webServerServerType="local"
    webServerServerName="server"
    webServerType="nginx"
    echo -n "Checking web server script: "
    webServerScript=$(which nginx 2>/dev/null | cat)
    if [[ -z "${webServerScript}" ]]; then
      webServerScript=$(which nginx-rc 2>/dev/null | cat)
    fi
    if [[ -n "${webServerScript}" ]]; then
      echo "${webServerScript}"
      echo -n "Extracting web server version: "
      webServerVersion=$("${webServerScript}" -v 2>&1 | awk '{print $3}' | sed 's/^nginx.*\///')
      echo "${webServerVersion}"
      echo -n "Extracting web server ports: "
      if [[ $(which netstat 2>/dev/null | wc -l) -gt 0 ]]; then
        ports=( $(sudo -n netstat -anp 2>/dev/null | grep nginx | grep LISTEN | awk '{print $4}' | grep -oP "[0-9]+$" | sort -u) )
      elif [[ -d /etc/nginx ]]; then
        ports=( $(grep -r "listen " /etc/nginx/ | cut -d' ' -f2- | sed 's/^\s*//g' | sed 's/\s\+/ /g' | sed 's/;$//g' | awk '{print $2}' | sort -u) )
      else
        ports=()
      fi
      echo "${ports[@]}"
      for port in "${ports[@]}"; do
        echo -n "Checking SSL on port: ${port}: "
        isSSL=$(echo ^D | openssl s_client -connect "localhost:${port}" 2>/dev/null | grep -c "Certificate chain" | cat)
        if [[ "${isSSL}" == 1 ]]; then
          echo "yes"
          webServerSslPort="${port}"
        else
          echo "no"
          webServerHttpPort="${port}"
        fi
      done
    else
      echo "Unknown"
    fi
  else
    echo "Unknown"
  fi
fi

if [[ "${webServerServerType}" == "local" ]]; then
  if [[ -d "${currentPath}/../../htdocs" ]]; then
    webServerPath=$(cd "${currentPath}/../../htdocs"; pwd)
  fi
  if [[ -d "${currentPath}/../../live" ]]; then
    webServerPath=$(cd "${currentPath}/../../live"; pwd)
  fi
  if [[ "${webServerPath}" != "-" ]] && [[ -d "${webServerPath}" ]]; then
    webServerUser=$(ls -ld "${webServerPath}"/ | awk '{print $3}')
    webServerGroup=$(ls -ld "${webServerPath}"/ | awk '{print $4}')
  else
    webServerUser=$(whoami)
    webServerGroup=$(id -gn "${webServerUser}")
  fi
fi

if [[ "${webServerVersion}" != "-" ]]; then
  # shellcheck disable=SC2086
  webServerVersion="$(echo ${webServerVersion} | cut -d. -f1).$(echo ${webServerVersion} | cut -d. -f2)"
fi

if [[ "${interactive}" == 1 ]]; then
  "${currentPath}/add-web-server.sh" \
    --webServerServerType "${webServerServerType}" \
    --webServerServerName "${webServerServerName}" \
    --webServerType "${webServerType}" \
    --webServerVersion "${webServerVersion}" \
    --webServerHttpPort "${webServerHttpPort}" \
    --webServerSslPort "${webServerSslPort}" \
    --webServerPath "${webServerPath}" \
    --webServerUser "${webServerUser}" \
    --webServerGroup "${webServerGroup}" \
    --interactive
else
  "${currentPath}/add-web-server.sh" \
    --webServerServerType "${webServerServerType}" \
    --webServerServerName "${webServerServerName}" \
    --webServerType "${webServerType}" \
    --webServerVersion "${webServerVersion}" \
    --webServerHttpPort "${webServerHttpPort}" \
    --webServerSslPort "${webServerSslPort}" \
    --webServerPath "${webServerPath}" \
    --webServerUser "${webServerUser}" \
    --webServerGroup "${webServerGroup}"
fi
