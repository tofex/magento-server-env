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

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

for server in "${serverList[@]}"; do
  serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
  webServer=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "webServer")

  if [[ -n "${webServer}" ]]; then
    webPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webPath")
    if [[ "${serverType}" == "local" ]]; then
      if [[ -f "${webPath}/app/etc/local.xml" ]]; then
        magentoVersion=1
      else
        magentoVersion=2
      fi

      echo -n "Extracting database host: "
      if [[ "${magentoVersion}" == 1 ]]; then
        databaseHost=$(php read_config_value.php "${webPath}" global/resources/default_setup/connection/host localhost)
      else
        databaseHost=$(php read_config_value.php "${webPath}" db/connection/default/host localhost)
      fi
      echo "${databaseHost}"

      echo -n "Extracting database port: "
      if [[ "${magentoVersion}" == 1 ]]; then
        databasePort=$(php read_config_value.php "${webPath}" global/resources/default_setup/connection/port 3306)
      else
        databasePort=$(php read_config_value.php "${webPath}" db/connection/default/port 3306)
      fi
      echo "${databasePort}"

      echo -n "Extracting database user: "
      if [[ "${magentoVersion}" == 1 ]]; then
        databaseUser=$(php read_config_value.php "${webPath}" global/resources/default_setup/connection/username)
      else
        databaseUser=$(php read_config_value.php "${webPath}" db/connection/default/username)
      fi
      echo "${databaseUser}"

      echo -n "Extracting database password: "
      if [[ "${magentoVersion}" == 1 ]]; then
        databasePassword=$(php read_config_value.php "${webPath}" global/resources/default_setup/connection/password)
      else
        databasePassword=$(php read_config_value.php "${webPath}" db/connection/default/password)
      fi
      echo "${databasePassword}"

      echo -n "Extracting database name: "
      if [[ "${magentoVersion}" == 1 ]]; then
        databaseName=$(php read_config_value.php "${webPath}" global/resources/default_setup/connection/dbname)
      else
        databaseName=$(php read_config_value.php "${webPath}" db/connection/default/dbname)
      fi
      echo "${databaseName}"

      export MYSQL_PWD="${databasePassword}"
      echo -n "Extracting database version: "
      databaseVersion=$(mysql -h "${databaseHost}" -P "${databasePort}" -u "${databaseUser}" -sN -e "SELECT VERSION();")
      echo "${databaseVersion}"

      echo -n "Extracting database type: "
      if [[ $(echo "${databaseVersion}" | grep MariaDB | wc -l) == 1 ]]; then
        databaseType="mariadb"
      else
        clientDatabaseVersion=$(mysql -V 2>/dev/null)
        if [[ $(echo "${clientDatabaseVersion}" | grep MariaDB | wc -l) == 1 ]]; then
          databaseType="mariadb"
        elif [[ $(echo "${clientDatabaseVersion}" | grep -c "Distrib [0-9]*\.[0-9]*\.[0-9]*,") == 1 ]]; then
          databaseType="mysql"
        fi
      fi
      echo "${databaseType}"

      databaseVersion=$(echo "${databaseVersion}" | grep -Eo '^[0-9]+\.[0-9]+\.[0-9]+')
      databaseVersion="${databaseVersion%.*}"

      if [[ "${interactive}" == 1 ]]; then
        ./add-database.sh \
          --databaseHost "${databaseHost}" \
          --databaseType "${databaseType}" \
          --databaseVersion "${databaseVersion}" \
          --databasePort "${databasePort}" \
          --databaseUser "${databaseUser}" \
          --databasePassword "${databasePassword}" \
          --databaseName "${databaseName}" \
          --interactive
      else
        ./add-database.sh \
          --databaseHost "${databaseHost}" \
          --databaseType "${databaseType}" \
          --databaseVersion "${databaseVersion}" \
          --databasePort "${databasePort}" \
          --databaseUser "${databaseUser}" \
          --databasePassword "${databasePassword}" \
          --databaseName "${databaseName}"
      fi
    fi
  fi
done
