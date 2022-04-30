#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -n  Server name, default: server
  -b  Build path
  -t  Type (composer or git), default: composer
  -c  Composer project if type: composer
  -u  Magento composer user if type: composer
  -p  Magento composer password if type: composer
  -m  Build Magento, default: yes
  -a  Addition composer projects to install, separated by comma (optional)
  -g  Git URL if type: git
  -i  Build composer (yes or no) if type: git, default: no

Example: ${scriptName} -n server -b /var/www/magento/builds -t composer -c customer/project -u 12345678 -p 12345678
EOF
}

trim()
{
  echo -n "$1" | xargs
}

serverName=
path=
type=
composerProject=
composerUser=
composerPassword=
buildMagento=
additionalComposerProjects=
gitUrl=
gitComposer=

while getopts hn:b:t:c:u:p:m:a:g:i:? option; do
  case "${option}" in
    h) usage; exit 1;;
    n) serverName=$(trim "$OPTARG");;
    b) path=$(trim "$OPTARG");;
    t) type=$(trim "$OPTARG");;
    c) composerProject=$(trim "$OPTARG");;
    u) composerUser=$(trim "$OPTARG");;
    p) composerPassword=$(trim "$OPTARG");;
    m) buildMagento=$(trim "$OPTARG");;
    a) additionalComposerProjects=$(trim "$OPTARG");;
    g) gitUrl=$(trim "$OPTARG");;
    i) gitComposer=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${serverName}" ]]; then
  serverName="server"
fi

if [[ -z "${path}" ]]; then
  echo "No build path specified!"
  exit 1
fi

if [[ -z "${type}" ]]; then
  type="composer"
fi

if [[ "${type}" != "composer" ]] && [[ "${type}" != "git" ]]; then
  echo "Invalid type (composer or git) specified!"
  exit 1
fi

if [[ "${type}" == "composer" ]]; then
  if [[ -z "${composerProject}" ]]; then
    echo "No composer project specified!"
    exit 1
  fi

  if [[ -z "${composerUser}" ]]; then
    echo "No composer user specified!"
    exit 1
  fi

  if [[ -z "${composerPassword}" ]]; then
    echo "No composer password specified!"
    exit 1
  fi

  if [[ -z "${buildMagento}" ]]; then
    buildMagento="yes"
  fi

  if [[ "${buildMagento}" != "yes" ]] && [[ "${buildMagento}" != "no" ]]; then
    echo "Invalid build Magento (yes or no) specified!"
    exit 1
  fi
fi

if [[ "${type}" == "git" ]]; then
  if [[ -z "${gitUrl}" ]]; then
    echo "No git url specified!"
    exit 1
  fi

  if [[ -z "${gitComposer}" ]]; then
    gitComposer="no"
  fi

  if [[ "${gitComposer}" != "yes" ]] && [[ "${gitComposer}" != "no" ]]; then
    echo "Invalid use git build composer (yes or no) specified!"
    exit 1
  fi
fi

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  touch "${currentPath}/../env.properties"
fi

ini-set "${currentPath}/../env.properties" yes "${serverName}" buildPath "${path}"
ini-set "${currentPath}/../env.properties" yes build server "${serverName}"

if [[ "${type}" == "composer" ]]; then
  ini-set "${currentPath}/../env.properties" yes build type composer
  ini-set "${currentPath}/../env.properties" yes build composerProject "${composerProject}"
  ini-set "${currentPath}/../env.properties" yes build repositories "composer|https://composer.tofex.de|${composerUser}|${composerPassword}"
  ini-set "${currentPath}/../env.properties" yes build magento "${buildMagento}"
  if [[ -n "${additionalComposerProjects}" ]] && [[ "${additionalComposerProjects}" != "-" ]]; then
    additionalComposerProjectList=( $(echo "${additionalComposerProjects}" | tr "," "\n") )
    for additionalComposerProject in "${additionalComposerProjectList[@]}"; do
      ini-set "${currentPath}/../env.properties" no build additionalComposerProject "${additionalComposerProject}"
    done
  fi
elif [[ "${type}" == "git" ]]; then
  ini-set "${currentPath}/../env.properties" yes build type git
  ini-set "${currentPath}/../env.properties" yes build gitUrl "${gitUrl}"
  ini-set "${currentPath}/../env.properties" yes build composer "${gitComposer}"
fi
