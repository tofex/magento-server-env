#!/bin/bash -e

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptName="${0##*/}"

usage()
{
cat >&2 << EOF

usage: ${scriptName} options

OPTIONS:
  --help                Show this message
  --systemName          System name, default: system
  --smtpId              SMTP id, default: smtp
  --enabled             Flag if SMTP sending is enabled, default: true
  --disabled            Flag if SMTP sending is disabled
  --smtpHost            SMTP host
  --smptPort            SMTP port, default: 587
  --smtpProtocol        SMTP protocol (none, ssl or tls), default: tls
  --smtpAuthentication  SMTP authentication method (none, plain, login, cram-md5), default: login
  --smtpUser            SMTP user
  --smtpPassword        SMTP password

Example: ${scriptName} --enabled --smtpHost stmp.mailserver.com --smptPort 465 --smtpProtocol ssl --smtpUser user --smtpPassword secret
EOF
}

systemName=
smtpId=
enabled=
disabled=
smtpHost=
smtpPort=
smtpProtocol=
smtpAuthentication=
smtpUser=
smtpPassword=

source "${currentPath}/../core/prepare-parameters.sh"

if [[ -z "${systemName}" ]]; then
  systemName="system"
fi

if [[ -z "${smtpId}" ]]; then
  smtpId="smtp"
fi

if [[ "${disabled}" == "yes" ]] || [[ "${disabled}" == "true" ]]; then
  disabled=1
fi

if [[ "${disabled}" == 1 ]]; then
  enabled="no"
else
  enabled="yes"
fi

if [[ "${enabled}" == "yes" ]]; then
  if [[ -z "${smtpHost}" ]]; then
    echo "No SMTP host specified!"
    usage
    exit 1
  fi

  if [[ -z "${smtpPort}" ]]; then
    smtpPort="587"
  fi

  if [[ -z "${smtpProtocol}" ]]; then
    smtpProtocol="tls"
  fi

  if [[ -z "${smtpAuthentication}" ]]; then
    smtpAuthentication="login"
  fi

  if [[ -n "${smtpAuthentication}" ]] && [[ "${smtpAuthentication}" != "none" ]]; then
    if [[ -z "${smtpUser}" ]]; then
      echo "No SMTP user specified!"
      usage
      exit 1
    fi

    if [[ -z "${smtpPassword}" ]]; then
      echo "No SMTP password specified!"
      usage
      exit 1
    fi
  fi
fi

if [[ ! -f "${currentPath}/../env.properties" ]]; then
  touch "${currentPath}/../env.properties"
fi

ini-set "${currentPath}/../env.properties" no "${systemName}" smtp "${smtpId}"
ini-set "${currentPath}/../env.properties" yes "${smtpId}" enabled "${enabled}"
if [[ "${enabled}" == "yes" ]]; then
  ini-set "${currentPath}/../env.properties" yes "${smtpId}" host "${smtpHost}"
  ini-set "${currentPath}/../env.properties" yes "${smtpId}" port "${smtpPort}"
  ini-set "${currentPath}/../env.properties" yes "${smtpId}" protocol "${smtpProtocol}"
  ini-set "${currentPath}/../env.properties" yes "${smtpId}" authentication "${smtpAuthentication}"
  if [[ -n "${smtpAuthentication}" ]] && [[ "${smtpAuthentication}" != "none" ]]; then
    ini-set "${currentPath}/../env.properties" yes "${smtpId}" user "${smtpUser}"
    ini-set "${currentPath}/../env.properties" yes "${smtpId}" password "${smtpPassword}"
  fi
fi
