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
    webPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${webServer}" "path")

    if [[ "${serverType}" == "local" ]]; then
      if [[ -f "${webPath}/app/etc/local.xml" ]]; then
        magentoVersion=1
      elif [[ -f "${webPath}/app/etc/env.php" ]]; then
        magentoVersion=2
      fi

      echo -n "Extracting Magento cache prefix: "
      if [[ "${magentoVersion}" == 1 ]]; then
        cachePrefix=$(php "${currentPath}/read_config_value.php" "${webPath}" global/cache/prefix)
      elif [[ "${magentoVersion}" == 2 ]]; then
        cachePrefix=$(php "${currentPath}/read_config_value.php" "${webPath}" cache/frontend/default/id_prefix)
      fi
      echo "${cachePrefix}"
      if [[ -z "${cachePrefix}" ]]; then
        cachePrefix="-"
      fi

      echo -n "Extracting cache type: "
      if [[ "${magentoVersion}" == 1 ]]; then
        cacheBackend=$(php "${currentPath}/read_config_value.php" "${webPath}" global/cache/backend)
      elif [[ "${magentoVersion}" == 2 ]]; then
        cacheBackend=$(php "${currentPath}/read_config_value.php" "${webPath}" cache/frontend/default/backend)
      fi

      if [[ "${cacheBackend}" == "Cm_Cache_Backend_Redis" ]] || [[ "${cacheBackend}" == "Magento\Framework\Cache\Backend\Redis" ]]; then
        echo "Redis"

        echo -n "Extracting Redis host: "
        if [[ "${magentoVersion}" == 1 ]]; then
          redisCacheHost=$(php "${currentPath}/read_config_value.php" "${webPath}" global/cache/backend_options/server localhost)
        elif [[ "${magentoVersion}" == 2 ]]; then
          redisCacheHost=$(php "${currentPath}/read_config_value.php" "${webPath}" cache/frontend/default/backend_options/server localhost)
        fi
        echo "${redisCacheHost}"
        if [[ -z "${redisCacheHost}" ]]; then
          redisCacheHost="-"
        fi

        echo -n "Extracting Redis port: "
        if [[ "${magentoVersion}" == 1 ]]; then
          redisCachePort=$(php "${currentPath}/read_config_value.php" "${webPath}" global/cache/backend_options/port 6379)
        elif [[ "${magentoVersion}" == 2 ]]; then
          redisCachePort=$(php "${currentPath}/read_config_value.php" "${webPath}" cache/frontend/default/backend_options/port 6379)
        fi
        echo "${redisCachePort}"
        if [[ -z "${redisCachePort}" ]]; then
          redisCachePort="-"
        fi

        redisCliScript=$(which redis-cli 2>/dev/null | cat)
        if [[ -n "${redisCliScript}" ]]; then
          echo -n "Extracting Redis version: "
          if [[ "${redisCacheHost}" == "localhost" ]] || [[ "${redisCacheHost}" == "127.0.0.1" ]]; then
            redisCacheVersion=$("${redisCliScript}" --version | cut -d' ' -f2)
          elif [[ -n "${redisCacheHost}" ]] && [[ "${redisCacheHost}" != "-" ]] && [[ -n "${redisCachePort}" ]] && [[ "${redisCachePort}" != "-" ]]; then
            redisCacheVersion=$("${redisCliScript}" -h "${redisCacheHost}" -p "${redisCachePort}" --version | cut -d' ' -f2)
          elif [[ -n "${redisCacheHost}" ]] && [[ "${redisCacheHost}" != "-" ]]; then
            redisCacheVersion=$("${redisCliScript}" -h "${redisCacheHost}" --version | cut -d' ' -f2)
          fi
          echo "${redisCacheVersion}"
          if [[ -n "${redisCacheVersion}" ]]; then
            # shellcheck disable=SC2086
            redisCacheVersion="$(echo ${redisCacheVersion} | cut -d. -f1).$(echo ${redisCacheVersion} | cut -d. -f2)"
          fi
        fi
        if [[ -z "${redisCacheVersion}" ]]; then
          redisCacheVersion="-"
        fi

        echo -n "Extracting Redis password: "
        if [[ "${magentoVersion}" == 1 ]]; then
          redisCachePassword=$(php "${currentPath}/read_config_value.php" "${webPath}" global/cache/backend_options/password)
        elif [[ "${magentoVersion}" == 2 ]]; then
          redisCachePassword=$(php "${currentPath}/read_config_value.php" "${webPath}" cache/frontend/default/backend_options/password)
        fi
        echo "${redisCachePassword}"
        if [[ -z "${redisCachePassword}" ]]; then
          redisCachePassword="-"
        fi

        echo -n "Extracting Redis database: "
        if [[ "${magentoVersion}" == 1 ]]; then
          redisCacheDatabase=$(php "${currentPath}/read_config_value.php" "${webPath}" global/cache/backend_options/database 0)
        elif [[ "${magentoVersion}" == 2 ]]; then
          redisCacheDatabase=$(php "${currentPath}/read_config_value.php" "${webPath}" cache/frontend/default/backend_options/database 0)
        fi
        echo "${redisCacheDatabase}"
        if [[ -z "${redisCacheDatabase}" ]]; then
          redisCacheDatabase="-"
        fi

        echo -n "Extracting Redis class name: "
        if [[ "${magentoVersion}" == 1 ]]; then
          redisCacheClassName=$(php "${currentPath}/read_config_value.php" "${webPath}" global/cache/backend)
        elif [[ "${magentoVersion}" == 2 ]]; then
          redisCacheClassName=$(php "${currentPath}/read_config_value.php" "${webPath}" cache/frontend/default/backend)
        fi
        echo "${redisCacheClassName}"
        if [[ -z "${redisCacheClassName}" ]]; then
          redisCacheClassName="-"
        else
          redisCacheClassName=$(echo "${redisCacheClassName}" | sed -e 's/\\/\\\\/g')
        fi

        if [[ "${interactive}" == 1 ]]; then
          "${currentPath}/add-redis-cache.sh" \
            --redisCacheHost "${redisCacheHost}" \
            --redisCacheVersion "${redisCacheVersion}" \
            --redisCachePort "${redisCachePort}" \
            --redisCachePassword "${redisCachePassword}" \
            --redisCacheDatabase "${redisCacheDatabase}" \
            --cachePrefix "${cachePrefix}" \
            --redisCacheClassName "${redisCacheClassName}" \
            --interactive
        else
          "${currentPath}/add-redis-cache.sh" \
            --redisCacheHost "${redisCacheHost}" \
            --redisCacheVersion "${redisCacheVersion}" \
            --redisCachePort "${redisCachePort}" \
            --redisCachePassword "${redisCachePassword}" \
            --redisCacheDatabase "${redisCacheDatabase}" \
            --cachePrefix "${cachePrefix}" \
            --redisCacheClassName "${redisCacheClassName}"
        fi
      else
        echo "Files"
      fi
    fi
  fi
done
