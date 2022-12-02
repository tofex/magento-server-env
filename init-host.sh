#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -n  System name, default: system
  -i  Host id
  -v  Virtual host name
  -s  Scope (default, website or store)
  -c  Code
  -t  SSL terminated (yes or no), default: no
  -f  Force SSL (yes or no), default: yes
  -e  SSL certification file (optional)
  -k  SSL key file (optional)
  -r  Require IP list (optional)
  -a  Allow Urls (optional)
  -b  Basic Auth User Name (optional)
  -w  Basic Auth Password (optional)

Example: ${scriptName} -i dev_magento2_de -v dev.magento2.de -s website -c base -t no -f yes
EOF
}

trim()
{
  echo -n "$1" | xargs
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

while getopts hn:i:v:s:c:t:f:e:k:r:a:b:w:? option; do
  case "${option}" in
    h) usage; exit 1;;
    n) systemName=$(trim "$OPTARG");;
    i) hostId=$(trim "$OPTARG");;
    v) virtualHost=$(trim "$OPTARG");;
    s) scope=$(trim "$OPTARG");;
    c) code=$(trim "$OPTARG");;
    t) sslTerminated=$(trim "$OPTARG");;
    f) forceSsl=$(trim "$OPTARG");;
    e) sslCertFile=$(trim "$OPTARG");;
    k) sslKeyFile=$(trim "$OPTARG");;
    r) requireIp=$(trim "$OPTARG");;
    a) allowUrl=$(trim "$OPTARG");;
    b) basicAuthUserName=$(trim "$OPTARG");;
    w) basicAuthPassword=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

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
