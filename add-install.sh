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

while getopts hs:? option; do
  case "${option}" in
    h) usage; exit 1;;
    ?) usage; exit 1;;
  esac
done

echo ""
echo "Please specify the Magento version, followed by [ENTER]:"
read -r -i "2.4.5-p1" -e magentoVersion

echo ""
echo "Please specify the Magento edition, followed by [ENTER]:"
read -r -i "community" -e magentoEdition

echo ""
echo "Please specify the Magento mode, followed by [ENTER]:"
read -r -i "production" -e magentoMode

echo ""
echo "Please specify the crypt key (empty to generate), followed by [ENTER]:"
read -r -e cryptKey

if [[ -z "${cryptKey}" ]]; then
  cryptKey=$(echo "${RANDOM}" | md5sum | head -c 32)
fi

echo ""
echo "Please specify the Magento composer user, followed by [ENTER]:"
read -r -e magentoComposerUser

echo ""
echo "Please specify the Magento composer password, followed by [ENTER]:"
read -r -e magentoComposerPassword

echo ""
echo "Please specify the Magento mode, followed by [ENTER]:"
read -r -i "admin" -e adminPath

echo ""
echo "Please specify the system mail address, followed by [ENTER]:"
read -r -e systemMailAddress

"${currentPath}/init-install.sh" \
  -v "${magentoVersion}" \
  -e "${magentoEdition}" \
  -p "${magentoMode}" \
  -c "${cryptKey}" \
  -u "${magentoComposerUser}" \
  -p "${magentoComposerPassword}" \
  -a "${adminPath}" \
  -i "${systemMailAddress}"
