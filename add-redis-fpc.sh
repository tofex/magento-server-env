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
  redisFullPageCacheVersion=$(ini-parse "/opt/install/env.properties" "no" "redis" "fullPageCacheVersion")
  redisFullPageCachePort=$(ini-parse "/opt/install/env.properties" "no" "redis" "fullPageCachePort")
else
  redisFullPageCacheVersion="6.0"
  redisFullPageCachePort="6379"
fi

echo ""
echo "Please specify the redis full page cache server name, followed by [ENTER]:"
read -r -i "server" -e redisFullPageCacheServerName

echo ""
echo "Please specify the redis full page cache server user, followed by [ENTER]:"
read -r -i "local" -e redisFullPageCacheServerType

if [[ "${redisFullPageCacheServerType}" == "local" ]]; then
  redisFullPageCacheServerHost="localhost"
elif [[ "${redisFullPageCacheServerType}" == "ssh" ]]; then
  echo ""
  echo "Please specify the redis full page cache server host, followed by [ENTER]:"
  read -r -e redisFullPageCacheServerHost

  echo ""
  echo "Please specify the redis full page cache server user, followed by [ENTER]:"
  read -r -e redisFullPageCacheServerUser
fi

echo ""
echo "Please specify the redis full page cache version, followed by [ENTER]:"
read -r -i "${redisFullPageCacheVersion}" -e redisFullPageCacheVersion

echo ""
echo "Please specify the redis full page cache port, followed by [ENTER]:"
read -r -i "${redisFullPageCachePort}" -e redisFullPageCachePort

echo ""
echo "Please specify the redis full page cache database, followed by [ENTER]:"
read -r -i "0" -e redisFullPageCacheDatabase

echo ""
echo "Please specify the redis full page cache password (empty to generate), followed by [ENTER]:"
read -r -e redisFullPageCachePassword

if [[ -z "${redisFullPageCachePassword}" ]]; then
  redisFullPageCachePassword=$(echo "${RANDOM}" | md5sum | head -c 32)
fi

echo ""
echo "Please specify the redis full page cache prefix, followed by [ENTER]:"
if [[ -z "${systemName}" ]]; then
  read -r -e redisFullPageCachePrefix
else
  read -r -i "${systemName}_" -e redisFullPageCachePrefix
fi

if [[ "${redisFullPageCacheServerType}" == "local" ]]; then
  "${currentPath}/init-server.sh" \
    -n "${redisFullPageCacheServerName}" \
    -t "${redisFullPageCacheServerType}"
elif [[ "${redisFullPageCacheServerType}" == "ssh" ]]; then
  "${currentPath}/init-server.sh" \
    -n "${redisFullPageCacheServerName}" \
    -t "${redisFullPageCacheServerType}" \
    -o "${redisFullPageCacheServerHost}" \
    -s "${redisFullPageCacheServerUser}"
fi

"${currentPath}/init-redis-fpc.sh" \
  -o "${redisFullPageCacheServerHost}" \
  -v "${redisFullPageCacheVersion}" \
  -p "${redisFullPageCachePort}" \
  -d "${redisFullPageCacheDatabase}" \
  -s "${redisFullPageCachePassword}" \
  -r "${redisFullPageCachePrefix}"
