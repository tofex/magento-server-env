#!/bin/bash -e

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

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

echo ""
echo "Please specify the name of the system, followed by [ENTER]:"
read -i "system" -e -r systemName

echo ""
echo "Please specify the name of the host, followed by [ENTER]:"
read -r -e hostName

echo ""
echo "Please specify the scope of the host (website or store), followed by [ENTER]:"
read -r -e hostScope

echo ""
echo "Please specify the code of the host scope, followed by [ENTER]:"
read -r -e hostCode

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

hostId=$(echo "${hostName}" | sed "s/[^[:alnum:]]/_/g")

./init-host.sh \
  -n "${systemName}" \
  -i "${hostId}" \
  -v "${hostName}" \
  -s "${hostScope}" \
  -c "${hostCode}" \
  -t "${sslTerminated}" \
  -f "${forceSsl}"
