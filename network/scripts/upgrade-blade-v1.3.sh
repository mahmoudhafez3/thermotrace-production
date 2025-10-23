#!/bin/bash
set -e

echo "Upgrading to v1.3 (Fixed Time.Time issue)"

export PATH=$HOME/thermotrace-production/bin:$PATH
export FABRIC_CFG_PATH=$PWD/../../config

CC_NAME="bladeinspection"
CC_VERSION="1.3"
CC_SEQUENCE=4
CC_SRC_PATH="../../chaincode/blade-inspection/go"

peer lifecycle chaincode package ${CC_NAME}_v1.3.tar.gz \
  --path ${CC_SRC_PATH} --lang golang --label ${CC_NAME}_${CC_VERSION}

export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="MROLabMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/../../organizations/peerOrganizations/mrolab.thermotrace.com/peers/peer0.mrolab.thermotrace.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=$PWD/../../organizations/peerOrganizations/mrolab.thermotrace.com/users/Admin@mrolab.thermotrace.com/msp
export CORE_PEER_ADDRESS=peer0.mrolab.thermotrace.com:7051

peer lifecycle chaincode install ${CC_NAME}_v1.3.tar.gz

export CORE_PEER_LOCALMSPID="ManufacturerMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/../../organizations/peerOrganizations/manufacturer.thermotrace.com/peers/peer0.manufacturer.thermotrace.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=$PWD/../../organizations/peerOrganizations/manufacturer.thermotrace.com/users/Admin@manufacturer.thermotrace.com/msp
export CORE_PEER_ADDRESS=peer0.manufacturer.thermotrace.com:9051

peer lifecycle chaincode install ${CC_NAME}_v1.3.tar.gz

export CORE_PEER_LOCALMSPID="MROLabMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/../../organizations/peerOrganizations/mrolab.thermotrace.com/peers/peer0.mrolab.thermotrace.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=$PWD/../../organizations/peerOrganizations/mrolab.thermotrace.com/users/Admin@mrolab.thermotrace.com/msp
export CORE_PEER_ADDRESS=peer0.mrolab.thermotrace.com:7051

peer lifecycle chaincode queryinstalled > installed_v13.txt
PACKAGE_ID=$(sed -n "/${CC_NAME}_${CC_VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" installed_v13.txt)
echo "Package ID: $PACKAGE_ID"

export ORDERER_CA=$PWD/../../organizations/ordererOrganizations/thermotrace.com/orderers/orderer1.thermotrace.com/msp/tlscacerts/tlsca.thermotrace.com-cert.pem

peer lifecycle chaincode approveformyorg -o orderer1.thermotrace.com:7050 \
  --ordererTLSHostnameOverride orderer1.thermotrace.com --channelID inspection-channel \
  --name ${CC_NAME} --version ${CC_VERSION} --package-id ${PACKAGE_ID} \
  --sequence ${CC_SEQUENCE} --tls --cafile ${ORDERER_CA}

export CORE_PEER_LOCALMSPID="ManufacturerMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/../../organizations/peerOrganizations/manufacturer.thermotrace.com/peers/peer0.manufacturer.thermotrace.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=$PWD/../../organizations/peerOrganizations/manufacturer.thermotrace.com/users/Admin@manufacturer.thermotrace.com/msp
export CORE_PEER_ADDRESS=peer0.manufacturer.thermotrace.com:9051

peer lifecycle chaincode approveformyorg -o orderer1.thermotrace.com:7050 \
  --ordererTLSHostnameOverride orderer1.thermotrace.com --channelID inspection-channel \
  --name ${CC_NAME} --version ${CC_VERSION} --package-id ${PACKAGE_ID} \
  --sequence ${CC_SEQUENCE} --tls --cafile ${ORDERER_CA}

peer lifecycle chaincode commit -o orderer1.thermotrace.com:7050 \
  --ordererTLSHostnameOverride orderer1.thermotrace.com --channelID inspection-channel \
  --name ${CC_NAME} --version ${CC_VERSION} --sequence ${CC_SEQUENCE} --tls --cafile ${ORDERER_CA} \
  --peerAddresses peer0.mrolab.thermotrace.com:7051 \
  --tlsRootCertFiles $PWD/../../organizations/peerOrganizations/mrolab.thermotrace.com/peers/peer0.mrolab.thermotrace.com/tls/ca.crt \
  --peerAddresses peer0.manufacturer.thermotrace.com:9051 \
  --tlsRootCertFiles $PWD/../../organizations/peerOrganizations/manufacturer.thermotrace.com/peers/peer0.manufacturer.thermotrace.com/tls/ca.crt

echo "✓ Upgraded to v1.3!"
peer lifecycle chaincode querycommitted --channelID inspection-channel --name ${CC_NAME}
