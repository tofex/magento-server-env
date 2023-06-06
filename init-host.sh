#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  --help               Show this message
  --systemName         System name, default: system
  --hostId             Host id
  --virtualHost        Virtual host name
  --scope              Scope (default, website or store)
  --code               Code
  --sslTerminated      SSL terminated (yes or no), default: no
  --forceSsl           Force SSL (yes or no), default: yes
  --sslCertFile        SSL certification file (optional)
  --sslKeyFile         SSL key file (optional)
  --requireIp          Require IP list (optional)
  --allowUrl           Allow Urls (optional)
  --basicAuthUserName  Basic Auth User Name (optional)
  --basicAuthPassword  Basic Auth Password (optional)

Example: ${scriptName} --hostId dev_magento2_de --virtualHost dev.magento2.de --scope website --code base --sslTerminated no --forceSsl yes
EOF
}

systemName=
hostId=
virtualHost=
scope=
code=
sslTerminated=
forceSsl=
sslCertFile=
sslKeyFile=
requireIp=
allowUrl=
basicAuthUserName=
basicAuthPassword=

source "${currentPath}/../core/prepare-parameters.sh"

if [[ -z "${systemName}" ]]; then
  systemName="system"
fi

if [[ -z "${hostId}" ]]; then
  echo "No host id specified!"
  exit 1
fi

if [[ -z "${virtualHost}" ]]; then
  echo "No virtual host specified!"
  exit 1
fi

if [[ -z "${scope}" ]]; then
  echo "No scope specified!"
  exit 1
fi

if [[ "${scope}" != "default" ]] && [[ "${scope}" != "website" ]] && [[ "${scope}" != "store" ]]; then
  echo "Invalid scope specified! Can be default, website or store."
  exit 1
fi

if [[ "${scope}" != "default" ]] && [[ -z "${code}" ]]; then
  echo "No code specified!"
  exit 1
fi

if [[ -z "${sslTerminated}" ]]; then
  sslTerminated="no"
fi

if [[ "${sslTerminated}" != "yes" ]] && [[ "${sslTerminated}" != "no" ]]; then
  echo "Invalid SSL terminated (yes or no) specified!"
  exit 1
fi

if [[ -z "${forceSsl}" ]]; then
  forceSsl="yes"
fi

if [[ "${forceSsl}" != "yes" ]] && [[ "${forceSsl}" != "no" ]]; then
  echo "Invalid force SSL (yes or no) specified!"
  exit 1
fi

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  touch "${currentPath}/../env.properties"
fi

hostList=( $(ini-parse "${currentPath}/../env.properties" "no" "system" "host") )

for hostName in "${hostList[@]}"; do
  hostScope=$(ini-parse "${currentPath}/../env.properties" "yes" "${hostName}" "scope")
  hostCode=$(ini-parse "${currentPath}/../env.properties" "yes" "${hostName}" "code")

  if [[ "${hostScope}" == "${scope}" ]] && [[ "${hostCode}" == "${code}" ]]; then
    ini-set "${currentPath}/../env.properties" yes "${hostName}" vhost "${virtualHost}"
    ini-set "${currentPath}/../env.properties" yes "${hostName}" sslTerminated "${sslTerminated}"
    ini-set "${currentPath}/../env.properties" yes "${hostName}" forceSsl "${forceSsl}"
    exit 0
  fi
done

ini-set "${currentPath}/../env.properties" no "${systemName}" host "${hostId}"
ini-set "${currentPath}/../env.properties" yes "${hostId}" vhost "${virtualHost}"
ini-set "${currentPath}/../env.properties" yes "${hostId}" scope "${scope}"
ini-set "${currentPath}/../env.properties" yes "${hostId}" code "${code}"
ini-set "${currentPath}/../env.properties" yes "${hostId}" sslTerminated "${sslTerminated}"
ini-set "${currentPath}/../env.properties" yes "${hostId}" forceSsl "${forceSsl}"
if [[ -n "${sslCertFile}" ]] && [[ "${sslCertFile}" != "-" ]]; then
  ini-set "${currentPath}/../env.properties" yes "${hostId}" sslCertFile "${sslCertFile}"
fi
if [[ -n "${sslKeyFile}" ]] && [[ "${sslKeyFile}" != "-" ]]; then
  ini-set "${currentPath}/../env.properties" yes "${hostId}" sslKeyFile "${sslKeyFile}"
fi
if [[ -n "${requireIp}" ]] && [[ "${requireIp}" != "-" ]]; then
  ini-set "${currentPath}/../env.properties" yes "${hostId}" requireIp "${requireIp}"
fi
if [[ -n "${allowUrl}" ]] && [[ "${allowUrl}" != "-" ]]; then
  ini-set "${currentPath}/../env.properties" yes "${hostId}" allowUrl "${allowUrl}"
fi
if [[ -n "${basicAuthUserName}" ]] && [[ "${basicAuthUserName}" != "-" ]]; then
  ini-set "${currentPath}/../env.properties" yes "${hostId}" basicAuthUserName "${basicAuthUserName}"
fi
if [[ -n "${basicAuthPassword}" ]] && [[ "${basicAuthPassword}" != "-" ]]; then
  ini-set "${currentPath}/../env.properties" yes "${hostId}" basicAuthPassword "${basicAuthPassword}"
fi
