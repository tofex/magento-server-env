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
        echo -n "Extracting session type: "
        sessionBackend=$(php read_config_value.php "${webPath}" global/session_save)
        if [[ "${sessionBackend}" == "db" ]]; then
          redisSessionHost=$(php read_config_value.php "${webPath}" global/redis_session/host localhost)
          if [[ -n "${redisSessionHost}" ]]; then
            echo "Redis"

            echo -n "Extracting Redis host: "
            redisSessionHost=$(php read_config_value.php "${webPath}" global/redis_session/host localhost)
            echo "${redisSessionHost}"

            if [[ "${redisSessionHost}" == "localhost" ]] || [[ "${redisSessionHost}" == "127.0.0.1" ]]; then
              echo -n "Extracting Redis version: "
              redisSessionVersion=$(redis-cli --version | cut -d' ' -f2)
              echo "${redisSessionVersion}"
              if [[ -n "${redisSessionVersion}" ]]; then
                # shellcheck disable=SC2086
                redisSessionVersion="$(echo ${redisSessionVersion} | cut -d. -f1).$(echo ${redisSessionVersion} | cut -d. -f2)"
              fi
            else
              echo ""
              echo "Please specify Redis version, followed by [ENTER]:"
              read -r -e redisSessionVersion
            fi

            echo -n "Extracting Redis port: "
            redisSessionPort=$(php read_config_value.php "${webPath}" global/redis_session/port 6379)
            echo "${redisSessionPort}"

            echo -n "Extracting Redis password: "
            redisSessionPassword=$(php read_config_value.php "${webPath}" global/redis_session/password)
            echo "${redisSessionPassword}"
            if [[ -z "${redisSessionPassword}" ]]; then
              redisSessionPassword="-"
            fi

            echo -n "Extracting Redis database: "
            redisSessionDatabase=$(php read_config_value.php "${webPath}" global/redis_session/database 0)
            echo "${redisSessionDatabase}"

            ./init-redis-session.sh \
              -o "${redisSessionHost}" \
              -v "${redisSessionVersion}" \
              -p "${redisSessionPort}" \
              -s "${redisSessionPassword}" \
              -d "${redisSessionDatabase}"
          else
            echo "Database"
          fi
        else
          echo "Files"
        fi
      elif [[ "${magentoVersion}" == 2 ]]; then
        echo -n "Extracting session type: "
        sessionBackend=$(php read_config_value.php "${webPath}" session/save)
        if [[ "${sessionBackend}" == "redis" ]]; then
          echo "Redis"

          echo -n "Extracting Redis host: "
          redisSessionHost=$(php read_config_value.php "${webPath}" session/redis/host localhost)
          echo "${redisSessionHost}"

          if [[ "${redisSessionHost}" == "localhost" ]] || [[ "${redisSessionHost}" == "127.0.0.1" ]]; then
            echo -n "Extracting Redis version: "
            redisSessionVersion=$(redis-cli --version | cut -d' ' -f2)
            echo "${redisSessionVersion}"
            if [[ -n "${redisSessionVersion}" ]]; then
              # shellcheck disable=SC2086
              redisSessionVersion="$(echo ${redisSessionVersion} | cut -d. -f1).$(echo ${redisSessionVersion} | cut -d. -f2)"
            fi
          else
            echo ""
            echo "Please specify Redis version, followed by [ENTER]:"
            read -r -e redisSessionVersion
          fi

          echo -n "Extracting Redis port: "
          redisSessionPort=$(php read_config_value.php "${webPath}" session/redis/port 6379)
          echo "${redisSessionPort}"

          echo -n "Extracting Redis password: "
          redisSessionPassword=$(php read_config_value.php "${webPath}" session/redis/password)
          echo "${redisSessionPassword}"
          if [[ -z "${redisSessionPassword}" ]]; then
            redisSessionPassword="-"
          fi

          echo -n "Extracting Redis database: "
          redisSessionDatabase=$(php read_config_value.php "${webPath}" session/redis/database 0)
          echo "${redisSessionDatabase}"

          ./init-redis-session.sh \
            -o "${redisSessionHost}" \
            -v "${redisSessionVersion}" \
            -p "${redisSessionPort}" \
            -s "${redisSessionPassword}" \
            -d "${redisSessionDatabase}"
        else
          echo "Files"
        fi
      else
        ./server-session.sh -n "${server}"
      fi
    fi
  fi
done
