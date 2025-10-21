#!/bin/bash
set -e

echo "=========================================="
echo "Creating inspection-channel"
echo "=========================================="

export PATH=$HOME/thermotrace-production/bin:$PATH
export FABRIC_CFG_PATH=$PWD/../config

# Set environment for MROLab peer
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="MROLabMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/../organizations/peerOrganizations/mrolab.thermotrace.com/peers/peer0.mrolab.thermotrace.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=$PWD/../organizations/peerOrganizations/mrolab.thermotrace.com/users/Admin@mrolab.thermotrace.com/msp
export CORE_PEER_ADDRESS=peer0.mrolab.thermotrace.com:7051

export ORDERER_CA=$PWD/../organizations/ordererOrganizations/thermotrace.com/orderers/orderer1.thermotrace.com/msp/tlscacerts/tlsca.thermotrace.com-cert.pem

echo ""
echo "Step 1: Creating application channel from channel transaction..."
peer channel create \
  -o orderer1.thermotrace.com:7050 \
  -c inspection-channel \
  -f ./channel-artifacts/inspection-channel.tx \
  --outputBlock ./channel-artifacts/inspection-channel.block \
  --tls \
  --cafile "$ORDERER_CA"

echo "✓ Channel block created: inspection-channel.block"

echo ""
echo "Step 2: Joining MROLab peer to channel..."
peer channel join -b ./channel-artifacts/inspection-channel.block

echo "✓ MROLab peer joined"

# Set environment for Manufacturer peer
export CORE_PEER_LOCALMSPID="ManufacturerMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/../organizations/peerOrganizations/manufacturer.thermotrace.com/peers/peer0.manufacturer.thermotrace.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=$PWD/../organizations/peerOrganizations/manufacturer.thermotrace.com/users/Admin@manufacturer.thermotrace.com/msp
export CORE_PEER_ADDRESS=peer0.manufacturer.thermotrace.com:9051

echo ""
echo "Step 3: Joining Manufacturer peer to channel..."
peer channel join -b ./channel-artifacts/inspection-channel.block

echo "✓ Manufacturer peer joined"

echo ""
echo "=========================================="
echo "✓ Channel creation complete!"
echo "=========================================="

# Verify channel membership
echo ""
echo "Verifying channel membership..."
echo ""
echo "MROLab peer channels:"
export CORE_PEER_LOCALMSPID="MROLabMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/../organizations/peerOrganizations/mrolab.thermotrace.com/peers/peer0.mrolab.thermotrace.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=$PWD/../organizations/peerOrganizations/mrolab.thermotrace.com/users/Admin@mrolab.thermotrace.com/msp
export CORE_PEER_ADDRESS=peer0.mrolab.thermotrace.com:7051
peer channel list

echo ""
echo "Manufacturer peer channels:"
export CORE_PEER_LOCALMSPID="ManufacturerMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/../organizations/peerOrganizations/manufacturer.thermotrace.com/peers/peer0.manufacturer.thermotrace.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=$PWD/../organizations/peerOrganizations/manufacturer.thermotrace.com/users/Admin@manufacturer.thermotrace.com/msp
export CORE_PEER_ADDRESS=peer0.manufacturer.thermotrace.com:9051
peer channel list

echo ""
echo "Channel info from MROLab peer:"
export CORE_PEER_LOCALMSPID="MROLabMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/../organizations/peerOrganizations/mrolab.thermotrace.com/peers/peer0.mrolab.thermotrace.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=$PWD/../organizations/peerOrganizations/mrolab.thermotrace.com/users/Admin@mrolab.thermotrace.com/msp
export CORE_PEER_ADDRESS=peer0.mrolab.thermotrace.com:7051
peer channel getinfo -c inspection-channel
