#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -v  Magento version
  -e  Magento edition, default: community
  -m  Magento mode, default: developer
  -c  Crypt key, default: 59d6bece52542f48fd629b78e7921b39
  -u  Magento composer user, default: d661c529da2e737d5b514bf1ff2a2576
  -p  Magento composer password, default: b969ec145c55b8a8248ca8541160fe89
  -a  Admin path (optional)
  -i  Mail address for all system mails

Example: ${scriptName} -v 2.3.7 -e community -m production
EOF
}

trim()
{
  echo -n "$1" | xargs
}

versionCompare() {
  if [[ "$1" == "$2" ]]; then
    echo "0"
  elif [[ "$1" = $(echo -e "$1\n$2" | sort -V | head -n1) ]]; then
    echo "1"
  else
    echo "2"
  fi
}

magentoVersion=
magentoEdition=
magentoMode=
cryptKey=
composerUser=
composerPassword=
adminPath=
mailAddress=

while getopts hv:e:m:c:u:p:a:i:? option; do
  case "${option}" in
    h) usage; exit 1;;
    v) magentoVersion=$(trim "$OPTARG");;
    e) magentoEdition=$(trim "$OPTARG");;
    m) magentoMode=$(trim "$OPTARG");;
    c) cryptKey=$(trim "$OPTARG");;
    u) composerUser=$(trim "$OPTARG");;
    p) composerPassword=$(trim "$OPTARG");;
    a) adminPath=$(trim "$OPTARG");;
    i) mailAddress=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${magentoVersion}" ]]; then
  echo "No Magento version specified!"
  exit 1
fi

if [[ -z "${magentoEdition}" ]]; then
  magentoEdition="community"
fi

if [[ -z "${magentoMode}" ]]; then
  magentoMode="developer"
fi

if [[ "${magentoMode}" != "developer" ]] && [[ "${magentoMode}" != "production" ]]; then
  echo "Invalid Magento mode (developer or production) specified!"
  exit 1
fi

if [[ -z "${cryptKey}" ]]; then
  cryptKey="59d6bece52542f48fd629b78e7921b39"
fi

if [[ -z "${composerUser}" ]]; then
  if [[ $(versionCompare "${magentoVersion}" "1.9.4.5") == 0 ]] || [[ $(versionCompare "${magentoVersion}" "1.9.4.5") == 1 ]]; then
    composerUser="397680c997623334a6da103dbfd2d3c3"
  else
    composerUser="d661c529da2e737d5b514bf1ff2a2576"
  fi
fi

if [[ -z "${composerPassword}" ]]; then
  if [[ $(versionCompare "${magentoVersion}" "1.9.4.5") == 0 ]] || [[ $(versionCompare "${magentoVersion}" "1.9.4.5") == 1 ]]; then
    composerPassword="a9ccf6ec2e552892f8a510b4b0e1edd5"
  else
    composerPassword="b969ec145c55b8a8248ca8541160fe89"
  fi
fi

if [[ $(versionCompare "${magentoVersion}" "1.9.4.5") == 0 ]] || [[ $(versionCompare "${magentoVersion}" "1.9.4.5") == 1 ]]; then
  composerServer="https://composer.tofex.de"
else
  composerServer="https://repo.magento.com"
fi

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  touch "${currentPath}/../env.properties"
fi

ini-set "${currentPath}/../env.properties" yes install repositories "composer|${composerServer}|${composerUser}|${composerPassword}"
ini-set "${currentPath}/../env.properties" yes install magentoVersion "${magentoVersion}"
ini-set "${currentPath}/../env.properties" yes install magentoEdition "${magentoEdition}"
ini-set "${currentPath}/../env.properties" yes install magentoMode "${magentoMode}"
if [[ -n "${cryptKey}" ]] && [[ "${cryptKey}" != "-" ]]; then
  ini-set "${currentPath}/../env.properties" yes install cryptKey "${cryptKey}"
fi
if [[ -n "${adminPath}" ]] && [[ "${adminPath}" != "-" ]]; then
  ini-set "${currentPath}/../env.properties" yes install adminPath "${adminPath}"
fi
if [[ -n "${mailAddress}" ]] && [[ "${mailAddress}" != "-" ]]; then
  ini-set "${currentPath}/../env.properties" yes install mailAddress "${mailAddress}"
fi
