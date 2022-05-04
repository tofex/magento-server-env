#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -v  Magento version
  -e  Magento edition
  -m  Magento mode
  -c  Crypt key
  -a  Admin path
  -i  Mail address for all system mails

Example: ${scriptName} -c 59d6bece52542f48fd629b78e7921b39
EOF
}

trim()
{
  echo -n "$1" | xargs
}

magentoVersion=
magentoEdition=
magentoMode=
cryptKey=
adminPath=
mailAddress=

while getopts hv:e:m:c:a:i:? option; do
  case "${option}" in
    h) usage; exit 1;;
    v) magentoVersion=$(trim "$OPTARG");;
    e) magentoEdition=$(trim "$OPTARG");;
    m) magentoMode=$(trim "$OPTARG");;
    c) cryptKey=$(trim "$OPTARG");;
    a) adminPath=$(trim "$OPTARG");;
    i) mailAddress=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -n "${magentoMode}" ]] && [[ "${magentoMode}" != "-" ]] && [[ "${magentoMode}" != "developer" ]] && [[ "${magentoMode}" != "production" ]]; then
  echo "Invalid Magento mode (developer or production) specified!"
  exit 1
fi

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  echo "No environment specified!"
  exit 1
fi

if [[ -n "${magentoVersion}" ]] && [[ "${magentoVersion}" != "-" ]]; then
  ini-set "${currentPath}/../env.properties" yes install magentoVersion "${magentoVersion}"
fi
if [[ -n "${magentoEdition}" ]] && [[ "${magentoEdition}" != "-" ]]; then
  ini-set "${currentPath}/../env.properties" yes install magentoEdition "${magentoEdition}"
fi
if [[ -n "${magentoMode}" ]] && [[ "${magentoMode}" != "-" ]]; then
  ini-set "${currentPath}/../env.properties" yes install magentoMode "${magentoMode}"
fi
if [[ -n "${cryptKey}" ]] && [[ "${cryptKey}" != "-" ]]; then
  ini-set "${currentPath}/../env.properties" yes install cryptKey "${cryptKey}"
fi
if [[ -n "${adminPath}" ]] && [[ "${adminPath}" != "-" ]]; then
  ini-set "${currentPath}/../env.properties" yes install adminPath "${adminPath}"
fi
if [[ -n "${mailAddress}" ]] && [[ "${mailAddress}" != "-" ]]; then
  ini-set "${currentPath}/../env.properties" yes install mailAddress "${mailAddress}"
fi
