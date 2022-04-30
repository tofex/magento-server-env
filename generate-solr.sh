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

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

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

      solrUrl=
      solrUser="-"
      solrPassword="-"
      if [[ "${magentoVersion}" == 1 ]]; then
        solrUrl=$(php read_config_value.php "${webPath}" "solrbridge/settings/solr_server_url" "-")
        solrUser=$(php read_config_value.php "${webPath}" "solrbridge/settings/solr_server_url_auth_username" "-")
        solrPassword=$(php read_config_value.php "${webPath}" "solrbridge/settings/solr_server_url_auth_password" "-")
      fi

      if [[ -n "${solrUrl}" ]]; then
        solrUrl=$(echo "${solrUrl}" | sed 's:/*$::')

        echo -n "Extracting Solr protocol: "
        solrProtocol=$(echo "${solrUrl}" | awk -F: '{print $1}')
        echo "${solrProtocol}"

        echo -n "Extracting Solr host: "
        urlHost=$(echo "${solrUrl}" | awk -F/ '{print $3}')
        echo "${urlHost}"

        echo -n "Extracting Solr host name: "
        solrHost=$(echo "${urlHost}" | awk -F: '{print $1}')
        echo "${solrHost}"

        echo -n "Extracting Solr port: "
        solrPort=$(echo "${urlHost}" | awk -F: '{print $2}')
        echo "${solrPort}"

        echo -n "Extracting Solr url path: "
        solrUrlPath=$(echo "${solrUrl}" | awk -F/ '{print $4}')
        echo "${solrUrlPath}"

        echo -n "Extracting Solr version: "
        if [[ -n "${solrUser}" ]] && [[ "${solrUser}" != "-" ]]; then
          solrVersion=$(curl -s -u "${solrUser}:${solrPassword}" "${solrUrl}/admin/info/system?wt=json" | grep "solr-spec-version" | sed -e 's/.*:\"\(.*\)\"\,.*/\1/')
        else
          solrVersion=$(curl -s "${solrUrl}/admin/info/system?wt=json" | grep "solr-spec-version" | sed -e 's/.*:\"\(.*\)\"\,.*/\1/')
        fi
        echo "${solrVersion}"
        if [[ -n "${solrVersion}" ]]; then
          # shellcheck disable=SC2086
          solrVersion="$(echo ${solrVersion} | cut -d. -f1).$(echo ${solrVersion} | cut -d. -f2)"
        fi

        ./init-solr.sh \
          -o "${solrHost}" \
          -v "${solrVersion}" \
          -t "${solrProtocol}" \
          -p "${solrPort}" \
          -r "${solrUrlPath}" \
          -u "${solrUser}" \
          -s "${solrPassword}"

        echo -n "Extracting all Solr cores: "
        if [[ -n "${solrUser}" ]] && [[ "${solrUser}" != "-" ]]; then
          curl -s -u "${solrUser}:${solrPassword}" "${solrUrl}/admin/cores?indexInfo=false\&wt=json" > /tmp/solr_cores.json
        else
          curl -s "${solrUrl}/admin/cores?indexInfo=false\&wt=json" > /tmp/solr_cores.json
        fi
        solrCoreList=( $(cat /tmp/solr_cores.json | jq -r '.status | keys | .[]' | sort -n) )
        echo "${solrCoreList[@]}"

        echo -n "Extracting used Solr cores: "
        usedSolrCoreList=( $(php read_config_value.php ~/www.kkl-luzern.ch/htdocs/ solrbridge/settings/solr_index) )
        echo "${usedSolrCoreList[@]}"

        for usedSolrCore in "${usedSolrCoreList[@]}"; do
          usedSolrCoreFound=0
          for solrCore in "${solrCoreList[@]}"; do
            if [[ "${usedSolrCore}" == "${solrCore}" ]]; then
              usedSolrCoreFound=1
              echo "Extracting configuration of Solr core: ${solrCore}"

              echo -n "Extracting instance directory: "
              instanceDirectory=$(cat /tmp/solr_cores.json | jq -r ".status[\"${solrCore}\"][\"instanceDir\"]")
              instanceDirectory="${instanceDirectory%/}"
              echo "${instanceDirectory}"

              echo -n "Extracting data directory: "
              dataDirectory=$(cat /tmp/solr_cores.json | jq -r ".status[\"${solrCore}\"][\"dataDir\"]")
              dataDirectory="${dataDirectory:${#instanceDirectory}}"
              dataDirectory="${dataDirectory#/}"
              dataDirectory="${dataDirectory%/}"
              echo "${dataDirectory}"

              echo -n "Extracting configuration file name: "
              configFileName=$(cat /tmp/solr_cores.json | jq -r ".status[\"${solrCore}\"][\"config\"]")
              echo "${configFileName}"

              ./init-solr-core.sh \
                -i "solr_${solrCore}" \
                -n "${solrCore}" \
                -t "${instanceDirectory}" \
                -d "${dataDirectory}" \
                -c "${configFileName}"
            fi
          done

          if [[ "${usedSolrCoreFound}" == 0 ]]; then
            echo "Could not find used Solr core with name: ${usedSolrCore}"
          fi
        done
      fi
    fi
  fi
done
