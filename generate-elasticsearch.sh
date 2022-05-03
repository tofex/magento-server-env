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

      if [[ "${magentoVersion}" == 2 ]]; then
        echo -n "Extracting search engine: "
        searchEngine=$(php read_config_value.php "${webPath}" catalog/search/engine)
        echo "${searchEngine}"

        if [[ "${searchEngine}" == "elasticsearch" ]]; then
          echo -n "Extracting Elasticsearch host name: "
          elasticsearchHostName=$(php read_config_value.php "${webPath}" catalog/search/elasticsearch_server_hostname)
          echo "${elasticsearchHostName}"

          echo -n "Extracting Elasticsearch port: "
          elasticsearchPort=$(php read_config_value.php "${webPath}" catalog/search/elasticsearch_server_port)
          echo "${elasticsearchPort}"
        elif [[ "${searchEngine}" == "elasticsearch5" ]]; then
          echo -n "Extracting Elasticsearch host name: "
          elasticsearchHostName=$(php read_config_value.php "${webPath}" catalog/search/elasticsearch5_server_hostname)
          echo "${elasticsearchHostName}"

          echo -n "Extracting Elasticsearch port: "
          elasticsearchPort=$(php read_config_value.php "${webPath}" catalog/search/elasticsearch5_server_port)
          echo "${elasticsearchPort}"
        elif [[ "${searchEngine}" == "elasticsearch6" ]]; then
          echo -n "Extracting Elasticsearch host name: "
          elasticsearchHostName=$(php read_config_value.php "${webPath}" catalog/search/elasticsearch6_server_hostname)
          echo "${elasticsearchHostName}"

          echo -n "Extracting Elasticsearch port: "
          elasticsearchPort=$(php read_config_value.php "${webPath}" catalog/search/elasticsearch6_server_port)
          echo "${elasticsearchPort}"
        elif [[ "${searchEngine}" == "elasticsearch7" ]]; then
          echo -n "Extracting Elasticsearch host name: "
          elasticsearchHostName=$(php read_config_value.php "${webPath}" catalog/search/elasticsearch7_server_hostname)
          echo "${elasticsearchHostName}"

          echo -n "Extracting Elasticsearch port: "
          elasticsearchPort=$(php read_config_value.php "${webPath}" catalog/search/elasticsearch7_server_port)
          echo "${elasticsearchPort}"
        elif [[ "${searchEngine}" == "amasty_elastic" ]]; then
          echo -n "Extracting Elasticsearch host name: "
          elasticsearchHostName=$(php read_config_value.php "${webPath}" amasty_elastic/connection/server_hostname)
          echo "${elasticsearchHostName}"

          echo -n "Extracting Elasticsearch port: "
          elasticsearchPort=$(php read_config_value.php "${webPath}" amasty_elastic/connection/server_port)
          echo "${elasticsearchPort}"
        fi

        if [[ -n "${elasticsearchHostName}" ]]; then
          if [[ -z "${elasticsearchPort}" ]]; then
            elasticsearchPort=9200
          fi
          echo -n "Extracting Elasticsearch version: "
          elasticsearchVersion=$(curl -XGET -s "http://${elasticsearchHostName}:${elasticsearchPort}" | jq -r ".version.number // empty")
          echo "${elasticsearchVersion}"

          ./init-elasticsearch.sh \
            -o "${elasticsearchHostName}" \
            -v "${elasticsearchVersion}" \
            -p "${elasticsearchPort}"
        fi
      else
        ./server-elasticsearch.sh -n "${server}"
      fi
    fi
  fi
done
