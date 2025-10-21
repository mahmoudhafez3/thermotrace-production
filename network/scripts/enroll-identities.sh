
#!/bin/bash

# Color output for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  ThermoTrace Identity Enrollment${NC}"
echo -e "${GREEN}========================================${NC}\n"

# Set fabric-ca-client binary path
export PATH=$HOME/thermotrace-production/bin:$PATH
export FABRIC_CA_CLIENT_HOME=$HOME/thermotrace-production/network/organizations

# Create organizations directory structure
mkdir -p $FABRIC_CA_CLIENT_HOME/peerOrganizations/mrolab.thermotrace.com
mkdir -p $FABRIC_CA_CLIENT_HOME/peerOrganizations/manufacturer.thermotrace.com
mkdir -p $FABRIC_CA_CLIENT_HOME/ordererOrganizations/thermotrace.com

#############################################
# Enroll MRO Lab Organization
#############################################
echo -e "${YELLOW}>>> Enrolling MRO Lab identities...${NC}"

export FABRIC_CA_CLIENT_HOME=$FABRIC_CA_CLIENT_HOME/peerOrganizations/mrolab.thermotrace.com

# Enroll CA admin
fabric-ca-client enroll -u https://admin:adminpw@localhost:7054 --caname ca-mrolab --tls.certfiles $HOME/thermotrace-production/network/organizations/fabric-ca/mrolab/tls-cert.pem

# Register peer0
fabric-ca-client register --caname ca-mrolab --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles $HOME/thermotrace-production/network/organizations/fabric-ca/mrolab/tls-cert.pem

# Register org admin
fabric-ca-client register --caname ca-mrolab --id.name mrolabadmin --id.secret mrolabadminpw --id.type admin --tls.certfiles $HOME/thermotrace-production/network/organizations/fabric-ca/mrolab/tls-cert.pem

# Register inspector user (inspector-level identity)
fabric-ca-client register --caname ca-mrolab --id.name inspector1 --id.secret inspector1pw --id.type client --tls.certfiles $HOME/thermotrace-production/network/organizations/fabric-ca/mrolab/tls-cert.pem

# Enroll peer0
fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca-mrolab -M $FABRIC_CA_CLIENT_HOME/peers/peer0.mrolab.thermotrace.com/msp --tls.certfiles $HOME/thermotrace-production/network/organizations/fabric-ca/mrolab/tls-cert.pem

# Enroll peer0 TLS
fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca-mrolab -M $FABRIC_CA_CLIENT_HOME/peers/peer0.mrolab.thermotrace.com/tls --enrollment.profile tls --csr.hosts peer0.mrolab.thermotrace.com --tls.certfiles $HOME/thermotrace-production/network/organizations/fabric-ca/mrolab/tls-cert.pem

# Copy TLS key (Fabric expects specific naming)
cp $FABRIC_CA_CLIENT_HOME/peers/peer0.mrolab.thermotrace.com/tls/keystore/* $FABRIC_CA_CLIENT_HOME/peers/peer0.mrolab.thermotrace.com/tls/server.key

# Enroll org admin
fabric-ca-client enroll -u https://mrolabadmin:mrolabadminpw@localhost:7054 --caname ca-mrolab -M $FABRIC_CA_CLIENT_HOME/users/Admin@mrolab.thermotrace.com/msp --tls.certfiles $HOME/thermotrace-production/network/organizations/fabric-ca/mrolab/tls-cert.pem

# Enroll inspector1 user
fabric-ca-client enroll -u https://inspector1:inspector1pw@localhost:7054 --caname ca-mrolab -M $FABRIC_CA_CLIENT_HOME/users/Inspector1@mrolab.thermotrace.com/msp --tls.certfiles $HOME/thermotrace-production/network/organizations/fabric-ca/mrolab/tls-cert.pem

# Copy MSP config files
cp $FABRIC_CA_CLIENT_HOME/msp/config.yaml $FABRIC_CA_CLIENT_HOME/peers/peer0.mrolab.thermotrace.com/msp/config.yaml
cp $FABRIC_CA_CLIENT_HOME/msp/config.yaml $FABRIC_CA_CLIENT_HOME/users/Admin@mrolab.thermotrace.com/msp/config.yaml
cp $FABRIC_CA_CLIENT_HOME/msp/config.yaml $FABRIC_CA_CLIENT_HOME/users/Inspector1@mrolab.thermotrace.com/msp/config.yaml

echo -e "${GREEN}✓ MRO Lab identities enrolled${NC}\n"

#############################################
# Enroll Manufacturer Organization
#############################################
echo -e "${YELLOW}>>> Enrolling Manufacturer identities...${NC}"

export FABRIC_CA_CLIENT_HOME=$HOME/thermotrace-production/network/organizations/peerOrganizations/manufacturer.thermotrace.com

# Enroll CA admin
fabric-ca-client enroll -u https://admin:adminpw@localhost:8054 --caname ca-manufacturer --tls.certfiles $HOME/thermotrace-production/network/organizations/fabric-ca/manufacturer/tls-cert.pem

# Register peer0
fabric-ca-client register --caname ca-manufacturer --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles $HOME/thermotrace-production/network/organizations/fabric-ca/manufacturer/tls-cert.pem

# Register org admin
fabric-ca-client register --caname ca-manufacturer --id.name mfgadmin --id.secret mfgadminpw --id.type admin --tls.certfiles $HOME/thermotrace-production/network/organizations/fabric-ca/manufacturer/tls-cert.pem

# Register quality engineer user (inspector-level identity)
fabric-ca-client register --caname ca-manufacturer --id.name qe1 --id.secret qe1pw --id.type client --tls.certfiles $HOME/thermotrace-production/network/organizations/fabric-ca/manufacturer/tls-cert.pem

# Enroll peer0
fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca-manufacturer -M $FABRIC_CA_CLIENT_HOME/peers/peer0.manufacturer.thermotrace.com/msp --tls.certfiles $HOME/thermotrace-production/network/organizations/fabric-ca/manufacturer/tls-cert.pem

# Enroll peer0 TLS
fabric-ca-client enroll -u https://peer0:peer0pw@localhost:8054 --caname ca-manufacturer -M $FABRIC_CA_CLIENT_HOME/peers/peer0.manufacturer.thermotrace.com/tls --enrollment.profile tls --csr.hosts peer0.manufacturer.thermotrace.com --tls.certfiles $HOME/thermotrace-production/network/organizations/fabric-ca/manufacturer/tls-cert.pem

# Copy TLS key
cp $FABRIC_CA_CLIENT_HOME/peers/peer0.manufacturer.thermotrace.com/tls/keystore/* $FABRIC_CA_CLIENT_HOME/peers/peer0.manufacturer.thermotrace.com/tls/server.key

# Enroll org admin
fabric-ca-client enroll -u https://mfgadmin:mfgadminpw@localhost:8054 --caname ca-manufacturer -M $FABRIC_CA_CLIENT_HOME/users/Admin@manufacturer.thermotrace.com/msp --tls.certfiles $HOME/thermotrace-production/network/organizations/fabric-ca/manufacturer/tls-cert.pem

# Enroll qe1 user
fabric-ca-client enroll -u https://qe1:qe1pw@localhost:8054 --caname ca-manufacturer -M $FABRIC_CA_CLIENT_HOME/users/QE1@manufacturer.thermotrace.com/msp --tls.certfiles $HOME/thermotrace-production/network/organizations/fabric-ca/manufacturer/tls-cert.pem

# Copy MSP config files
cp $FABRIC_CA_CLIENT_HOME/msp/config.yaml $FABRIC_CA_CLIENT_HOME/peers/peer0.manufacturer.thermotrace.com/msp/config.yaml
cp $FABRIC_CA_CLIENT_HOME/msp/config.yaml $FABRIC_CA_CLIENT_HOME/users/Admin@manufacturer.thermotrace.com/msp/config.yaml
cp $FABRIC_CA_CLIENT_HOME/msp/config.yaml $FABRIC_CA_CLIENT_HOME/users/QE1@manufacturer.thermotrace.com/msp/config.yaml

echo -e "${GREEN}✓ Manufacturer identities enrolled${NC}\n"

#############################################
# Enroll Orderer Organization
#############################################
echo -e "${YELLOW}>>> Enrolling Orderer identities (3 nodes)...${NC}"

export FABRIC_CA_CLIENT_HOME=$HOME/thermotrace-production/network/organizations/ordererOrganizations/thermotrace.com

# Enroll CA admin
fabric-ca-client enroll -u https://admin:adminpw@localhost:9054 --caname ca-orderer --tls.certfiles $HOME/thermotrace-production/network/organizations/fabric-ca/orderer/tls-cert.pem

# Register orderer1, orderer2, orderer3
fabric-ca-client register --caname ca-orderer --id.name orderer1 --id.secret orderer1pw --id.type orderer --tls.certfiles $HOME/thermotrace-production/network/organizations/fabric-ca/orderer/tls-cert.pem
fabric-ca-client register --caname ca-orderer --id.name orderer2 --id.secret orderer2pw --id.type orderer --tls.certfiles $HOME/thermotrace-production/network/organizations/fabric-ca/orderer/tls-cert.pem
fabric-ca-client register --caname ca-orderer --id.name orderer3 --id.secret orderer3pw --id.type orderer --tls.certfiles $HOME/thermotrace-production/network/organizations/fabric-ca/orderer/tls-cert.pem

# Register orderer admin
fabric-ca-client register --caname ca-orderer --id.name ordereradmin --id.secret ordereradminpw --id.type admin --tls.certfiles $HOME/thermotrace-production/network/organizations/fabric-ca/orderer/tls-cert.pem

# Enroll orderer1
fabric-ca-client enroll -u https://orderer1:orderer1pw@localhost:9054 --caname ca-orderer -M $FABRIC_CA_CLIENT_HOME/orderers/orderer1.thermotrace.com/msp --tls.certfiles $HOME/thermotrace-production/network/organizations/fabric-ca/orderer/tls-cert.pem

fabric-ca-client enroll -u https://orderer1:orderer1pw@localhost:9054 --caname ca-orderer -M $FABRIC_CA_CLIENT_HOME/orderers/orderer1.thermotrace.com/tls --enrollment.profile tls --csr.hosts orderer1.thermotrace.com --tls.certfiles $HOME/thermotrace-production/network/organizations/fabric-ca/orderer/tls-cert.pem

cp $FABRIC_CA_CLIENT_HOME/orderers/orderer1.thermotrace.com/tls/keystore/* $FABRIC_CA_CLIENT_HOME/orderers/orderer1.thermotrace.com/tls/server.key

# Enroll orderer2
fabric-ca-client enroll -u https://orderer2:orderer2pw@localhost:9054 --caname ca-orderer -M $FABRIC_CA_CLIENT_HOME/orderers/orderer2.thermotrace.com/msp --tls.certfiles $HOME/thermotrace-production/network/organizations/fabric-ca/orderer/tls-cert.pem

fabric-ca-client enroll -u https://orderer2:orderer2pw@localhost:9054 --caname ca-orderer -M $FABRIC_CA_CLIENT_HOME/orderers/orderer2.thermotrace.com/tls --enrollment.profile tls --csr.hosts orderer2.thermotrace.com --tls.certfiles $HOME/thermotrace-production/network/organizations/fabric-ca/orderer/tls-cert.pem

cp $FABRIC_CA_CLIENT_HOME/orderers/orderer2.thermotrace.com/tls/keystore/* $FABRIC_CA_CLIENT_HOME/orderers/orderer2.thermotrace.com/tls/server.key

# Enroll orderer3
fabric-ca-client enroll -u https://orderer3:orderer3pw@localhost:9054 --caname ca-orderer -M $FABRIC_CA_CLIENT_HOME/orderers/orderer3.thermotrace.com/msp --tls.certfiles $HOME/thermotrace-production/network/organizations/fabric-ca/orderer/tls-cert.pem

fabric-ca-client enroll -u https://orderer3:orderer3pw@localhost:9054 --caname ca-orderer -M $FABRIC_CA_CLIENT_HOME/orderers/orderer3.thermotrace.com/tls --enrollment.profile tls --csr.hosts orderer3.thermotrace.com --tls.certfiles $HOME/thermotrace-production/network/organizations/fabric-ca/orderer/tls-cert.pem

cp $FABRIC_CA_CLIENT_HOME/orderers/orderer3.thermotrace.com/tls/keystore/* $FABRIC_CA_CLIENT_HOME/orderers/orderer3.thermotrace.com/tls/server.key

# Enroll orderer admin
fabric-ca-client enroll -u https://ordereradmin:ordereradminpw@localhost:9054 --caname ca-orderer -M $FABRIC_CA_CLIENT_HOME/users/Admin@thermotrace.com/msp --tls.certfiles $HOME/thermotrace-production/network/organizations/fabric-ca/orderer/tls-cert.pem

# Copy MSP config files
cp $FABRIC_CA_CLIENT_HOME/msp/config.yaml $FABRIC_CA_CLIENT_HOME/orderers/orderer1.thermotrace.com/msp/config.yaml
cp $FABRIC_CA_CLIENT_HOME/msp/config.yaml $FABRIC_CA_CLIENT_HOME/orderers/orderer2.thermotrace.com/msp/config.yaml
cp $FABRIC_CA_CLIENT_HOME/msp/config.yaml $FABRIC_CA_CLIENT_HOME/orderers/orderer3.thermotrace.com/msp/config.yaml
cp $FABRIC_CA_CLIENT_HOME/msp/config.yaml $FABRIC_CA_CLIENT_HOME/users/Admin@thermotrace.com/msp/config.yaml

echo -e "${GREEN}✓ Orderer identities enrolled (3 nodes)${NC}\n"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  ✓ All identities created successfully${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "\nIdentities created:"
echo "  MRO Lab: Admin, Inspector1, peer0"
echo "  Manufacturer: Admin, QE1, peer0"
echo "  Orderer: Admin, orderer1, orderer2, orderer3"
