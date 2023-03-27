#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -e  PHP executable (optional)

Example: ${scriptName}
EOF
}

trim()
{
  echo -n "$1" | xargs
}

phpExecutable="php"

while getopts he:? option; do
  case "${option}" in
    h) usage; exit 1;;
    e) phpExecutable=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  touch "${currentPath}/../env.properties"
fi

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

for server in "${serverList[@]}"; do
  serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")
  webServer=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "webServer")

  if [[ -n "${webServer}" ]]; then
    webPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${webServer}" "path")

    if [[ "${serverType}" == "local" ]]; then
      phpExecutable=$(which php)
      if [[ $(which locate 2>/dev/null | wc -l) -gt 0 ]]; then
        availablePhpExecutables=( $(locate bin/php | cat | grep -E php$ | cat) )
      else
        availablePhpExecutables=( $(find / -path "*bin/php" 2>/dev/null | cat) )
      fi

      if [[ "${#availablePhpExecutables[@]}" -gt 1 ]]; then
        echo "Found multiple PHP executables:"
        printf '%s\n' "${availablePhpExecutables[@]}"

        usePhpExecutable=0
        echo ""
        echo "Do you wish to use the current PHP executable at: ${phpExecutable}?"
        select yesNo in "Yes" "No"; do
          case "${yesNo}" in
            Yes ) usePhpExecutable=1; break;;
            No ) break;;
          esac
        done

        if [[ "${usePhpExecutable}" == 0 ]]; then
          echo ""
          echo "Please specify the PHP executable to use, followed by [ENTER]:"
          read -r phpExecutable
        fi
      fi

      if [[ -z "${phpExecutable}" ]]; then
        echo "PHP executable not found"
        exit 1
      fi

      webUser=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webUser")
      webGroup=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webGroup")

      if [[ -f "${webPath}/app/etc/local.xml" ]]; then
        magentoVersion=1
      elif [[ -f "${webPath}/app/etc/env.php" ]]; then
        magentoVersion=2
      else
        echo "Could not determine Magento version."
        continue
      fi

      echo -n "Extracting Magento version: "
      magentoSpecificVersion=$("${currentPath}/../ops/get-magento-version/web-server.sh" \
        -w "${webPath}" \
        -u "${webUser}" \
        -g "${webGroup}" \
        -b "${phpExecutable}")
      echo "${magentoSpecificVersion}"

      echo -n "Extracting Magento edition: "
      if [[ "${magentoVersion}" == 1 ]]; then
        magentoEdition=$(cd "${webPath}"; "${phpExecutable}" -r "require 'app/Mage.php'; echo Mage::getEdition();")
      elif [[ "${magentoVersion}" == 2 ]]; then
        magentoEdition=$(cd "${webPath}"; composer licenses 2>/dev/null | grep "magento/product" | cut -d'-' -f2)
      fi
      magentoEdition=$(echo "${magentoEdition}" | tr '[:upper:]' '[:lower:]')
      echo "${magentoEdition}"

      echo -n "Extracting Magento mode: "
      if [[ "${magentoVersion}" == 1 ]]; then
        magentoMode="production"
      elif [[ "${magentoVersion}" == 2 ]]; then
        if [[ $(cd "${webPath}"; "${phpExecutable}" bin/magento deploy:mode:show | grep -c "production" | cat) -gt 0 ]]; then
          magentoMode="production"
        else
          if [[ $(cd "${webPath}"; "${phpExecutable}" bin/magento deploy:mode:show | grep -c "developer" | cat) -gt 0 ]]; then
            magentoMode="developer"
          else
            magentoMode="default"
          fi
        fi
      fi
      echo "${magentoMode}"

      echo -n "Extracting Magento crypt key: "
      if [[ "${magentoVersion}" == 1 ]]; then
        # shellcheck disable=SC2016
        cryptKey=$(cd "${webPath}"; "${phpExecutable}" -r '$config=simplexml_load_file("app/etc/local.xml",null,LIBXML_NOCDATA);echo (string)$config->global->crypt->key;')
      elif [[ "${magentoVersion}" == 2 ]]; then
        # shellcheck disable=SC2016
        cryptKey=$(cd "${webPath}"; "${phpExecutable}" -r '$config=include "app/etc/env.php"; echo $config["crypt"]["key"];')
      fi
      echo "${cryptKey}"

      ./init-install.sh \
        --magentoVersion "${magentoSpecificVersion}" \
        --magentoEdition "${magentoEdition}" \
        --magentoMode "${magentoMode}" \
        --cryptKey "${cryptKey}"
    fi
  fi
done
