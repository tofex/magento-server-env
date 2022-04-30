#!/bin/bash -e

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

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

while getopts h? option; do
  case ${option} in
    h) usage; exit 1;;
    ?) usage; exit 1;;
  esac
done

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

for server in "${serverList[@]}"; do
  webServer=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "webServer")
  if [[ -n "${webServer}" ]]; then
    serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
    webPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webPath")
    if [[ "${serverType}" == "local" ]]; then
      if [[ -f "${webPath}/app/etc/local.xml" ]]; then
        magentoVersion=1
      else
        magentoVersion=2
      fi

      echo -n "Extracting database host: "
      if [[ "${magentoVersion}" == 1 ]]; then
        databaseHost=$(php ../read_config_value.php "${webPath}" global/resources/default_setup/connection/host localhost)
      else
        databaseHost=$(php ../read_config_value.php "${webPath}" db/connection/default/host localhost)
      fi
      echo "${databaseHost}"

      echo -n "Extracting database port: "
      if [[ "${magentoVersion}" == 1 ]]; then
        databasePort=$(php ../read_config_value.php "${webPath}" global/resources/default_setup/connection/port 3306)
      else
        databasePort=$(php ../read_config_value.php "${webPath}" db/connection/default/port 3306)
      fi
      echo "${databasePort}"

      echo -n "Extracting database user: "
      if [[ "${magentoVersion}" == 1 ]]; then
        databaseUser=$(php ../read_config_value.php "${webPath}" global/resources/default_setup/connection/username)
      else
        databaseUser=$(php ../read_config_value.php "${webPath}" db/connection/default/username)
      fi
      echo "${databaseUser}"

      echo -n "Extracting database password: "
      if [[ "${magentoVersion}" == 1 ]]; then
        databasePassword=$(php ../read_config_value.php "${webPath}" global/resources/default_setup/connection/password)
      else
        databasePassword=$(php ../read_config_value.php "${webPath}" db/connection/default/password)
      fi
      echo "${databasePassword}"

      echo -n "Extracting database name: "
      if [[ "${magentoVersion}" == 1 ]]; then
        databaseName=$(php ../read_config_value.php "${webPath}" global/resources/default_setup/connection/dbname)
      else
        databaseName=$(php ../read_config_value.php "${webPath}" db/connection/default/dbname)
      fi
      echo "${databaseName}"

      if [[ "${databaseHost}" == "localhost" ]]; then
        if [[ $(mysql -V 2>/dev/null | grep -c MariaDB) == 1 ]]; then
          databaseType="mariadb"
          databaseVersion=$(mysql -V 2>/dev/null | grep MariaDB | cut -d' ' -f6 | sed 's/\.[0-9]*-MariaDB,//')
        elif [[ $(mysql -V 2>/dev/null | grep -c "Distrib [0-9]*\.[0-9]*\.[0-9]*,") == 1 ]]; then
          databaseType="mysql"
          databaseVersion=$(mysql -V 2>/dev/null | cut -d' ' -f6 | sed 's/\.[0-9]*,//')
        fi
      fi

      ./init-database.sh \
        -o "${databaseHost}" \
        -t "${databaseType}" \
        -v "${databaseVersion}" \
        -p "${databasePort}" \
        -u "${databaseUser}" \
        -s "${databasePassword}" \
        -d "${databaseName}"
    fi
  fi
done
