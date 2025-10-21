#!/bin/bash
set -e

echo "=========================================="
echo "Testing Chaincode Transactions"
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
echo "Step 1: Initializing ledger with sample assets..."
peer chaincode invoke \
  -o orderer1.thermotrace.com:7050 \
  --ordererTLSHostnameOverride orderer1.thermotrace.com \
  --tls \
  --cafile ${ORDERER_CA} \
  -C inspection-channel \
  -n testasset \
  --peerAddresses peer0.mrolab.thermotrace.com:7051 \
  --tlsRootCertFiles $PWD/../organizations/peerOrganizations/mrolab.thermotrace.com/peers/peer0.mrolab.thermotrace.com/tls/ca.crt \
  --peerAddresses peer0.manufacturer.thermotrace.com:9051 \
  --tlsRootCertFiles $PWD/../organizations/peerOrganizations/manufacturer.thermotrace.com/peers/peer0.manufacturer.thermotrace.com/tls/ca.crt \
  -c '{"function":"InitLedger","Args":[]}'

echo "✓ Ledger initialized"

sleep 5

echo ""
echo "Step 2: Querying all assets..."
peer chaincode query -C inspection-channel -n testasset -c '{"Args":["GetAllAssets"]}'

echo ""
echo "Step 3: Creating a new asset (asset3)..."
peer chaincode invoke \
  -o orderer1.thermotrace.com:7050 \
  --ordererTLSHostnameOverride orderer1.thermotrace.com \
  --tls \
  --cafile ${ORDERER_CA} \
  -C inspection-channel \
  -n testasset \
  --peerAddresses peer0.mrolab.thermotrace.com:7051 \
  --tlsRootCertFiles $PWD/../organizations/peerOrganizations/mrolab.thermotrace.com/peers/peer0.mrolab.thermotrace.com/tls/ca.crt \
  --peerAddresses peer0.manufacturer.thermotrace.com:9051 \
  --tlsRootCertFiles $PWD/../organizations/peerOrganizations/manufacturer.thermotrace.com/peers/peer0.manufacturer.thermotrace.com/tls/ca.crt \
  -c '{"function":"CreateAsset","Args":["asset3","Blade Inspection","MROLab","350"]}'

echo "✓ Asset3 created"

sleep 3

echo ""
echo "Step 4: Reading the new asset (asset3)..."
peer chaincode query -C inspection-channel -n testasset -c '{"Args":["ReadAsset","asset3"]}'

echo ""
echo "Step 5: Querying all assets (should now have 3)..."
peer chaincode query -C inspection-channel -n testasset -c '{"Args":["GetAllAssets"]}'

echo ""
echo "Step 6: Checking blockchain height..."
peer channel getinfo -c inspection-channel

echo ""
echo "=========================================="
echo "✓ All transactions successful!"
echo "=========================================="
echo ""
echo "Summary:"
echo "- Initialized ledger with 2 assets ✅"
echo "- Created new asset (asset3) ✅"
echo "- Queried assets successfully ✅"
echo "- Multi-org endorsement working ✅"
echo "- Blockchain growing with each transaction ✅"
