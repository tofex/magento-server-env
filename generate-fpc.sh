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
        fpcPrefix=

        echo -n "Extracting FPC type: "
        fpcBackend=$(php read_config_value.php "${webPath}" global/full_page_cache/backend)
        if [[ "${fpcBackend}" == "Cm_Cache_Backend_Redis" ]]; then
          echo "Redis"

          echo -n "Extracting Redis host: "
          redisFullPageCacheHost=$(php read_config_value.php "${webPath}" global/full_page_cache/backend_options/backend_options/server localhost)
          echo "${redisFullPageCacheHost}"

          if [[ "${redisFullPageCacheHost}" == "localhost" ]] || [[ "${redisFullPageCacheHost}" == "127.0.0.1" ]]; then
            echo -n "Extracting Redis version: "
            redisFullPageCacheVersion=$(redis-cli --version | cut -d' ' -f2)
            echo "${redisFullPageCacheVersion}"
            if [[ -n "${redisFullPageCacheVersion}" ]]; then
              # shellcheck disable=SC2086
              redisFullPageCacheVersion="$(echo ${redisFullPageCacheVersion} | cut -d. -f1).$(echo ${redisFullPageCacheVersion} | cut -d. -f2)"
            fi
          else
            echo ""
            echo "Please specify Redis version, followed by [ENTER]:"
            read -r -e redisFullPageCacheVersion
          fi

          echo -n "Extracting Redis port: "
          redisFullPageCachePort=$(php read_config_value.php "${webPath}" global/full_page_cache/backend_options/port 6379)
          echo "${redisFullPageCachePort}"

          echo -n "Extracting Redis password: "
          redisFullPageCachePassword=$(php read_config_value.php "${webPath}" global/full_page_cache/backend_options/password)
          echo "${redisFullPageCachePassword}"
          if [[ -z "${redisFullPageCachePassword}" ]]; then
            redisFullPageCachePassword="-"
          fi

          echo -n "Extracting Redis database: "
          redisFullPageCacheDatabase=$(php read_config_value.php "${webPath}" global/full_page_cache/backend_options/database 0)
          echo "${redisFullPageCacheDatabase}"

          echo -n "Extracting Redis class name: "
          redisFullPageCacheClassName=$(php read_config_value.php "${webPath}" global/full_page_cache/backend)
          echo "${redisFullPageCacheClassName}"

          redisFullPageCacheClassName=$(echo "${redisFullPageCacheClassName}" | sed -e 's/\\/\\\\/g')

          ./init-redis-fpc.sh \
            -o "${redisFullPageCacheHost}" \
            -v "${redisFullPageCacheVersion}" \
            -p "${redisFullPageCachePort}" \
            -s "${redisFullPageCachePassword}" \
            -d "${redisFullPageCacheDatabase}" \
            -c "${redisFullPageCacheClassName}" \
            -r "${fpcPrefix}"
        else
          echo "Files"
        fi
      elif [[ "${magentoVersion}" == 2 ]]; then
        echo -n "Extracting FPC prefix: "
        fpcPrefix=$(php read_config_value.php "${webPath}" cache/frontend/page_cache/id_prefix)
        echo "${fpcPrefix}"

        echo -n "Extracting FPC type: "
        fpcBackend=$(php read_config_value.php "${webPath}" cache/frontend/page_cache/backend)
        if [[ "${fpcBackend}" == "Cm_Cache_Backend_Redis" ]] || [[ "${fpcBackend}" == "Magento\Framework\Cache\Backend\Redis" ]]; then
          echo "Redis"

          echo -n "Extracting Redis host: "
          redisFullPageCacheHost=$(php read_config_value.php "${webPath}" cache/frontend/page_cache/backend_options/server localhost)
          echo "${redisFullPageCacheHost}"

          if [[ "${redisFullPageCacheHost}" == "localhost" ]] || [[ "${redisFullPageCacheHost}" == "127.0.0.1" ]]; then
            echo -n "Extracting Redis version: "
            redisFullPageCacheVersion=$(redis-cli --version | cut -d' ' -f2)
            echo "${redisFullPageCacheVersion}"
            if [[ -n "${redisFullPageCacheVersion}" ]]; then
              # shellcheck disable=SC2086
              redisFullPageCacheVersion="$(echo ${redisFullPageCacheVersion} | cut -d. -f1).$(echo ${redisFullPageCacheVersion} | cut -d. -f2)"
            fi
          else
            echo ""
            echo "Please specify Redis version, followed by [ENTER]:"
            read -r -e redisFullPageCacheVersion
          fi

          echo -n "Extracting Redis port: "
          redisFullPageCachePort=$(php read_config_value.php "${webPath}" cache/frontend/page_cache/backend_options/port 6379)
          echo "${redisFullPageCachePort}"

          echo -n "Extracting Redis password: "
          redisFullPageCachePassword=$(php read_config_value.php "${webPath}" cache/frontend/page_cache/backend_options/password)
          echo "${redisFullPageCachePassword}"
          if [[ -z "${redisFullPageCachePassword}" ]]; then
            redisFullPageCachePassword="-"
          fi

          echo -n "Extracting Redis database: "
          redisFullPageCacheDatabase=$(php read_config_value.php "${webPath}" cache/frontend/page_cache/backend_options/database 0)
          echo "${redisFullPageCacheDatabase}"

          echo -n "Extracting Redis class name: "
          redisFullPageCacheClassName=$(php read_config_value.php "${webPath}" cache/frontend/page_cache/backend)
          echo "${redisFullPageCacheClassName}"

          redisFullPageCacheClassName=$(echo "${redisFullPageCacheClassName}" | sed -e 's/\\/\\\\/g')

          ./init-redis-fpc.sh \
            -o "${redisFullPageCacheHost}" \
            -v "${redisFullPageCacheVersion}" \
            -p "${redisFullPageCachePort}" \
            -s "${redisFullPageCachePassword}" \
            -d "${redisFullPageCacheDatabase}" \
            -c "${redisFullPageCacheClassName}" \
            -r "${fpcPrefix}"
        else
          echo "Files"
        fi
      else
        ./server-fpc.sh -n "${server}"
      fi
    fi
  fi
done
