#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message

Example: ${scriptName}
EOF
}

trim()
{
  echo -n "$1" | xargs
}

while getopts h? option; do
  case "${option}" in
    h) usage; exit 1;;
    ?) usage; exit 1;;
  esac
done

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  touch "${currentPath}/../env.properties"
fi

echo ""
echo "Please specify the name of the host, followed by [ENTER]:"
read -r -e hostName

echo ""
echo "Please specify the scope of the host (website or store), followed by [ENTER]:"
read -r -e hostScope

echo ""
echo "Please specify the code of the host scope, followed by [ENTER]:"
read -r -e hostCode

sslTerminated="no"
echo ""
echo "Is this host SSL terminated?"
select yesNo in "Yes" "No"; do
  case "${yesNo}" in
    Yes ) sslTerminated="yes"; break;;
    No ) break;;
  esac
done

forceSsl="no"
echo ""
echo "Should SSL be forced on this host?"
select yesNo in "Yes" "No"; do
  case "${yesNo}" in
    Yes ) forceSsl="yes"; break;;
    No ) break;;
  esac
done

basicAuth="no"
echo ""
echo "Use basic auth?"
select yesNo in "Yes" "No"; do
  case "${yesNo}" in
    Yes ) basicAuth="yes"; break;;
    No ) break;;
  esac
done

if [[ "${basicAuth}" == "yes" ]]; then
  echo ""
  echo "Please specify the user name of the basic auth, followed by [ENTER]:"
  read -r -e basicAuthUserName

  echo ""
  echo "Please specify the password of the basic auth, followed by [ENTER]:"
  read -r -e basicAuthPassword
fi

hostId=$(echo "${hostName}" | sed "s/[^[:alnum:]]/_/g")

if [[ "${basicAuth}" == "yes" ]]; then
  "${currentPath}/init-host.sh" \
    --systemName "system" \
    --hostId "${hostId}" \
    --virtualHost "${hostName}" \
    --scope "${hostScope}" \
    --code "${hostCode}" \
    --sslTerminated "${sslTerminated}" \
    --forceSsl "${forceSsl}" \
    --basicAuthUserName "${basicAuthUserName}" \
    --basicAuthPassword "${basicAuthPassword}"
else
  "${currentPath}/init-host.sh" \
    --systemName "system" \
    --hostId "${hostId}" \
    --virtualHost "${hostName}" \
    --scope "${hostScope}" \
    --code "${hostCode}" \
    --sslTerminated "${sslTerminated}" \
    --forceSsl "${forceSsl}"
fi
