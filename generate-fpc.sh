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

      echo -n "Extracting FPC prefix: "
      if [[ "${magentoVersion}" == 1 ]]; then
        fpcPrefix=
      elif [[ "${magentoVersion}" == 2 ]]; then
        fpcPrefix=$(php "${currentPath}/read_config_value.php" "${webPath}" cache/frontend/page_cache/id_prefix)
      fi
      echo "${fpcPrefix}"
      if [[ -z "${fpcPrefix}" ]]; then
        fpcPrefix="-"
      fi

      echo -n "Extracting FPC type: "
      if [[ "${magentoVersion}" == 1 ]]; then
        fpcBackend=$(php "${currentPath}/read_config_value.php" "${webPath}" global/full_page_cache/backend)
      elif [[ "${magentoVersion}" == 2 ]]; then
        fpcBackend=$(php "${currentPath}/read_config_value.php" "${webPath}" cache/frontend/page_cache/backend)
      fi

      if [[ "${fpcBackend}" == "Cm_Cache_Backend_Redis" ]] || [[ "${fpcBackend}" == "Magento\Framework\Cache\Backend\Redis" ]]; then
        echo "Redis"

        echo -n "Extracting Redis host: "
        if [[ "${magentoVersion}" == 1 ]]; then
          redisFullPageCacheHost=$(php "${currentPath}/read_config_value.php" "${webPath}" global/full_page_cache/backend_options/backend_options/server localhost)
        elif [[ "${magentoVersion}" == 2 ]]; then
          redisFullPageCacheHost=$(php "${currentPath}/read_config_value.php" "${webPath}" cache/frontend/page_cache/backend_options/server localhost)
        fi
        echo "${redisFullPageCacheHost}"
        if [[ -z "${redisFullPageCacheHost}" ]]; then
          redisFullPageCacheHost="-"
        fi

        echo -n "Extracting Redis port: "
        if [[ "${magentoVersion}" == 1 ]]; then
          redisFullPageCachePort=$(php "${currentPath}/read_config_value.php" "${webPath}" global/full_page_cache/backend_options/port 6379)
        elif [[ "${magentoVersion}" == 2 ]]; then
          redisFullPageCachePort=$(php "${currentPath}/read_config_value.php" "${webPath}" cache/frontend/page_cache/backend_options/port 6379)
        fi
        echo "${redisFullPageCachePort}"
        if [[ -z "${redisFullPageCachePort}" ]]; then
          redisFullPageCachePort="-"
        fi

        redisCliScript=$(which redis-cli 2>/dev/null | cat)
        if [[ -n "${redisCliScript}" ]]; then
          echo -n "Extracting Redis version: "
          if [[ "${redisFullPageCacheHost}" == "localhost" ]] || [[ "${redisFullPageCacheHost}" == "127.0.0.1" ]]; then
            redisFullPageCacheVersion=$("${redisCliScript}" --version | cut -d' ' -f2)
          elif [[ -n "${redisFullPageCacheHost}" ]] && [[ "${redisFullPageCacheHost}" != "-" ]] && [[ -n "${redisFullPageCachePort}" ]] && [[ "${redisFullPageCachePort}" != "-" ]]; then
            redisFullPageCacheVersion=$("${redisCliScript}" -h "${redisFullPageCacheHost}" -p "${redisFullPageCachePort}" --version | cut -d' ' -f2)
          elif [[ -n "${redisFullPageCacheHost}" ]] && [[ "${redisFullPageCacheHost}" != "-" ]]; then
            redisFullPageCacheVersion=$("${redisCliScript}" -h "${redisFullPageCacheHost}" --version | cut -d' ' -f2)
          fi
          echo "${redisFullPageCacheVersion}"
          if [[ -n "${redisFullPageCacheVersion}" ]]; then
            # shellcheck disable=SC2086
            redisFullPageCacheVersion="$(echo ${redisFullPageCacheVersion} | cut -d. -f1).$(echo ${redisFullPageCacheVersion} | cut -d. -f2)"
          fi
        fi
        if [[ -z "${redisFullPageCacheVersion}" ]]; then
          redisFullPageCacheVersion="-"
        fi

        echo -n "Extracting Redis password: "
        if [[ "${magentoVersion}" == 1 ]]; then
          redisFullPageCachePassword=$(php "${currentPath}/read_config_value.php" "${webPath}" global/full_page_cache/backend_options/password)
        elif [[ "${magentoVersion}" == 2 ]]; then
          redisFullPageCachePassword=$(php "${currentPath}/read_config_value.php" "${webPath}" cache/frontend/page_cache/backend_options/password)
        fi
        echo "${redisFullPageCachePassword}"
        if [[ -z "${redisFullPageCachePassword}" ]]; then
          redisFullPageCachePassword="-"
        fi

        echo -n "Extracting Redis database: "
          redisFullPageCacheDatabase=$(php "${currentPath}/read_config_value.php" "${webPath}" global/full_page_cache/backend_options/database 0)
          redisFullPageCacheDatabase=$(php "${currentPath}/read_config_value.php" "${webPath}" cache/frontend/page_cache/backend_options/database 0)
        echo "${redisFullPageCacheDatabase}"

        echo -n "Extracting Redis class name: "
          redisFullPageCacheClassName=$(php "${currentPath}/read_config_value.php" "${webPath}" global/full_page_cache/backend)
          redisFullPageCacheClassName=$(php "${currentPath}/read_config_value.php" "${webPath}" cache/frontend/page_cache/backend)
        echo "${redisFullPageCacheClassName}"
        if [[ -z "${redisFullPageCacheClassName}" ]]; then
          redisFullPageCacheClassName="-"
        else
          redisFullPageCacheClassName=$(echo "${redisFullPageCacheClassName}" | sed -e 's/\\/\\\\/g')
        fi

        if [[ "${interactive}" == 1 ]]; then
          "${currentPath}/add-redis-fpc.sh" \
            --redisFullPageCacheHost "${redisFullPageCacheHost}" \
            --redisFullPageCacheVersion "${redisFullPageCacheVersion}" \
            --redisFullPageCachePort "${redisFullPageCachePort}" \
            --redisFullPageCachePassword "${redisFullPageCachePassword}" \
            --redisFullPageCacheDatabase "${redisFullPageCacheDatabase}" \
            --redisFullPageCacheClassName "${redisFullPageCacheClassName}" \
            --redisFullPageCachePrefix "${fpcPrefix}" \
            --interactive
        else
          "${currentPath}/add-redis-fpc.sh" \
            --redisFullPageCacheHost "${redisFullPageCacheHost}" \
            --redisFullPageCacheVersion "${redisFullPageCacheVersion}" \
            --redisFullPageCachePort "${redisFullPageCachePort}" \
            --redisFullPageCachePassword "${redisFullPageCachePassword}" \
            --redisFullPageCacheDatabase "${redisFullPageCacheDatabase}" \
            --redisFullPageCacheClassName "${redisFullPageCacheClassName}" \
            --redisFullPageCachePrefix "${fpcPrefix}"
        fi
      else
        echo "Files"
      fi
    fi
  fi
done
