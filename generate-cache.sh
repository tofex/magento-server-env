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

while getopts h? option; do
  case "${option}" in
    h) usage; exit 1;;
    ?) usage; exit 1;;
  esac
done

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

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
      elif [[ -f "${webPath}/app/etc/env.php" ]]; then
        magentoVersion=2
      fi

      if [[ "${magentoVersion}" == 1 ]]; then
        cachePrefix="-"
        echo -n "Extracting Magento cache prefix: "
        cachePrefix=$(php read_config_value.php "${webPath}" global/cache/prefix)
        echo "${cachePrefix}"

        echo -n "Extracting cache type: "
        cacheBackend=$(php read_config_value.php "${webPath}" global/cache/backend)
        if [[ "${cacheBackend}" == "Cm_Cache_Backend_Redis" ]]; then
          echo "Redis"

          echo -n "Extracting Redis host: "
          redisCacheHost=$(php read_config_value.php "${webPath}"  global/cache/backend_options/server localhost)
          echo "${redisCacheHost}"

          if [[ "${redisCacheHost}" == "localhost" ]] || [[ "${redisCacheHost}" == "127.0.0.1" ]]; then
            echo -n "Extracting Redis version: "
            redisCacheVersion=$(redis-cli --version | cut -d' ' -f2)
            echo "${redisCacheVersion}"
            if [[ -n "${redisCacheVersion}" ]]; then
              # shellcheck disable=SC2086
              redisCacheVersion="$(echo ${redisCacheVersion} | cut -d. -f1).$(echo ${redisCacheVersion} | cut -d. -f2)"
            fi
          else
            echo ""
            echo "Please specify Redis version, followed by [ENTER]:"
            read -r -e redisCacheVersion
          fi

          echo -n "Extracting Redis port: "
          redisCachePort=$(php read_config_value.php "${webPath}" global/cache/backend_options/port 6379)
          echo "${redisCachePort}"

          echo -n "Extracting Redis password: "
          redisCachePassword=$(php read_config_value.php "${webPath}" global/cache/backend_options/password)
          echo "${redisCachePassword}"
          if [[ -z "${redisCachePassword}" ]]; then
            redisCachePassword="-"
          fi

          echo -n "Extracting Redis database: "
          redisCacheDatabase=$(php read_config_value.php "${webPath}" global/cache/backend_options/database 0)
          echo "${redisCacheDatabase}"

          echo -n "Extracting Redis class name: "
          redisCacheClassName=$(php read_config_value.php "${webPath}" global/cache/backend)
          echo "${redisCacheClassName}"

          ./init-redis-cache.sh \
            -o "${redisCacheHost}" \
            -v "${redisCacheVersion}" \
            -p "${redisCachePort}" \
            -s "${redisCachePassword}" \
            -d "${redisCacheDatabase}" \
            -c "${redisCacheClassName}" \
            -r "${cachePrefix}"
        else
          echo "Files"
        fi
      elif [[ "${magentoVersion}" == 2 ]]; then
        cachePrefix="-"
        echo -n "Extracting Magento cache prefix: "
        cachePrefix=$(php read_config_value.php "${webPath}" cache/frontend/default/id_prefix)
        echo "${cachePrefix}"

        echo -n "Extracting cache type: "
        cacheBackend=$(php read_config_value.php "${webPath}" cache/frontend/default/backend)
        if [[ "${cacheBackend}" == "Cm_Cache_Backend_Redis" ]]; then
          echo "Redis"

          echo -n "Extracting Redis host: "
          redisCacheHost=$(php read_config_value.php "${webPath}" cache/frontend/default/backend_options/server localhost)
          echo "${redisCacheHost}"

          if [[ "${redisCacheHost}" == "localhost" ]] || [[ "${redisCacheHost}" == "127.0.0.1" ]]; then
            echo -n "Extracting Redis version: "
            redisCacheVersion=$(redis-cli --version | cut -d' ' -f2)
            echo "${redisCacheVersion}"
            if [[ -n "${redisCacheVersion}" ]]; then
              # shellcheck disable=SC2086
              redisCacheVersion="$(echo ${redisCacheVersion} | cut -d. -f1).$(echo ${redisCacheVersion} | cut -d. -f2)"
            fi
          else
            echo ""
            echo "Please specify Redis version, followed by [ENTER]:"
            read -r -e redisCacheVersion
          fi

          echo -n "Extracting Redis port: "
          redisCachePort=$(php read_config_value.php "${webPath}" cache/frontend/default/backend_options/port 6379)
          echo "${redisCachePort}"

          echo -n "Extracting Redis password: "
          redisCachePassword=$(php read_config_value.php "${webPath}" cache/frontend/default/backend_options/password)
          echo "${redisCachePassword}"
          if [[ -z "${redisCachePassword}" ]]; then
            redisCachePassword="-"
          fi

          echo -n "Extracting Redis database: "
          redisCacheDatabase=$(php read_config_value.php "${webPath}" cache/frontend/default/backend_options/database 0)
          echo "${redisCacheDatabase}"

          echo -n "Extracting Redis class name: "
          redisCacheClassName=$(php read_config_value.php "${webPath}" cache/frontend/default/backend)
          echo "${redisCacheClassName}"

          ./init-redis-cache.sh \
            -o "${redisCacheHost}" \
            -v "${redisCacheVersion}" \
            -p "${redisCachePort}" \
            -s "${redisCachePassword}" \
            -d "${redisCacheDatabase}" \
            -c "${redisCacheClassName}" \
            -r "${cachePrefix}"
        else
          echo "Files"
        fi
      else
        ./server-cache.sh -n "${server}"
      fi
    fi
  fi
done
