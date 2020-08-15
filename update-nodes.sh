
#!/bin/bash

###################################################################################################
# CONFIGURATION
###################################################################################################

UPDATE_MAINNET_NODE=true
UPDATE_TESTNET_NODE=false


###################################################################################################
# MAIN
###################################################################################################

###
# Only check for new stable releases to mainnet for both mainnet and testnet nodes
###
date +"%Y-%m-%d %H:%M:%S || [INFO] Checking for new ardor release"
ALIAS_VERSION=$(curl --connect-timeout 2 --retry 2 --retry-delay 0 --retry-max-time 2 -s -S "http://127.0.0.1:27876/nxt?requestType=getAlias&aliasName=nrsVersion&chain=2")
REMOTE_VERSION=$( echo ${ALIAS_VERSION} | jq '.aliasURI' | sed -e 's/^"//' -e 's/"$//' | head -n1 | awk '{print $1;}')

BLOCKCHAIN_VERSION=$(curl --connect-timeout 2 --retry 2 --retry-delay 0 --retry-max-time 2 -s -S "http://127.0.0.1:27876/nxt?requestType=getBlockchainStatus")
LOCAL_VERSION=$( echo ${BLOCKCHAIN_VERSION} | jq '.version' | sed -e 's/^"//' -e 's/"$//')

if [ -z ${REMOTE_VERSION} ] || [ -z ${LOCAL_VERSION} ]; then
  echo "[WARNING] Failed to check ardor versions"
  exit 1
fi

if [ ${REMOTE_VERSION} != ${LOCAL_VERSION} ]; then
  cd /home/ardor

  echo "[INFO] downloading new ardor release ..."
  wget https://www.jelurida.com/ardor-client.zip -q --show-progress
  wget https://www.jelurida.com/ardor-client.zip.asc -q --show-progress
  gpg --with-fingerprint --verify ardor-client.zip.asc ardor-client.zip

  echo "" && echo "[INFO] unzipping new ardor release ..."
  unzip -qq ardor-client.zip


  if [ ${UPDATE_MAINNET_NODE} == true ]; then

      echo "" && echo "[INFO] stopping ardor mainnet service ..."
      sudo systemctl stop ardor-mainnet.service


      echo "" && echo "[INFO] installing new ardor release ..."
      mkdir ardor-mainnet-update

      mv ./ardor-mainnet/conf/nxt.properties ./ardor-mainnet-update/nxt.properties
      sudo mv ./ardor-mainnet/nxt_db/ ./ardor-mainnet-update/nxt_db/

      rm -rf ./ardor-mainnet/
      cp -r ./ardor ./ardor-mainnet

      mv ./ardor-mainnet-update/nxt.properties ./ardor-mainnet/conf/nxt.properties
      sudo mv ./ardor-mainnet-update/nxt_db/ ./ardor-mainnet/nxt_db/


      echo "" && echo "[INFO] restarting ardor mainnet service ..."
      sudo systemctl start ardor-mainnet.service
  fi


  if [ ${UPDATE_TESTNET_NODE} == true ]; then

      echo "" && echo "[INFO] stopping ardor testnet service ..."
      sudo systemctl stop ardor-testnet.service


      echo "" && echo "[INFO] installing new ardor release ..."
      mkdir ardor-testnet-update

      mv ./ardor-testnet/conf/nxt.properties ./ardor-testnet-update/nxt.properties
      sudo mv ./ardor-testnet/nxt_test_db/ ./ardor-testnet-update/nxt_test_db/

      rm -rf ./ardor-testnet/
      cp -r ./ardor ./ardor-testnet

      mv ./ardor-testnet-update/nxt.properties ./ardor-testnet/conf/nxt.properties
      sudo mv ./ardor-testnet-update/nxt_test_db/ ./ardor-testnet/nxt_test_db/


      echo "" && echo "[INFO] restarting ardor testnet service ..."
      sudo systemctl start ardor-testnet.service
  fi


  echo "" && echo "[INFO] cleaning up ..."
  rm -rf ./ardor-mainnet-update ./ardor-testnet-update
  rm -rf ardor ardor-client.zip ardor-client.zip.asc

  echo "" && echo "[INFO] done. Ardor nodes updated"
else
  echo "" && echo "[INFO] No update available"
fi

