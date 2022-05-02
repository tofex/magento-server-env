#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -t  Server type (local or ssh)

Example: ${scriptName} -t local
EOF
}

trim()
{
  echo -n "$1" | xargs
}

serverType=

while getopts ht:? option; do
  case "${option}" in
    h) usage; exit 1;;
    t) serverType=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ -z "${serverType}" ]]; then
  echo ""
  echo "Do you wish to add a local server?"
  select yesNo in "Yes" "No"; do
    case "${yesNo}" in
      Yes ) serverType=local; break;;
      No ) serverType=ssh; break;;
    esac
  done
fi

if [[ -z "${serverType}" ]]; then
  echo "No server type specified!"
fi

if [[ "${serverType}" != "local" ]] && [[ "${serverType}" != "ssh" ]]; then
  echo "Invalid server type specified!"
fi

if [[ "${serverType}" == "local" ]]; then
  host="localhost"
  sshUser="-"
elif [[ "${serverType}" == "ssh" ]]; then
  echo ""
  echo "Please specify the SSH host, followed by [ENTER]:"
  read -r -e host

  echo ""
  echo "Please specify the SSH user, followed by [ENTER]:"
  read -r -e sshUser
fi

echo ""
echo "Please specify the web path of Magento, followed by [ENTER]:"
read -r -e webPath

webPath=$(echo "${webPath}" | sed 's:/*$::')
webPath="${webPath%/}"

if [[ "${serverType}" == "local" ]]; then
  currentUser=$(whoami)
  currentGroup=$(id -gn "${currentUser}")
  webUser=$(ls -ld "${webPath}"/ | awk '{print $3}')
  webGroup=$(ls -ld "${webPath}"/ | awk '{print $4}')
#else
  #@todo: SSH handling
fi

if [[ "${webUser}" != "${currentUser}" ]] || [[ "${webGroup}" != "${currentGroup}" ]]; then
  echo "The magento root path is owned by user: ${webUser}:${webGroup}. Do you want to use this user as deployment user? Sudo rights would be required for current user: ${currentUser}:${currentGroup}."
  select yesNo in "Yes" "No"; do
    case "${yesNo}" in
      Yes ) break;;
      No ) webUser="${currentUser}"; webGroup="${currentGroup}" break;;
    esac
  done
fi

./init-server.sh \
  -t "${serverType}" \
  -o "${host}" \
  -s "${sshUser}" \
  -p "${webPath}" \
  -u "${webUser}" \
  -g "${webGroup}"
