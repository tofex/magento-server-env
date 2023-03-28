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

      if [[ "${magentoVersion}" == 2 ]]; then
        echo -n "Extracting search engine: "
        searchEngine=$(php "${currentPath}/read_config_value.php" "${webPath}" catalog/search/engine "elasticsearch7")
        echo "${searchEngine}"

        if [[ "${searchEngine}" == "elasticsearch" ]]; then
          echo -n "Extracting Elasticsearch host name: "
          elasticsearchHostName=$(php "${currentPath}/read_config_value.php" "${webPath}" catalog/search/elasticsearch_server_hostname)
          echo "${elasticsearchHostName}"

          echo -n "Extracting Elasticsearch port: "
          elasticsearchPort=$(php "${currentPath}/read_config_value.php" "${webPath}" catalog/search/elasticsearch_server_port)
          echo "${elasticsearchPort}"
        elif [[ "${searchEngine}" == "elasticsearch5" ]]; then
          echo -n "Extracting Elasticsearch host name: "
          elasticsearchHostName=$(php "${currentPath}/read_config_value.php" "${webPath}" catalog/search/elasticsearch5_server_hostname)
          echo "${elasticsearchHostName}"

          echo -n "Extracting Elasticsearch port: "
          elasticsearchPort=$(php "${currentPath}/read_config_value.php" "${webPath}" catalog/search/elasticsearch5_server_port)
          echo "${elasticsearchPort}"
        elif [[ "${searchEngine}" == "elasticsearch6" ]]; then
          echo -n "Extracting Elasticsearch host name: "
          elasticsearchHostName=$(php "${currentPath}/read_config_value.php" "${webPath}" catalog/search/elasticsearch6_server_hostname)
          echo "${elasticsearchHostName}"

          echo -n "Extracting Elasticsearch port: "
          elasticsearchPort=$(php "${currentPath}/read_config_value.php" "${webPath}" catalog/search/elasticsearch6_server_port)
          echo "${elasticsearchPort}"
        elif [[ "${searchEngine}" == "elasticsearch7" ]]; then
          echo -n "Extracting Elasticsearch host name: "
          elasticsearchHostName=$(php "${currentPath}/read_config_value.php" "${webPath}" catalog/search/elasticsearch7_server_hostname)
          echo "${elasticsearchHostName}"

          echo -n "Extracting Elasticsearch SSL: "
          if [[ "${elasticsearchHostName}" =~ ^https:// ]]; then
            elasticsearchHostName=$(echo "${elasticsearchHostName}" | awk -F/ '{print $3}')
            elasticsearchSsl="true"
          elif [[ "${elasticsearchHostName}" =~ ^http:// ]]; then
            elasticsearchHostName=$(echo "${elasticsearchHostName}" | awk -F/ '{print $3}')
            elasticsearchSsl="false"
          else
            elasticsearchSsl="false"
          fi
          echo "${elasticsearchSsl}"

          echo -n "Extracting Elasticsearch port: "
          elasticsearchPort=$(php "${currentPath}/read_config_value.php" "${webPath}" catalog/search/elasticsearch7_server_port)
          echo "${elasticsearchPort}"

          echo -n "Extracting Elasticsearch port: "
          elasticsearchEnableAuth=$(php "${currentPath}/read_config_value.php" "${webPath}" catalog/search/elasticsearch7_enable_auth)
          if [[ "${elasticsearchEnableAuth}" == 1 ]]; then
            elasticsearchEnableAuth="true"
          else
            elasticsearchEnableAuth="false"
          fi
          echo "${elasticsearchEnableAuth}"

          if [[ "${elasticsearchEnableAuth}" == "true" ]]; then
            echo -n "Extracting Elasticsearch user: "
            elasticsearchUser=$(php "${currentPath}/read_config_value.php" "${webPath}" catalog/search/elasticsearch7_username)
            echo "${elasticsearchUser}"

            echo -n "Extracting Elasticsearch password: "
            elasticsearchPassword=$(php "${currentPath}/read_config_value.php" "${webPath}" catalog/search/elasticsearch7_password)
            echo "${elasticsearchPassword}"
          fi

          echo -n "Extracting Elasticsearch prefix: "
          elasticsearchPrefix=$(php "${currentPath}/read_config_value.php" "${webPath}" catalog/search/elasticsearch7_index_prefix magento2)
          echo "${elasticsearchPrefix}"
        elif [[ "${searchEngine}" == "amasty_elastic" ]]; then
          echo -n "Extracting Elasticsearch host name: "
          elasticsearchHostName=$(php "${currentPath}/read_config_value.php" "${webPath}" amasty_elastic/connection/server_hostname)
          echo "${elasticsearchHostName}"

          echo -n "Extracting Elasticsearch port: "
          elasticsearchPort=$(php "${currentPath}/read_config_value.php" "${webPath}" amasty_elastic/connection/server_port)
          echo "${elasticsearchPort}"
        fi

        if [[ -n "${elasticsearchHostName}" ]]; then
          if [[ -z "${elasticsearchPort}" ]]; then
            elasticsearchPort=9200
          fi

          echo -n "Extracting Elasticsearch version: "
          if [[ "${elasticsearchSsl}" == "true" ]]; then
            elasticsearchInfoUrl="https://${elasticsearchHostName}:${elasticsearchPort}"
          else
            elasticsearchInfoUrl="http://${elasticsearchHostName}:${elasticsearchPort}"
          fi
          if [[ "${elasticsearchEnableAuth}" == "true" ]]; then
            elasticsearchInfo=$(curl -XGET -u "${elasticsearchUser}:${elasticsearchPassword}" -s "${elasticsearchInfoUrl}")
          else
            elasticsearchInfo=$(curl -XGET -s "${elasticsearchInfoUrl}")
          fi
          if [[ $(which jq 2>/dev/null | wc -l) -gt 0 ]]; then
            elasticsearchVersion=$(echo "${elasticsearchInfo}" | jq -r ".version.number // empty")
          else
            elasticsearchVersion=$(echo "${elasticsearchInfo}" | tr '\n' ' ' | sed 's/\s\+/ /g' | grep -oE '\"number\" : \"[0-9]*.[0-9]*.[0-9]*\"' | tr '\"' ' ' | awk '{print $3}')
          fi
          echo "${elasticsearchVersion}"

          if [[ "${elasticsearchEnableAuth}" == "true" ]]; then
            if [[ "${interactive}" == 1 ]]; then
              "${currentPath}/init-elasticsearch.sh" \
                --elasticsearchHost "${elasticsearchHostName}" \
                --elasticsearchSsl "${elasticsearchSsl}" \
                --elasticsearchVersion "${elasticsearchVersion}" \
                --elasticsearchPort "${elasticsearchPort}" \
                --elasticsearchPrefix "${elasticsearchPrefix}" \
                --elasticsearchUser "${elasticsearchUser}" \
                --elasticsearchPassword "${elasticsearchPassword}" \
                --interactive "${interactive}"
            else
              "${currentPath}/init-elasticsearch.sh" \
                --elasticsearchHost "${elasticsearchHostName}" \
                --elasticsearchSsl "${elasticsearchSsl}" \
                --elasticsearchVersion "${elasticsearchVersion}" \
                --elasticsearchPort "${elasticsearchPort}" \
                --elasticsearchPrefix "${elasticsearchPrefix}" \
                --elasticsearchUser "${elasticsearchUser}" \
                --elasticsearchPassword "${elasticsearchPassword}"
            fi
          else
            if [[ "${interactive}" == 1 ]]; then
              "${currentPath}/init-elasticsearch.sh" \
                --elasticsearchHost "${elasticsearchHostName}" \
                --elasticsearchSsl "${elasticsearchSsl}" \
                --elasticsearchVersion "${elasticsearchVersion}" \
                --elasticsearchPort "${elasticsearchPort}" \
                --elasticsearchPrefix "${elasticsearchPrefix}" \
                --interactive "${interactive}"
            else
              "${currentPath}/init-elasticsearch.sh" \
                --elasticsearchHost "${elasticsearchHostName}" \
                --elasticsearchSsl "${elasticsearchSsl}" \
                --elasticsearchVersion "${elasticsearchVersion}" \
                --elasticsearchPort "${elasticsearchPort}" \
                --elasticsearchPrefix "${elasticsearchPrefix}"
            fi
          fi
        fi
      else
        "${currentPath}/server-elasticsearch.sh" -n "${server}"
      fi
    fi
  fi
done
