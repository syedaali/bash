#!/bin/bash

# Script written  2014-10-24
# Author: Syed Ali alicsyed@gmail.com
# Purpose: To create user certificate/key for Openvpn
# Usage:  script-name.sh <username>
# Output: 2 files, username.{key,crt} in /etc/openvpn/keys and a
# zip file <username>.zip in /usr/share/easy-rsa/2.0 that contains
# 4 files, two of the above and one ca.crt, along with custom.ovpn config file
# the custom.ovpn file is a Viscosity configuration file to import into Viscosity
# you can replace that file with your OpenVPN client config file

## BEGIN CUSTOMIZATION
PREFIX='/usr/share/easy-rsa/2.0'
SRC_KEYS="${PREFIX}/keys"
DST_KEYS='/etc/openvpn/keys'
VARS="${PREFIX}/vars"
BUILD_KEY="${PREFIX}/build-key"
OVPN_CONFIG="${SRC_KEYS}/custom.ovpn"
## END CUSTOMIZATION

if [ -z ${1} ];
then
    printf "must supply username, exiting\n"
    exit 1
fi

check_if_exists () {
    
    if [ ! ${1} ${2} ];
    then
        printf "${2} missing, exiting\n!"
        exit 1
    else
        printf "${2} found, good...\n"
    fi
    
}

check_if_exists '-d' ${PREFIX} 
check_if_exists '-d' ${SRC_KEYS} 
check_if_exists '-d' ${DST_KEYS} 
check_if_exists '-f' ${VARS} 
check_if_exists '-f' ${BUILD_KEY} 
check_if_exists '-f' ${OVPN_CONFIG} 

cd ${PREFIX}
source ${VARS} ${1}
${BUILD_KEY} --batch ${1}

printf "Key generation complete, zipping keys...\n"
/usr/bin/zip --no-dir-entries --junk-paths ${SRC_KEYS}/${1}.zip ${SRC_KEYS}/${1}.{key,crt} ${OVPN_CONFIG} ${SRC_KEYS}/ca.crt

printf "Copying keys to openvpn keys directory...\n"
/bin/cp ${SRC_KEYS}/${1}.{key,crt} ${DST_KEYS}

printf "All DONE!!! You can email the user the zip file in ${SRC_KEYS} and once they unzip it, they can use the ${OVPN_CONFIG} file to import in their VPN Client :)\n"

exit 0

