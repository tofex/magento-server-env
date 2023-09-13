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

      echo -n "Extracting session type: "
      if [[ "${magentoVersion}" == 1 ]]; then
        sessionBackend=$(php "${currentPath}/read_config_value.php" "${webPath}" global/session_save)
      elif [[ "${magentoVersion}" == 2 ]]; then
        sessionBackend=$(php "${currentPath}/read_config_value.php" "${webPath}" session/save)
      fi

      if [[ "${sessionBackend}" == "db" ]] || [[ "${sessionBackend}" == "redis" ]]; then
        echo "Redis"

        echo -n "Extracting Redis host: "
        if [[ "${magentoVersion}" == 1 ]]; then
          redisSessionHost=$(php "${currentPath}/read_config_value.php" "${webPath}" global/redis_session/host localhost)
        elif [[ "${magentoVersion}" == 2 ]]; then
          redisSessionHost=$(php "${currentPath}/read_config_value.php" "${webPath}" session/redis/host localhost)
        fi
        echo "${redisSessionHost}"
        if [[ -z "${redisSessionHost}" ]]; then
          redisSessionHost="-"
        fi

        echo -n "Extracting Redis port: "
        if [[ "${magentoVersion}" == 1 ]]; then
          redisSessionPort=$(php "${currentPath}/read_config_value.php" "${webPath}" global/redis_session/port 6379)
        elif [[ "${magentoVersion}" == 2 ]]; then
          redisSessionPort=$(php "${currentPath}/read_config_value.php" "${webPath}" session/redis/port 6379)
        fi
        echo "${redisSessionPort}"
        if [[ -z "${redisSessionPort}" ]]; then
          redisSessionPort="-"
        fi

        redisCliScript=$(which redis-cli 2>/dev/null | cat)
        if [[ -n "${redisCliScript}" ]]; then
          echo -n "Extracting Redis version: "
          if [[ "${redisSessionHost}" == "localhost" ]] || [[ "${redisSessionHost}" == "127.0.0.1" ]]; then
            redisSessionVersion=$("${redisCliScript}" --version | cut -d' ' -f2)
          elif [[ -n "${redisSessionHost}" ]] && [[ "${redisSessionHost}" != "-" ]] && [[ -n "${redisSessionPort}" ]] && [[ "${redisSessionPort}" != "-" ]]; then
            redisSessionVersion=$("${redisCliScript}" -h "${redisSessionHost}" -p "${redisSessionPort}" --version | cut -d' ' -f2)
          elif [[ -n "${redisSessionHost}" ]] && [[ "${redisSessionHost}" != "-" ]]; then
            redisSessionVersion=$("${redisCliScript}" -h "${redisSessionHost}" --version | cut -d' ' -f2)
          fi
          echo "${redisSessionVersion}"
          if [[ -n "${redisSessionVersion}" ]]; then
            # shellcheck disable=SC2086
            redisSessionVersion="$(echo ${redisSessionVersion} | cut -d. -f1).$(echo ${redisSessionVersion} | cut -d. -f2)"
          fi
        fi
        if [[ -z "${redisSessionVersion}" ]]; then
          redisSessionVersion="-"
        fi

        echo -n "Extracting Redis password: "
        if [[ "${magentoVersion}" == 1 ]]; then
          redisSessionPassword=$(php "${currentPath}/read_config_value.php" "${webPath}" global/redis_session/password)
        elif [[ "${magentoVersion}" == 2 ]]; then
          redisSessionPassword=$(php "${currentPath}/read_config_value.php" "${webPath}" session/redis/password)
        fi
        echo "${redisSessionPassword}"
        if [[ -z "${redisSessionPassword}" ]]; then
          redisSessionPassword="-"
        fi

        echo -n "Extracting Redis database: "
        if [[ "${magentoVersion}" == 1 ]]; then
          redisSessionDatabase=$(php "${currentPath}/read_config_value.php" "${webPath}" global/redis_session/database 0)
        elif [[ "${magentoVersion}" == 2 ]]; then
          redisSessionDatabase=$(php "${currentPath}/read_config_value.php" "${webPath}" session/redis/database 0)
        fi
        echo "${redisSessionDatabase}"
        if [[ -z "${redisSessionDatabase}" ]]; then
          redisSessionDatabase="-"
        fi

        if [[ "${interactive}" == 1 ]]; then
          "${currentPath}/add-redis-session.sh" \
            --redisSessionHost "${redisSessionHost}" \
            --redisSessionVersion "${redisSessionVersion}" \
            --redisSessionPort "${redisSessionPort}" \
            --redisSessionPassword "${redisSessionPassword}" \
            --redisSessionDatabase "${redisSessionDatabase}" \
            --interactive
        else
          "${currentPath}/add-redis-session.sh" \
            --redisSessionHost "${redisSessionHost}" \
            --redisSessionVersion "${redisSessionVersion}" \
            --redisSessionPort "${redisSessionPort}" \
            --redisSessionPassword "${redisSessionPassword}" \
            --redisSessionDatabase "${redisSessionDatabase}"
        fi
      else
        echo "Files"
      fi
    fi
  fi
done
