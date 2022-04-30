#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -n  System name, default: system
  -o  Hosts

Example: ${scriptName} -n server
EOF
}

trim()
{
  echo -n "$1" | xargs
}

systemName=
hosts=

while getopts hn:o:? option; do
  case "${option}" in
    h) usage; exit 1;;
    n) systemName=$(trim "$OPTARG");;
    o) hosts=$(trim "$OPTARG");;
    ?) usage; exit 1;;
  esac
done

if [[ -z "${systemName}" ]]; then
  systemName="system"
fi

if [[ -z "${hosts}" ]]; then
  echo "No hosts specified!"
  exit 1
fi

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "${currentPath}"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  touch "${currentPath}/../env.properties"
fi

if [[ -n "${hosts}" ]] && [[ "${hosts}" != "-" ]]; then
  hostList=( $(echo "${hosts}" | tr "," "\n") )

  for host in "${hostList[@]}"; do
    hostName=$(echo "${host}" | cut -d: -f1)
    hostScope=$(echo "${host}" | cut -d: -f2)
    hostCode=$(echo "${host}" | cut -d: -f3)
    sslTerminated=$(echo "${host}" | cut -d: -f4)
    forceSsl=$(echo "${host}" | cut -d: -f5)

    if [[ -z "${sslTerminated}" ]]; then
      sslTerminated="no"
    fi

    if [[ -z "${forceSsl}" ]]; then
      forceSsl="yes"
    fi

    hostId=$(echo "${hostName}" | sed "s/[^[:alnum:]]/_/g")

    "${currentPath}/init-host.sh" \
      -n "${systemName}" \
      -i "${hostId}" \
      -v "${hostName}" \
      -s "${hostScope}" \
      -c "${hostCode}" \
      -t "${sslTerminated}" \
      -f "${forceSsl}"
  done
fi
