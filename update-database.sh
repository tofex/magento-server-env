#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -i  Database id (optional)
  -t  Database type (optional)
  -v  Database version (optional)
  -o  Database host (optional)
  -p  Database port (optional)
  -u  Database user (optional)
  -s  Database password (optional)
  -d  Database name (optional)

Example: ${scriptName} -u new_user -s new_password
EOF
}

databaseId=
type=
version=
host=
port=
user=
password=
name=

while getopts hi:t:v:o:p:u:s:d:g:? option; do
  case "${option}" in
    h) usage; exit 1;;
    i) databaseId=$(trim "$OPTARG");;
    t) type=$(trim "$OPTARG");;
    v) version=$(trim "$OPTARG");;
    o) host=$(trim "$OPTARG");;
    p) port=$(trim "$OPTARG");;
    u) user=$(trim "$OPTARG");;
    s) password=$(trim "$OPTARG");;
    d) name=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

for server in "${serverList[@]}"; do
  database=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "database")
  if [[ "${database}" == "${databaseId}" ]]; then
    if [[ -n "${type}" ]]; then
      echo "--- Updating database type on server: ${server} ---"
      ini-set "${currentPath}/../env.properties" yes "${database}" type "${type}"
    fi
    if [[ -n "${version}" ]]; then
      echo "--- Updating database version on server: ${server} ---"
      ini-set "${currentPath}/../env.properties" yes "${database}" version "${version}"
    fi
    if [[ -n "${host}" ]]; then
      echo "--- Updating database host on server: ${server} ---"
      ini-set "${currentPath}/../env.properties" yes "${database}" host "${host}"
    fi
    if [[ -n "${port}" ]]; then
      echo "--- Updating database port on server: ${server} ---"
      ini-set "${currentPath}/../env.properties" yes "${database}" port "${port}"
    fi
    if [[ -n "${user}" ]]; then
      echo "--- Updating database user on server: ${server} ---"
      ini-set "${currentPath}/../env.properties" yes "${database}" user "${user}"
    fi
    if [[ -n "${password}" ]]; then
      echo "--- Updating database password on server: ${server} ---"
      ini-set "${currentPath}/../env.properties" yes "${database}" password "${password}"
    fi
    if [[ -n "${name}" ]]; then
      echo "--- Updating database name on server: ${server} ---"
      ini-set "${currentPath}/../env.properties" yes "${database}" name "${name}"
    fi
  fi
done
