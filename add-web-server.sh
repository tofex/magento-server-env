#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message

Example: ${scriptName}
EOF
}

trim()
{
  echo -n "$1" | xargs
}

while getopts hs:? option; do
  case "${option}" in
    h) usage; exit 1;;
    ?) usage; exit 1;;
  esac
done

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  touch "${currentPath}/../env.properties"
fi

if [[ -f /opt/install/env.properties ]]; then
  webServerApacheVersion=$(ini-parse "/opt/install/env.properties" "no" "apache" "version")
  if [[ -n "${webServerApacheVersion}" ]]; then
    webServerType="apache"
    webServerVersion="${webServerApacheVersion}"
    webServerHttpPort=$(ini-parse "/opt/install/env.properties" "no" "apache" "httpPort")
    webServerSslPort=$(ini-parse "/opt/install/env.properties" "no" "apache" "sslPort")
  fi
else
  webServerType="apache"
  webServerVersion="2.4"
  webServerHttpPort="80"
  webServerSslPort="443"
fi

webServerUser=$(whoami)
webServerGroup=$(id -gn "${webServerUser}")
webServerPath=$(realpath "${currentPath}/../../htdocs")

echo ""
echo "Please specify the web server server name, followed by [ENTER]:"
read -r -i "server" -e webServerServerName

echo ""
echo "Please specify the web server server user, followed by [ENTER]:"
read -r -i "local" -e webServerServerType

if [[ "${webServerServerType}" == "local" ]]; then
  webServerServerHost="localhost"
elif [[ "${webServerServerType}" == "ssh" ]]; then
  echo ""
  echo "Please specify the web server server host, followed by [ENTER]:"
  read -r -e webServerServerHost

  echo ""
  echo "Please specify the web server server user, followed by [ENTER]:"
  read -r -e webServerServerUser
fi

echo ""
echo "Please specify the web server user, followed by [ENTER]:"
read -r -i "${webServerUser}" -e webServerUser

echo ""
echo "Please specify the web server group, followed by [ENTER]:"
read -r -i "${webServerGroup}" -e webServerGroup

echo ""
echo "Please specify the web server path, followed by [ENTER]:"
read -r -i "${webServerPath}" -e webServerPath

echo ""
echo "Please specify the web server type, followed by [ENTER]:"
read -r -i "${webServerType}" -e webServerType

echo ""
echo "Please specify the web server version, followed by [ENTER]:"
read -r -i "${webServerVersion}" -e webServerVersion

echo ""
echo "Please specify the web server HTTP port, followed by [ENTER]:"
read -r -i "${webServerHttpPort}" -e webServerHttpPort

echo ""
echo "Please specify the web server SSL port, followed by [ENTER]:"
read -r -i "${webServerSslPort}" -e webServerSslPort

if [[ "${webServerServerType}" == "local" ]]; then
  "${currentPath}/init-server.sh" \
    -n "${webServerServerName}" \
    -t "${webServerServerType}" \
    -u "${webServerUser}" \
    -g "${webServerGroup}" \
    -p "${webServerPath}"
elif [[ "${webServerServerType}" == "ssh" ]]; then
  "${currentPath}/init-server.sh" \
    -n "${webServerServerName}" \
    -t "${webServerServerType}" \
    -o "${webServerServerHost}" \
    -s "${webServerServerUser}" \
    -u "${webServerUser}" \
    -g "${webServerGroup}" \
    -p "${webServerPath}"
fi

"${currentPath}/init-web-server.sh" \
  -t "${webServerType}" \
  -v "${webServerVersion}" \
  -o "${webServerServerHost}" \
  -p "${webServerHttpPort}" \
  -s "${webServerSslPort}"
