#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -s  System name, default: system
  -i  Solr core id
  -n  Solr core name
  -t  Instance directory
  -d  Data directory
  -c  Config file name, default: solrconfig.xml

Example: ${scriptName} -i solr_shop_german -n shop_german -t /var/solr/data/shop_german -d /var/solr/data/shop_german/data -c solrconfig.xml
EOF
}

trim()
{
  echo -n "$1" | xargs
}

systemName=
coreId=
name=
instanceDirectory=
dataDirectory=
configFileName=

while getopts hs:i:n:t:d:c:? option; do
  case "${option}" in
    h) usage; exit 1;;
    s) systemName=$(trim "$OPTARG");;
    i) coreId=$(trim "$OPTARG");;
    n) name=$(trim "$OPTARG");;
    t) instanceDirectory=$(trim "$OPTARG");;
    d) dataDirectory=$(trim "$OPTARG");;
    c) configFileName=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${systemName}" ]]; then
  systemName="system"
fi

if [[ -z "${coreId}" ]]; then
  echo "No Solr core id specified!"
  exit 1
fi

if [[ -z "${name}" ]]; then
  echo "No Solr core name specified!"
  exit 1
fi

if [[ -z "${instanceDirectory}" ]]; then
  echo "No Solr instance directory specified!"
  exit 1
fi

if [[ -z "${dataDirectory}" ]]; then
  echo "No Solr data directory specified!"
  exit 1
fi

if [[ -z "${configFileName}" ]] || [[ "${configFileName}" == "-" ]]; then
  configFileName="solrconfig.xml"
fi

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  touch "${currentPath}/../env.properties"
fi

ini-set "${currentPath}/../env.properties" no "${systemName}" solr_core "${coreId}"
ini-set "${currentPath}/../env.properties" yes "${coreId}" name "${name}"
ini-set "${currentPath}/../env.properties" yes "${coreId}" instanceDirectory "${instanceDirectory}"
ini-set "${currentPath}/../env.properties" yes "${coreId}" dataDirectory "${dataDirectory}"
ini-set "${currentPath}/../env.properties" yes "${coreId}" configFileName "${configFileName}"
