#!/bin/bash
set -e

echo "========================================"
echo "ThermoTrace Production Network Setup"
echo "========================================"

cd ~/thermotrace-production

# Use cryptogen instead of CAs for simplicity and reliability
echo ""
echo "Step 1: Generating crypto material with cryptogen..."

cat > network/crypto-config.yaml << 'CRYPTOEOF'
OrdererOrgs:
  - Name: Orderer
    Domain: thermotrace.com
    EnableNodeOUs: true
    Specs:
      - Hostname: orderer1
      - Hostname: orderer2
      - Hostname: orderer3

PeerOrgs:
  - Name: MROLab
    Domain: mrolab.thermotrace.com
    EnableNodeOUs: true
    Template:
      Count: 1
    Users:
      Count: 2

  - Name: Manufacturer
    Domain: manufacturer.thermotrace.com
    EnableNodeOUs: true
    Template:
      Count: 1
    Users:
      Count: 2
CRYPTOEOF

cryptogen generate --config=network/crypto-config.yaml --output=organizations

echo "✓ Crypto material generated"

# Move to proper structure
mv organizations/ordererOrganizations organizations_temp_orderer
mv organizations/peerOrganizations organizations_temp_peer
rm -rf organizations
mkdir -p organizations/ordererOrganizations
mkdir -p organizations/peerOrganizations
mv organizations_temp_orderer/thermotrace.com organizations/ordererOrganizations/
mv organizations_temp_peer/mrolab.thermotrace.com organizations/peerOrganizations/
mv organizations_temp_peer/manufacturer.thermotrace.com organizations/peerOrganizations/
rm -rf organizations_temp_*

echo ""
echo "Step 2: Creating configtx.yaml..."

cat > network/configtx.yaml << 'CONFIGEOF'
---
Organizations:
  - &OrdererOrg
      Name: OrdererOrg
      ID: OrdererMSP
      MSPDir: ../organizations/ordererOrganizations/thermotrace.com/msp
      Policies:
        Readers:
          Type: Signature
          Rule: "OR('OrdererMSP.member')"
        Writers:
          Type: Signature
          Rule: "OR('OrdererMSP.member')"
        Admins:
          Type: Signature
          Rule: "OR('OrdererMSP.admin')"
      OrdererEndpoints:
        - orderer1.thermotrace.com:7050
        - orderer2.thermotrace.com:8050
        - orderer3.thermotrace.com:9050

  - &MROLab
      Name: MROLabMSP
      ID: MROLabMSP
      MSPDir: ../organizations/peerOrganizations/mrolab.thermotrace.com/msp
      Policies:
        Readers:
          Type: Signature
          Rule: "OR('MROLabMSP.admin', 'MROLabMSP.peer', 'MROLabMSP.client')"
        Writers:
          Type: Signature
          Rule: "OR('MROLabMSP.admin', 'MROLabMSP.client')"
        Admins:
          Type: Signature
          Rule: "OR('MROLabMSP.admin')"
        Endorsement:
          Type: Signature
          Rule: "OR('MROLabMSP.peer')"
      AnchorPeers:
        - Host: peer0.mrolab.thermotrace.com
          Port: 7051

  - &Manufacturer
      Name: ManufacturerMSP
      ID: ManufacturerMSP
      MSPDir: ../organizations/peerOrganizations/manufacturer.thermotrace.com/msp
      Policies:
        Readers:
          Type: Signature
          Rule: "OR('ManufacturerMSP.admin', 'ManufacturerMSP.peer', 'ManufacturerMSP.client')"
        Writers:
          Type: Signature
          Rule: "OR('ManufacturerMSP.admin', 'ManufacturerMSP.client')"
        Admins:
          Type: Signature
          Rule: "OR('ManufacturerMSP.admin')"
        Endorsement:
          Type: Signature
          Rule: "OR('ManufacturerMSP.peer')"
      AnchorPeers:
        - Host: peer0.manufacturer.thermotrace.com
          Port: 9051

Capabilities:
  Channel: &ChannelCapabilities
    V2_0: true
  Orderer: &OrdererCapabilities
    V2_0: true
  Application: &ApplicationCapabilities
    V2_5: true

Application: &ApplicationDefaults
  Organizations:
  Policies:
    Readers:
      Type: ImplicitMeta
      Rule: "ANY Readers"
    Writers:
      Type: ImplicitMeta
      Rule: "ANY Writers"
    Admins:
      Type: ImplicitMeta
      Rule: "MAJORITY Admins"
    LifecycleEndorsement:
      Type: ImplicitMeta
      Rule: "MAJORITY Endorsement"
    Endorsement:
      Type: ImplicitMeta
      Rule: "MAJORITY Endorsement"
  Capabilities:
    <<: *ApplicationCapabilities

Orderer: &OrdererDefaults
  OrdererType: etcdraft
  Addresses:
    - orderer1.thermotrace.com:7050
    - orderer2.thermotrace.com:8050
    - orderer3.thermotrace.com:9050
  EtcdRaft:
    Consenters:
      - Host: orderer1.thermotrace.com
        Port: 7050
        ClientTLSCert: ../organizations/ordererOrganizations/thermotrace.com/orderers/orderer1.thermotrace.com/tls/server.crt
        ServerTLSCert: ../organizations/ordererOrganizations/thermotrace.com/orderers/orderer1.thermotrace.com/tls/server.crt
      - Host: orderer2.thermotrace.com
        Port: 8050
        ClientTLSCert: ../organizations/ordererOrganizations/thermotrace.com/orderers/orderer2.thermotrace.com/tls/server.crt
        ServerTLSCert: ../organizations/ordererOrganizations/thermotrace.com/orderers/orderer2.thermotrace.com/tls/server.crt
      - Host: orderer3.thermotrace.com
        Port: 9050
        ClientTLSCert: ../organizations/ordererOrganizations/thermotrace.com/orderers/orderer3.thermotrace.com/tls/server.crt
        ServerTLSCert: ../organizations/ordererOrganizations/thermotrace.com/orderers/orderer3.thermotrace.com/tls/server.crt
  BatchTimeout: 2s
  BatchSize:
    MaxMessageCount: 10
    AbsoluteMaxBytes: 99 MB
    PreferredMaxBytes: 512 KB
  Organizations:
  Policies:
    Readers:
      Type: ImplicitMeta
      Rule: "ANY Readers"
    Writers:
      Type: ImplicitMeta
      Rule: "ANY Writers"
    Admins:
      Type: ImplicitMeta
      Rule: "MAJORITY Admins"
    BlockValidation:
      Type: ImplicitMeta
      Rule: "ANY Writers"

Channel: &ChannelDefaults
  Policies:
    Readers:
      Type: ImplicitMeta
      Rule: "ANY Readers"
    Writers:
      Type: ImplicitMeta
      Rule: "ANY Writers"
    Admins:
      Type: ImplicitMeta
      Rule: "MAJORITY Admins"
  Capabilities:
    <<: *ChannelCapabilities

Profiles:
  ThreeNodeEtcdRaft:
    <<: *ChannelDefaults
    Orderer:
      <<: *OrdererDefaults
      Organizations:
        - *OrdererOrg
      Capabilities: *OrdererCapabilities
    Consortiums:
      ThermoTraceConsortium:
        Organizations:
          - *MROLab
          - *Manufacturer

  InspectionChannel:
    Consortium: ThermoTraceConsortium
    <<: *ChannelDefaults
    Application:
      <<: *ApplicationDefaults
      Organizations:
        - *MROLab
        - *Manufacturer
      Capabilities:
        <<: *ApplicationCapabilities
CONFIGEOF

echo "✓ configtx.yaml created"

echo ""
echo "Step 3: Generating channel artifacts..."
mkdir -p network/channel-artifacts

cd network
configtxgen -profile ThreeNodeEtcdRaft -channelID system-channel -outputBlock ./channel-artifacts/genesis.block
configtxgen -profile InspectionChannel -outputCreateChannelTx ./channel-artifacts/inspection-channel.tx -channelID inspection-channel

echo "✓ Genesis block and channel tx created"

echo ""
echo "========================================"
echo "✓ Setup complete!"
echo "========================================"
ls -lh channel-artifacts/
