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
  redisCacheVersion=$(ini-parse "/opt/install/env.properties" "no" "redis" "cacheVersion")
  redisCachePort=$(ini-parse "/opt/install/env.properties" "no" "redis" "cachePort")
else
  redisCacheVersion="6.0"
  redisCachePort="6379"
fi

echo ""
echo "Please specify the redis cache server name, followed by [ENTER]:"
read -r -i "server" -e redisCacheServerName

echo ""
echo "Please specify the redis cache server user, followed by [ENTER]:"
read -r -i "local" -e redisCacheServerType

if [[ "${redisCacheServerType}" == "local" ]]; then
  redisCacheServerHost="localhost"
elif [[ "${redisCacheServerType}" == "ssh" ]]; then
  echo ""
  echo "Please specify the redis cache server host, followed by [ENTER]:"
  read -r -e redisCacheServerHost

  echo ""
  echo "Please specify the redis cache server user, followed by [ENTER]:"
  read -r -e redisCacheServerUser
fi

echo ""
echo "Please specify the redis cache version, followed by [ENTER]:"
read -r -i "${redisCacheVersion}" -e redisCacheVersion

echo ""
echo "Please specify the redis cache port, followed by [ENTER]:"
read -r -i "${redisCachePort}" -e redisCachePort

echo ""
echo "Please specify the redis cache database, followed by [ENTER]:"
read -r -i "0" -e redisCacheDatabase

echo ""
echo "Please specify the redis cache password (empty to generate), followed by [ENTER]:"
read -r -e redisCachePassword

if [[ -z "${redisCachePassword}" ]]; then
  redisCachePassword=$(echo "${RANDOM}" | md5sum | head -c 32)
fi

echo ""
echo "Please specify the redis cache prefix, followed by [ENTER]:"
if [[ -z "${systemName}" ]]; then
  read -r -e redisCachePrefix
else
  read -r -i "${systemName}_" -e redisCachePrefix
fi

if [[ "${redisCacheServerType}" == "local" ]]; then
  "${currentPath}/init-server.sh" \
    -n "${redisCacheServerName}" \
    -t "${redisCacheServerType}"
elif [[ "${redisCacheServerType}" == "ssh" ]]; then
  "${currentPath}/init-server.sh" \
    -n "${redisCacheServerName}" \
    -t "${redisCacheServerType}" \
    -o "${redisCacheServerHost}" \
    -s "${redisCacheServerUser}"
fi

"${currentPath}/init-redis-cache.sh" \
  -o "${redisCacheServerHost}" \
  -v "${redisCacheVersion}" \
  -p "${redisCachePort}" \
  -d "${redisCacheDatabase}" \
  -s "${redisCachePassword}" \
  -r "${redisCachePrefix}"
