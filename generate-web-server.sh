#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -n  Server name, default: server
  -t  Server type (local or ssh)
  -c  Check for valid Magento installation

Example: ${scriptName} -n server1 -t local -c
EOF
}

trim()
{
  echo -n "$1" | xargs
}

serverName=
serverType=
checkMagento=0

while getopts hn:t:c? option; do
  case "${option}" in
    h) usage; exit 1;;
    n) serverName=$(trim "$OPTARG");;
    t) serverType=$(trim "$OPTARG");;
    c) checkMagento=1;;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${serverName}" ]]; then
  serverName="server"
fi

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

webPath=$(ini-parse "${currentPath}/../env.properties" yes "${serverName}" webPath)

if [[ "${checkMagento}" == 1 ]]; then
  if [[ "${serverType}" == "local" ]]; then
    if [[ ! -f "${webPath}/app/Mage.php" ]] && [[ ! -f "${webPath}/app/bootstrap.php" ]]; then
      echo "Invalid Magento path specified!"
      exit 1
    fi

    if [[ ! -f "${webPath}/app/etc/local.xml" ]] && [[ ! -f "${webPath}/app/etc/env.php" ]]; then
      echo "No Magento configuration found!"
      exit 1
    fi
  #else
    #@todo: SSH handling
  fi
else
  if [[ "${serverType}" == "local" ]]; then
    if [[ ! -f "${webPath}/bin/magento" ]]; then
      echo "Invalid Magento path specified!"
      exit 1
    fi

    if [[ ! -f "${webPath}/app/etc/env.php" ]] && [[ ! -f "${webPath}/app/etc/config.php" ]]; then
      echo "No Magento configuration found!"
      exit 1
    fi
  #else
    #@todo: SSH handling
  fi
fi

if [[ "${serverType}" == "local" ]]; then
  host="localhost"
  httpPort="-"
  sslPort="-"
  echo -n "Extracting web server type: "
  isApache2=$(sudo -n netstat -tulpn 2>/dev/null | grep ":443 " | awk '{print $7}' | grep -oPc "/apache2$" | cat)
  if [[ "${isApache2}" == 1 ]]; then
    echo "Apache2"
    type="apache"
    echo -n "Checking web server script: "
    webServerScript=$(which apache2)
    echo "${webServerScript}"
    if [[ -n "${webServerScript}" ]]; then
      echo -n "Extracting web server version: "
      webServerVersion=$("${webServerScript}" -v | grep "Server version:" | awk '{print $3}' | sed 's/^Apache\///')
      echo "${webServerVersion}"
      echo -n "Extracting web server ports: "
      ports=( $(sudo -n netstat -anp 2>/dev/null | grep apache | awk '{print $4}' | grep -oP "[0-9]+$") )
      echo "${ports[@]}"
      for port in "${ports[@]}"; do
        echo -n "Checking SSL on port: ${port}: "
        isSSL=$(echo ^D | openssl s_client -connect "localhost:${port}" 2>/dev/null | grep -c "Certificate chain" | cat)
        if [[ "${isSSL}" == 1 ]]; then
          echo "yes"
          sslPort="${port}"
        else
          echo "no"
          httpPort="${port}"
        fi
      done
    fi
  fi
  if [[ -n "${webServerVersion}" ]]; then
    # shellcheck disable=SC2086
    version="$(echo ${webServerVersion} | cut -d. -f1).$(echo ${webServerVersion} | cut -d. -f2)"
  fi
#else
  #@todo: SSH handling
fi

if [[ -z "${type}" ]]; then
  echo ""
  echo "Please specify the web server type (apache or nginx), followed by [ENTER]:"
  read -r -i "apache" -e type
fi

if [[ -z "${version}" ]]; then
  echo ""
  echo "Please specify the web server version, followed by [ENTER]:"
  if [[ "${type}" == "apache" ]]; then
    read -r -i "2.4" -e version
  else
    read -r -e version
  fi
fi

if [[ -z "${httpPort}" ]] || [[ "${httpPort}" == "-" ]]; then
  echo ""
  echo "Please specify the web server port, followed by [ENTER]:"
  read -r -i "80" -e httpPort
fi

if [[ -z "${sslPort}" ]] || [[ "${sslPort}" == "-" ]]; then
  echo ""
  echo "Please specify the web server port, followed by [ENTER]:"
  read -r -i "443" -e sslPort
fi

./init-web-server.sh \
  -o "${host}" \
  -t "${type}" \
  -v "${version}" \
  -p "${httpPort}" \
  -s "${sslPort}"
