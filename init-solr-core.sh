#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help                   Show this message
  --systemName             System name, default: system
  --solrCoreId             Solr core id
  --solrName               Solr core name
  --solrInstanceDirectory  Instance directory
  --solrDataDirectory      Data directory
  --solrConfigFileName     Config file name, default: solrconfig.xml

Example: ${scriptName} --solrCoreId solr_shop_german --solrName shop_german --solrInstanceDirectory /var/solr/data/shop_german --dataDirectory /var/solr/data/shop_german/data --configFileName solrconfig.xml
EOF
}

systemName=
solrCoreId=
solrName=
solrInstanceDirectory=
solrDataDirectory=
solrConfigFileName=

source "${currentPath}/../core/prepare-parameters.sh"

if [[ -z "${systemName}" ]]; then
  systemName="system"
fi

if [[ -z "${solrCoreId}" ]]; then
  echo "No Solr core id specified!"
  exit 1
fi

if [[ -z "${solrName}" ]]; then
  echo "No Solr core name specified!"
  exit 1
fi

if [[ -z "${solrInstanceDirectory}" ]]; then
  echo "No Solr instance directory specified!"
  exit 1
fi

if [[ -z "${solrDataDirectory}" ]]; then
  echo "No Solr data directory specified!"
  exit 1
fi

if [[ -z "${solrConfigFileName}" ]] || [[ "${solrConfigFileName}" == "-" ]]; then
  solrConfigFileName="solrconfig.xml"
fi

cd "${currentPath}"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  touch "${currentPath}/../env.properties"
fi

ini-set "${currentPath}/../env.properties" no "${systemName}" solr_core "${solrCoreId}"
ini-set "${currentPath}/../env.properties" yes "${solrCoreId}" name "${solrName}"
ini-set "${currentPath}/../env.properties" yes "${solrCoreId}" instanceDirectory "${solrInstanceDirectory}"
ini-set "${currentPath}/../env.properties" yes "${solrCoreId}" dataDirectory "${solrDataDirectory}"
ini-set "${currentPath}/../env.properties" yes "${solrCoreId}" configFileName "${solrConfigFileName}"
