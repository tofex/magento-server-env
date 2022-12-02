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
  databaseType=$(ini-parse "/opt/install/env.properties" "no" "mysql" "type")
  databaseVersion=$(ini-parse "/opt/install/env.properties" "no" "mysql" "version")
  databasePort=$(ini-parse "/opt/install/env.properties" "no" "mysql" "port")
else
  databaseType="mysql"
  databaseVersion="5.7"
  databasePort="3306"
fi

echo ""
echo "Please specify the database server name, followed by [ENTER]:"
read -r -i "server" -e databaseServerName

echo ""
echo "Please specify the database server user, followed by [ENTER]:"
read -r -i "local" -e databaseServerType

if [[ "${databaseServerType}" == "local" ]]; then
  databaseServerHost="localhost"
elif [[ "${databaseServerType}" == "ssh" ]]; then
  echo ""
  echo "Please specify the database server host, followed by [ENTER]:"
  read -r -e databaseServerHost

  echo ""
  echo "Please specify the database server user, followed by [ENTER]:"
  read -r -e databaseServerUser
fi

echo ""
echo "Please specify the database type, followed by [ENTER]:"
read -r -i "${databaseType}" -e databaseType

echo ""
echo "Please specify the database version, followed by [ENTER]:"
read -r -i "${databaseVersion}" -e databaseVersion

echo ""
echo "Please specify the database port, followed by [ENTER]:"
read -r -i "${databasePort}" -e databasePort

echo ""
echo "Please specify the database user, followed by [ENTER]:"
if [[ -z "${systemName}" ]]; then
  read -r -e databaseUser
else
  read -r -i "${systemName}" -e databaseUser
fi

echo ""
echo "Please specify the database password (empty to generate), followed by [ENTER]:"
read -r -e databasePassword

if [[ -z "${databasePassword}" ]]; then
  databasePassword=$(echo "${RANDOM}" | md5sum | head -c 32)
fi

echo ""
echo "Please specify the database name, followed by [ENTER]:"
if [[ -z "${systemName}" ]]; then
  read -r -e databaseName
else
  read -r -i "${systemName}" -e databaseName
fi

if [[ "${databaseServerType}" == "local" ]]; then
  "${currentPath}/init-server.sh" \
    -n "${databaseServerName}" \
    -t "${databaseServerType}"
elif [[ "${databaseServerType}" == "ssh" ]]; then
  "${currentPath}/init-server.sh" \
    -n "${databaseServerName}" \
    -t "${databaseServerType}" \
    -o "${databaseServerHost}" \
    -s "${databaseServerUser}"
fi

"${currentPath}/init-database.sh" \
  -o "${databaseServerHost}" \
  -t "${databaseType}" \
  -v "${databaseVersion}" \
  -p "${databasePort}" \
  -u "${databaseUser}" \
  -s "${databasePassword}" \
  -d "${databaseName}"
