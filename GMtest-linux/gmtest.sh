#By j1nj1 
#Github https://github.com/j1nj1CL
#wx wx_f0r_work
#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' 

if [ "$#" -ne 1 ]; then
    echo -e "${RED}Usage: bash $0 [domain or IP]"
    echo -e "eg:bash ./gmtest.sh www.baidu.com${NC}"
    exit 1
fi

SERVER=$1
PORT=443

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
OPENSSL_PATH="$SCRIPT_DIR/openssl"
readarray -t CIPHER_DETAILS <<< "$($OPENSSL_PATH ciphers -v | awk '{print $1, $2, $3, $4, $5, $6}')"

declare -A SUPPORTED_CIPHERS_INFO
for CIPHER_INFO in "${CIPHER_DETAILS[@]}"
do
    IFS=' ' read -ra CIPHER <<< "$CIPHER_INFO"
    CIPHER_NAME=${CIPHER[0]}
    TLS_VERSION=${CIPHER[1]}
    if [[ $TLS_VERSION == "TLSv1.3" ]]; then
        RESULT=$(echo -n | $OPENSSL_PATH s_client -tls1_3 -ciphersuites "$CIPHER_NAME" -connect $SERVER:$PORT 2>&1)
    elif [[ $TLS_VERSION == "NTLSv1.1" ]]; then
        RESULT=$(echo -n | $OPENSSL_PATH s_client -enable_ntls -ntls -cipher "$CIPHER_NAME" -connect $SERVER:$PORT 2>&1)
    elif [[ $TLS_VERSION == "TLSv1.2" ]]; then
        RESULT=$(echo -n | $OPENSSL_PATH s_client -tls1_2 -cipher "$CIPHER_NAME" -connect $SERVER:$PORT 2>&1)
    elif [[ $TLS_VERSION == "TLSv1" ]]; then
        RESULT=$(echo -n | $OPENSSL_PATH s_client -tls1 -cipher "$CIPHER_NAME" -connect $SERVER:$PORT 2>&1)
    elif [[ $TLS_VERSION == "SSLv3" ]]; then
        RESULT=$(echo -n | $OPENSSL_PATH s_client -no_tls1_3 -no_tls1_2 -no_tls1_1 -no_tls1 -no_tls1 -cipher "$CIPHER_NAME" -connect $SERVER:$PORT 2>&1)
    else
        RESULT=$(echo -n | $OPENSSL_PATH s_client -cipher "$CIPHER_NAME" -connect $SERVER:$PORT 2>&1)
    fi
    if echo "$RESULT" | grep -q "Cipher is $CIPHER_NAME" && ! echo "$RESULT" | grep -qE "(handshake failure|Cipher    : 0000)"; then
        SUPPORTED_CIPHERS_INFO[$TLS_VERSION]+="${CIPHER_INFO}\n"
    fi
done

echo "Supported Cipher Suites for $SERVER:"
for VERSION in "${!SUPPORTED_CIPHERS_INFO[@]}"
do
    echo -e "${BLUE}TLS Version: $VERSION${NC}"
    echo -e "${GREEN}"
    printf "%b" "${SUPPORTED_CIPHERS_INFO[$VERSION]}" | sed '/^$/d' | sort -u
    echo -e "${NC}"
done