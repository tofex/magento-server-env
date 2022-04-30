#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -n  Server name, default: server1

Example: ${scriptName} -n server1
EOF
}

trim()
{
  echo -n "$1" | xargs
}

serverName=

while getopts hn:? option; do
  case "${option}" in
    h) usage; exit 1;;
    n) serverName=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f ../env.properties ]]; then
  touch ../env.properties
fi

if [[ -z "${serverName}" ]]; then
  serverList=( $(ini-parse "../env.properties" "no" "system" "server") )
  if [[ "${#serverList[@]}" -gt 0 ]]; then
    for server in "${serverList[@]}"; do
      webServer=$(ini-parse "../env.properties" "no" "${server}" "webServer")
      if [[ -n "${webServer}" ]]; then
        useServer=0
        echo ""
        echo "Do you wish to use server \"${server}\" to deploy a release candidate?"
        select yesNo in "Yes" "No"; do
          case "${yesNo}" in
            Yes ) useServer=1; break;;
            No ) break;;
          esac
        done
        if [[ "${useServer}" == 1 ]]; then
          serverName="${server}"
          break
        fi
      fi
    done
  fi
fi

if [[ -z "${serverName}" ]]; then
  echo "No server name specified!"
  echo ""
  usage
  exit 1
fi

useDeploy=0
echo ""
echo "Do you wish to deploy release candidates?"
select yesNo in "Yes" "No"; do
  case "${yesNo}" in
    Yes ) useDeploy=1; break;;
    No ) break;;
  esac
done

if [[ "${useDeploy}" == 1 ]]; then
  ini-set ../env.properties yes deploy server "${serverName}"

  deployPath=
  webServer=$(ini-parse "../env.properties" "no" "${serverName}" "webServer")
  if [[ -n "${webServer}" ]]; then
    webPath=$(ini-parse "../env.properties" "no" "${serverName}" "webPath")
    if [[ -n "${webPath}" ]]; then
      basePath=$(dirname "${webPath}")
      deployPath="${basePath}/deployments"
    fi
  fi

  echo ""
  echo "Please specify the deploy path, followed by [ENTER]:"
  read -i "${deployPath}" -e -r deployPath
  ini-set ../env.properties yes "${serverName}" deployPath "${deployPath}"

  echo ""
  echo "Please specify the deploy history count, followed by [ENTER]:"
  read -i "5" -e -r deployHistoryCount
  ini-set ../env.properties yes deploy deployHistoryCount "${deployHistoryCount}"

  useUpgrade=0
  echo ""
  echo "Do you wish to upgrade the database on server: ${serverName}?"
  select yesNo in "Yes" "No"; do
    case "${yesNo}" in
      Yes ) useUpgrade=1; break;;
      No ) break;;
    esac
  done

  if [[ "${useUpgrade}" == 1 ]]; then
    ini-set ../env.properties yes "${serverName}" upgrade yes
  else
    ini-set ../env.properties yes "${serverName}" upgrade no
  fi
fi
