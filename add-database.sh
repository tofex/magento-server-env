#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -n  System name, default: server1

Example: ${scriptName} -n server1
EOF
}

trim()
{
  echo -n "$1" | xargs
}

systemName=

while getopts hs:? option; do
  case ${option} in
    h) usage; exit 1;;
    s) systemName=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ -f /opt/install/env.properties ]]; then
  mysqlType=$(ini-parse "/opt/install/env.properties" "no" "mysql" "type")
  mysqlVersion=$(ini-parse "/opt/install/env.properties" "no" "mysql" "version")
  mysqlHost="localhost"
  mysqlPort=$(ini-parse "/opt/install/env.properties" "no" "mysql" "port")
else
  mysqlType="mysql"
  mysqlVersion="5.7"
  mysqlHost="localhost"
  mysqlPort="3306"
fi

echo ""
echo "Please specify the database type, followed by [ENTER]:"
read -r -i "${mysqlType}" -e databaseType

echo ""
echo "Please specify the database version, followed by [ENTER]:"
read -r -i "${mysqlVersion}" -e databaseVersion

echo ""
echo "Please specify the database host, followed by [ENTER]:"
read -r -i "${mysqlHost}" -e databaseHost

echo ""
echo "Please specify the database port, followed by [ENTER]:"
read -r -i "${mysqlPort}" -e databasePort

echo ""
echo "Please specify the database user, followed by [ENTER]:"
if [[ -z "${systemName}" ]]; then
  read -r -e databaseUser
else
  read -r -i "${systemName}" -e databaseUser
fi

echo ""
echo "Please specify the database password, followed by [ENTER]:"
if [[ -z "${systemName}" ]]; then
  read -r -e databasePassword
else
  read -r -i "${systemName}" -e databasePassword
fi

echo ""
echo "Please specify the database name, followed by [ENTER]:"
if [[ -z "${systemName}" ]]; then
  read -r -e databaseName
else
  read -r -i "${systemName}" -e databaseName
fi

./init-database.sh \
  -o "${databaseHost}" \
  -t "${databaseType}" \
  -v "${databaseVersion}" \
  -p "${databasePort}" \
  -u "${databaseUser}" \
  -s "${databasePassword}" \
  -d "${databaseName}"
