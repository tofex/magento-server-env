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
        echo "Do you wish to use server \"${server}\" to build a release candidate?"
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

useComposerBuild=0
echo ""
echo "Do you wish to use Composer to build a release candidate?"
select yesNo in "Yes" "No"; do
  case "${yesNo}" in
    Yes ) useComposerBuild=1; break;;
    No ) break;;
  esac
done

if [[ "${useComposerBuild}" == 1 ]]; then
  ini-set ../env.properties yes build type composer

  echo ""
  echo "Please specify the name of the composer project, followed by [ENTER]:"
  read -r composerProject
  ini-set ../env.properties yes build composerProject "${composerProject}"

  echo ""
  echo "Please specify the user of the Tofex composer repository, followed by [ENTER]:"
  read -r composerUser
  echo ""
  echo "Please specify the password of the Tofex composer repository, followed by [ENTER]:"
  read -r composerPassword
  ini-set ../env.properties yes build repositories "composer|https://composer.tofex.de|${composerUser}|${composerPassword}"
else
  useGitBuild=0
  echo ""
  echo "Do you wish to use Git to build a release candidate?"
  select yesNo in "Yes" "No"; do
    case "${yesNo}" in
      Yes ) useGitBuild=1; break;;
      No ) break;;
    esac
  done

  if [[ "${useGitBuild}" == 1 ]]; then
    ini-set ../env.properties yes build type git

    echo ""
    echo "Please specify the Git url to clone from, followed by [ENTER]:"
    read -r gitUrl
    ini-set ../env.properties yes build gitUrl "${gitUrl}"

    if [[ "${gitUrl}" =~ ^git.* ]]; then
      useCurrentUser=0
      echo ""
      echo "Use the current user to access the Git repository?"
      select yesNo in "Yes" "No"; do
        case "${yesNo}" in
          Yes ) useCurrentUser=1; break;;
          No ) break;;
        esac
      done

      currentUser=$(whoami)

      if [[ "${useCurrentUser}" == 1 ]]; then
        gitUser="${currentUser}"

        home=$(awk -F: -v u="${gitUser}" '$1==u{print $6}' /etc/passwd)

        if [[ ! -f "${home}/.ssh/id_rsa.pub" ]]; then
          addKey=0
          echo ""
          echo "Could not find public key of user ${gitUser}. Do you wish to create a key?"
          select yesNo in "Yes" "No"; do
            case "${yesNo}" in
              Yes ) addKey=1; break;;
              No ) break;;
            esac
          done

          if [[ "${addKey}" == 1 ]]; then
            echo "Generating SSH key in directory: ${home}/.ssh"
            ssh-keygen -b 4096 -t rsa -f "${home}/.ssh/id_rsa" -q -N ""
          fi
        fi
      else
        echo ""
        echo "Please specify the user to access the Git repository, followed by [ENTER]:"
        read -r gitUrl
      fi

      ini-set ../env.properties yes build user "${gitUser}"
    fi

    useGitBuildComposer=0
    echo ""
    echo "Do you wish to run install composer requirements during build process?"
    select yesNo in "Yes" "No"; do
      case "${yesNo}" in
        Yes ) useGitBuildComposer=1; break;;
        No ) break;;
      esac
    done
    if [[ "${useGitBuildComposer}" == 1 ]]; then
      ini-set ../env.properties yes build composer yes
    else
      ini-set ../env.properties yes build composer no
    fi
  fi
fi

if [[ "${useComposerBuild}" == 1 ]] || [[ "${useGitBuild}" == 1 ]]; then
  ini-set ../env.properties yes build server "${serverName}"

  buildPath=
  webServer=$(ini-parse "../env.properties" "no" "${serverName}" "webServer")
  if [[ -n "${webServer}" ]]; then
    webPath=$(ini-parse "../env.properties" "no" "${serverName}" "webPath")
    if [[ -n "${webPath}" ]]; then
      basePath=$(dirname "${webPath}")
      buildPath="${basePath}/builds"
    fi
  fi

  echo ""
  echo "Please specify the build path, followed by [ENTER]:"
  read -i "${buildPath}" -e -r buildPath
  ini-set ../env.properties yes "${serverName}" buildPath "${buildPath}"
fi
