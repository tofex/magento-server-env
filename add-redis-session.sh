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

systemName=$(ini-parse "${currentPath}/../env.properties" "no" "system" "name")

if [[ -f /opt/install/env.properties ]]; then
  redisSessionVersion=$(ini-parse "/opt/install/env.properties" "no" "redis" "sessionVersion")
  redisSessionPort=$(ini-parse "/opt/install/env.properties" "no" "redis" "sessionPort")
else
  redisSessionVersion="6.0"
  redisSessionPort="6379"
fi

echo ""
echo "Please specify the redis session server name, followed by [ENTER]:"
read -r -i "server" -e redisSessionServerName

echo ""
echo "Please specify the redis session server user, followed by [ENTER]:"
read -r -i "local" -e redisSessionServerType

if [[ "${redisSessionServerType}" == "local" ]]; then
  redisSessionServerHost="localhost"
elif [[ "${redisSessionServerType}" == "remote" ]]; then
  echo ""
  echo "Please specify the redis session server host, followed by [ENTER]:"
  read -r -e redisSessionServerHost
elif [[ "${redisSessionServerType}" == "ssh" ]]; then
  echo ""
  echo "Please specify the redis session server host, followed by [ENTER]:"
  read -r -e redisSessionServerHost

  echo ""
  echo "Please specify the redis session server user, followed by [ENTER]:"
  read -r -e redisSessionServerUser
fi

echo ""
echo "Please specify the redis session version, followed by [ENTER]:"
read -r -i "${redisSessionVersion}" -e redisSessionVersion

echo ""
echo "Please specify the redis session port, followed by [ENTER]:"
read -r -i "${redisSessionPort}" -e redisSessionPort

echo ""
echo "Please specify the redis session database, followed by [ENTER]:"
read -r -i "0" -e redisSessionDatabase

echo ""
echo "Please specify the redis session password (empty to generate), followed by [ENTER]:"
read -r -e redisSessionPassword

if [[ -z "${redisSessionPassword}" ]]; then
  redisSessionPassword=$(echo "${RANDOM}" | md5sum | head -c 32)
fi

if [[ "${redisSessionServerType}" == "local" ]]; then
  "${currentPath}/init-server.sh" \
    --name "${redisSessionServerName}" \
    --type "${redisSessionServerType}"
elif [[ "${redisSessionServerType}" == "remote" ]]; then
  "${currentPath}/init-server.sh" \
    --name "${redisSessionServerName}" \
    --type "${redisSessionServerType}" \
    --host "${redisSessionServerHost}"
elif [[ "${redisSessionServerType}" == "ssh" ]]; then
  "${currentPath}/init-server.sh" \
    --name "${redisSessionServerName}" \
    --type "${redisSessionServerType}" \
    --host "${redisSessionServerHost}" \
    --sshUser "${redisSessionServerUser}"
fi

"${currentPath}/init-redis-session.sh" \
  -o "${redisSessionServerHost}" \
  -v "${redisSessionVersion}" \
  -p "${redisSessionPort}" \
  -d "${redisSessionDatabase}" \
  -s "${redisSessionPassword}"
