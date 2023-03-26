#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
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

while getopts hs:? option; do
  case "${option}" in
    h) usage; exit 1;;
    ?) usage; exit 1;;
  esac
done

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  touch "${currentPath}/../env.properties"
fi

if [[ -f /opt/install/env.properties ]]; then
  elasticsearchVersion=$(ini-parse "/opt/install/env.properties" "no" "elasticsearch" "version")
  elasticsearchPort=$(ini-parse "/opt/install/env.properties" "no" "elasticsearch" "port")
else
  elasticsearchVersion="7.9"
  elasticsearchPort="9200"
fi

echo ""
echo "Please specify the elasticsearch server name, followed by [ENTER]:"
read -r -i "server" -e elasticsearchServerName

echo ""
echo "Please specify the elasticsearch server user, followed by [ENTER]:"
read -r -i "local" -e elasticsearchServerType

if [[ "${elasticsearchServerType}" == "local" ]]; then
  elasticsearchServerHost="localhost"
elif [[ "${elasticsearchServerType}" == "remote" ]]; then
  echo ""
  echo "Please specify the elasticsearch server host, followed by [ENTER]:"
  read -r -e elasticsearchServerHost
elif [[ "${elasticsearchServerType}" == "ssh" ]]; then
  echo ""
  echo "Please specify the elasticsearch server host, followed by [ENTER]:"
  read -r -e elasticsearchServerHost

  echo ""
  echo "Please specify the elasticsearch server user, followed by [ENTER]:"
  read -r -e elasticsearchServerUser
fi

echo ""
echo "Please specify the elasticsearch version, followed by [ENTER]:"
read -r -i "${elasticsearchVersion}" -e elasticsearchVersion

echo ""
echo "Please specify the elasticsearch port, followed by [ENTER]:"
read -r -i "${elasticsearchPort}" -e elasticsearchPort

echo ""
echo "Please specify the elasticsearch prefix, followed by [ENTER]:"
read -r -i "magento" -e elasticsearchPrefix

if [[ "${elasticsearchServerType}" == "local" ]]; then
  "${currentPath}/init-server.sh" \
    --name "${elasticsearchServerName}" \
    --type "${elasticsearchServerType}"
elif [[ "${elasticsearchServerType}" == "remote" ]]; then
  "${currentPath}/init-server.sh" \
    --name "${elasticsearchServerName}" \
    --type "${elasticsearchServerType}" \
    --host "${elasticsearchServerHost}"
elif [[ "${elasticsearchServerType}" == "ssh" ]]; then
  "${currentPath}/init-server.sh" \
    --name "${elasticsearchServerName}" \
    --type "${elasticsearchServerType}" \
    --host "${elasticsearchServerHost}" \
    --sshUser "${elasticsearchServerUser}"
fi

"${currentPath}/init-elasticsearch.sh" \
  -o "${elasticsearchServerHost}" \
  -v "${elasticsearchVersion}" \
  -p "${elasticsearchPort}" \
  -x "${elasticsearchPrefix}"
