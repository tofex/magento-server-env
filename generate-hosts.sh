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

while getopts h? option; do
  case "${option}" in
    h) usage; exit 1;;
    ?) usage; exit 1;;
  esac
done

echo "Extracting Magento hosts: "
hostList=( $("${currentPath}/../ops/get-magento-hosts.sh" -q) )

echo "${hostList[@]}"

for host in "${hostList[@]}"; do
  hostName=$(echo "${host}" | cut -d: -f1)
  hostScope=$(echo "${host}" | cut -d: -f2)
  hostCode=$(echo "${host}" | cut -d: -f3)
  hostId=$(echo "${hostName}" | sed "s/[^[:alnum:]]/_/g")

  "${currentPath}/init-host.sh" \
    --systemName "system" \
    --hostId "${hostId}" \
    --virtualHost "${hostName}" \
    --scope "${hostScope}" \
    --code "${hostCode}"
done
