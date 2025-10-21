#!/bin/bash
set -e

echo "=========================================="
echo "Deploying Test Asset Chaincode"
echo "=========================================="

export PATH=$HOME/thermotrace-production/bin:$PATH
export FABRIC_CFG_PATH=$PWD/../config

CC_NAME="testasset"
CC_VERSION="1.0"
CC_SEQUENCE=1
CC_SRC_PATH="../chaincode/test-asset/go"

echo ""
echo "Step 1: Packaging chaincode..."
peer lifecycle chaincode package ${CC_NAME}.tar.gz \
  --path ${CC_SRC_PATH} \
  --lang golang \
  --label ${CC_NAME}_${CC_VERSION}

echo "✓ Chaincode packaged: ${CC_NAME}.tar.gz"

# Install on MROLab peer
echo ""
echo "Step 2: Installing on MROLab peer..."
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="MROLabMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/../organizations/peerOrganizations/mrolab.thermotrace.com/peers/peer0.mrolab.thermotrace.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=$PWD/../organizations/peerOrganizations/mrolab.thermotrace.com/users/Admin@mrolab.thermotrace.com/msp
export CORE_PEER_ADDRESS=peer0.mrolab.thermotrace.com:7051

peer lifecycle chaincode install ${CC_NAME}.tar.gz

echo "✓ Installed on MROLab peer"

# Install on Manufacturer peer
echo ""
echo "Step 3: Installing on Manufacturer peer..."
export CORE_PEER_LOCALMSPID="ManufacturerMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/../organizations/peerOrganizations/manufacturer.thermotrace.com/peers/peer0.manufacturer.thermotrace.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=$PWD/../organizations/peerOrganizations/manufacturer.thermotrace.com/users/Admin@manufacturer.thermotrace.com/msp
export CORE_PEER_ADDRESS=peer0.manufacturer.thermotrace.com:9051

peer lifecycle chaincode install ${CC_NAME}.tar.gz

echo "✓ Installed on Manufacturer peer"

# Query installed chaincode to get package ID
echo ""
echo "Step 4: Querying installed chaincode..."
export CORE_PEER_LOCALMSPID="MROLabMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/../organizations/peerOrganizations/mrolab.thermotrace.com/peers/peer0.mrolab.thermotrace.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=$PWD/../organizations/peerOrganizations/mrolab.thermotrace.com/users/Admin@mrolab.thermotrace.com/msp
export CORE_PEER_ADDRESS=peer0.mrolab.thermotrace.com:7051

peer lifecycle chaincode queryinstalled > installed.txt
cat installed.txt

# Extract package ID
PACKAGE_ID=$(sed -n "/${CC_NAME}_${CC_VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" installed.txt)
echo ""
echo "Package ID: $PACKAGE_ID"

# Approve for MROLab
echo ""
echo "Step 5: Approving chaincode for MROLab..."
export ORDERER_CA=$PWD/../organizations/ordererOrganizations/thermotrace.com/orderers/orderer1.thermotrace.com/msp/tlscacerts/tlsca.thermotrace.com-cert.pem

peer lifecycle chaincode approveformyorg \
  -o orderer1.thermotrace.com:7050 \
  --ordererTLSHostnameOverride orderer1.thermotrace.com \
  --channelID inspection-channel \
  --name ${CC_NAME} \
  --version ${CC_VERSION} \
  --package-id ${PACKAGE_ID} \
  --sequence ${CC_SEQUENCE} \
  --tls \
  --cafile ${ORDERER_CA}

echo "✓ Approved for MROLab"

# Approve for Manufacturer
echo ""
echo "Step 6: Approving chaincode for Manufacturer..."
export CORE_PEER_LOCALMSPID="ManufacturerMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/../organizations/peerOrganizations/manufacturer.thermotrace.com/peers/peer0.manufacturer.thermotrace.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=$PWD/../organizations/peerOrganizations/manufacturer.thermotrace.com/users/Admin@manufacturer.thermotrace.com/msp
export CORE_PEER_ADDRESS=peer0.manufacturer.thermotrace.com:9051

peer lifecycle chaincode approveformyorg \
  -o orderer1.thermotrace.com:7050 \
  --ordererTLSHostnameOverride orderer1.thermotrace.com \
  --channelID inspection-channel \
  --name ${CC_NAME} \
  --version ${CC_VERSION} \
  --package-id ${PACKAGE_ID} \
  --sequence ${CC_SEQUENCE} \
  --tls \
  --cafile ${ORDERER_CA}

echo "✓ Approved for Manufacturer"

# Check commit readiness
echo ""
echo "Step 7: Checking commit readiness..."
peer lifecycle chaincode checkcommitreadiness \
  --channelID inspection-channel \
  --name ${CC_NAME} \
  --version ${CC_VERSION} \
  --sequence ${CC_SEQUENCE} \
  --tls \
  --cafile ${ORDERER_CA} \
  --output json

# Commit chaincode definition
echo ""
echo "Step 8: Committing chaincode definition..."
peer lifecycle chaincode commit \
  -o orderer1.thermotrace.com:7050 \
  --ordererTLSHostnameOverride orderer1.thermotrace.com \
  --channelID inspection-channel \
  --name ${CC_NAME} \
  --version ${CC_VERSION} \
  --sequence ${CC_SEQUENCE} \
  --tls \
  --cafile ${ORDERER_CA} \
  --peerAddresses peer0.mrolab.thermotrace.com:7051 \
  --tlsRootCertFiles $PWD/../organizations/peerOrganizations/mrolab.thermotrace.com/peers/peer0.mrolab.thermotrace.com/tls/ca.crt \
  --peerAddresses peer0.manufacturer.thermotrace.com:9051 \
  --tlsRootCertFiles $PWD/../organizations/peerOrganizations/manufacturer.thermotrace.com/peers/peer0.manufacturer.thermotrace.com/tls/ca.crt

echo "✓ Chaincode committed"

# Query committed chaincode
echo ""
echo "Step 9: Verifying committed chaincode..."
peer lifecycle chaincode querycommitted --channelID inspection-channel --name ${CC_NAME}

echo ""
echo "=========================================="
echo "✓ Chaincode deployment complete!"
echo "=========================================="
