# ThermoTrace Production - System Architecture

## Table of Contents
1. [Overview](#overview)
2. [Current Setup: Local Simulation](#current-setup-local-simulation)
3. [Where Everything Is Stored](#where-everything-is-stored)
4. [How to Distribute Across Real Organizations](#how-to-distribute-across-real-organizations)
5. [Network Components](#network-components)
6. [Data Flow](#data-flow)

---

## Overview

You have built a **production-ready Hyperledger Fabric blockchain network** that is currently running **locally on one machine** but is designed to be **distributed across multiple organizations**.

### What You Have:
- ✅ Complete Fabric 2.5 blockchain network
- ✅ 2 Organizations (Manufacturer & MRO Lab)
- ✅ Private Data Collections for selective privacy
- ✅ Hyperledger Explorer for visualization
- ✅ All blocks stored on local disk

---

## Current Setup: Local Simulation

### **YES, everything is running locally on your machine**

```
Your Machine (localhost)
├── ManufacturerMSP Organization
│   ├── peer0.manufacturer.thermotrace.com (port 9051)
│   ├── CouchDB database (port 6984)
│   └── CA (Certificate Authority) if running
│
├── MROLabMSP Organization
│   ├── peer0.mrolab.thermotrace.com (port 7051)
│   ├── CouchDB database (port 5984)
│   └── CA (Certificate Authority) if running
│
├── Orderer Service (Raft consensus)
│   ├── orderer1.thermotrace.com (port 8051)
│   ├── orderer2.thermotrace.com (port 9051)
│   └── orderer3.thermotrace.com (port 10051)
│
└── Hyperledger Explorer
    ├── Web UI (port 8080)
    └── PostgreSQL database (port 5432)
```

**This is a SIMULATION** of a distributed network, but all components run on your single machine.

---

## Where Everything Is Stored

### 1. **Blockchain Blocks** (The Ledger)

Blocks are stored in **Docker volumes** on your local disk:

```bash
Physical Location:
/var/lib/docker/volumes/network_peer0.manufacturer.thermotrace.com/_data/ledgersData/chains/chains/inspection-channel/blockfile_000000

Size: ~270 KB (46 blocks)
```

**Each peer has its own copy:**
- Manufacturer Peer: `/var/lib/docker/volumes/network_peer0.manufacturer.thermotrace.com/_data/`
- MRO Lab Peer: `/var/lib/docker/volumes/network_peer0.mrolab.thermotrace.com/_data/`
- Orderer1: `/var/lib/docker/volumes/network_orderer1.thermotrace.com/_data/`
- Orderer2: `/var/lib/docker/volumes/network_orderer2.thermotrace.com/_data/`
- Orderer3: `/var/lib/docker/volumes/network_orderer3.thermotrace.com/_data/`

**Important:** Each peer and orderer maintains its own complete copy of the blockchain!

### 2. **State Database** (Current World State)

Stored in CouchDB containers:
- Manufacturer: `couchdb0-manufacturer` container
- MRO Lab: `couchdb0-mrolab` container

These contain the **current state** (latest values), not historical data.

### 3. **Private Data** (PDC Collections)

Stored separately from the public ledger:
```
/var/lib/docker/volumes/network_peer0.manufacturer.thermotrace.com/_data/ledgersData/pvtdataStore/
```

**Key Point:**
- Manufacturer peer has: `inspectionPrivateManufacturerCollection` data
- MRO Lab peer has: `inspectionPrivateMROLabCollection` data
- Public data is on both peers

### 4. **Cryptographic Material**

Your local filesystem:
```
/home/lp502261/thermotrace-production/organizations/
├── peerOrganizations/
│   ├── manufacturer.thermotrace.com/
│   │   ├── peers/
│   │   ├── users/
│   │   └── msp/
│   └── mrolab.thermotrace.com/
│       ├── peers/
│       ├── users/
│       └── msp/
└── ordererOrganizations/
    └── thermotrace.com/
```

**These are the digital identities** (certificates, private keys) for all organizations.

### 5. **Chaincode** (Smart Contracts)

Source code:
```
/home/lp502261/thermotrace-production/chaincode/blade-inspection/
```

Running instances (Docker containers):
```
dev-peer0.manufacturer.thermotrace.com-bladeinspection_1.9
dev-peer0.mrolab.thermotrace.com-bladeinspection_1.9
```

Each peer runs its own chaincode container!

### 6. **Explorer Database**

PostgreSQL container stores:
- Indexed blockchain data
- Transaction metadata
- User accounts

Volume: `blockchain-explorer` Docker volumes

---

## How to Distribute Across Real Organizations

### **YES, you can split this into a real distributed system!**

Here's how you would deploy to two separate organizations:

### Architecture: Distributed Setup

```
Organization 1: Manufacturer (Germany)
Server: manufacturer.thermotrace.com
├── peer0.manufacturer.thermotrace.com
├── couchdb0-manufacturer
└── orderer1.thermotrace.com (optional)

Organization 2: MRO Lab (USA)
Server: mrolab.thermotrace.com
├── peer0.mrolab.thermotrace.com
├── couchdb0-mrolab
└── orderer2.thermotrace.com (optional)

Neutral/Shared Orderer Service (Cloud/Third Party)
Server: orderer.thermotrace.com
├── orderer1.thermotrace.com
├── orderer2.thermotrace.com
└── orderer3.thermotrace.com
```

### Steps to Distribute:

#### **1. Infrastructure Setup**

**Manufacturer (Germany Server):**
- Install Docker on their server
- Copy only Manufacturer's files:
  ```bash
  organizations/peerOrganizations/manufacturer.thermotrace.com/
  docker-compose-manufacturer.yaml (create separate compose file)
  ```
- Open port 9051 for peer communication
- Configure firewall to allow connections from MRO Lab peer

**MRO Lab (USA Server):**
- Install Docker on their server
- Copy only MRO Lab's files:
  ```bash
  organizations/peerOrganizations/mrolab.thermotrace.com/
  docker-compose-mrolab.yaml (create separate compose file)
  ```
- Open port 7051 for peer communication
- Configure firewall to allow connections from Manufacturer peer

#### **2. Network Configuration**

Update `docker-compose.yaml` on each machine:

**Manufacturer's docker-compose.yaml:**
```yaml
services:
  peer0.manufacturer.thermotrace.com:
    environment:
      - CORE_PEER_ADDRESS=peer0.manufacturer.thermotrace.com:9051
      - CORE_PEER_GOSSIP_EXTERNALENDPOINT=manufacturer.thermotrace.com:9051  # Public IP/domain
      - CORE_PEER_GOSSIP_BOOTSTRAP=mrolab.thermotrace.com:7051  # MRO Lab's public address
    ports:
      - 9051:9051  # Exposed to internet
```

**MRO Lab's docker-compose.yaml:**
```yaml
services:
  peer0.mrolab.thermotrace.com:
    environment:
      - CORE_PEER_ADDRESS=peer0.mrolab.thermotrace.com:7051
      - CORE_PEER_GOSSIP_EXTERNALENDPOINT=mrolab.thermotrace.com:7051  # Public IP/domain
      - CORE_PEER_GOSSIP_BOOTSTRAP=manufacturer.thermotrace.com:9051  # Manufacturer's public address
    ports:
      - 7051:7051  # Exposed to internet
```

#### **3. DNS/IP Configuration**

Set up DNS records or update `/etc/hosts`:
- `manufacturer.thermotrace.com` → Manufacturer's public IP
- `mrolab.thermotrace.com` → MRO Lab's public IP
- `orderer1.thermotrace.com` → Orderer's public IP

#### **4. Security Considerations**

**Mutual TLS (mTLS):**
- Already configured! Each peer authenticates using certificates
- Only peers with valid certificates can join

**Firewall Rules:**
```bash
# Manufacturer Server
Allow TCP 9051 from mrolab.thermotrace.com (peer gossip)
Allow TCP 8051 from orderer1.thermotrace.com (orderer connection)

# MRO Lab Server
Allow TCP 7051 from manufacturer.thermotrace.com (peer gossip)
Allow TCP 8051 from orderer1.thermotrace.com (orderer connection)
```

**VPN (Optional but recommended):**
- Set up VPN between organizations
- All Fabric traffic goes through encrypted tunnel

#### **5. Access Control**

**What you can do:**

✅ **YES:** You can remove MRO Lab from your local machine entirely
- Give MRO Lab their cryptographic material:
  ```bash
  organizations/peerOrganizations/mrolab.thermotrace.com/
  ```
- Delete it from your machine
- MRO Lab runs their peer independently
- They can ONLY see:
  - Public inspection data
  - Their own private inspector names
  - NOT Manufacturer's private inspector names

✅ **YES:** MRO Lab can operate completely independently
- They don't need access to your server
- They run their own peer, CouchDB, and chaincode
- Blockchain synchronizes automatically

✅ **YES:** True organizational separation
- You keep: `organizations/peerOrganizations/manufacturer.thermotrace.com/`
- They get: `organizations/peerOrganizations/mrolab.thermotrace.com/`
- Neither can impersonate the other

#### **6. Testing the Distributed Setup**

**From Manufacturer's machine:**
```bash
peer channel list  # Should show: inspection-channel
peer chaincode query -C inspection-channel -n bladeinspection -c '{"Args":["GetAllInspections"]}'
```

**From MRO Lab's machine:**
```bash
peer channel list  # Should show: inspection-channel
peer chaincode query -C inspection-channel -n bladeinspection -c '{"Args":["GetAllInspections"]}'
```

Both should return the same public data, but different private data!

---

## Network Components

### **1. Peers** (Maintain ledger, execute chaincode)
- **peer0.manufacturer.thermotrace.com** (port 9051)
  - Holds: Full blockchain + Manufacturer's private data
  - Access: Only Manufacturer can read their private collections

- **peer0.mrolab.thermotrace.com** (port 7051)
  - Holds: Full blockchain + MRO Lab's private data
  - Access: Only MRO Lab can read their private collections

### **2. Orderers** (Order transactions, create blocks)
- **orderer1, orderer2, orderer3** (Raft consensus)
- Ports: 8051, 9051, 10051
- Function: Neutral service, doesn't see private data
- Can be hosted by third party or shared between orgs

### **3. CouchDB** (State database)
- **couchdb0-manufacturer** (port 6984)
- **couchdb0-mrolab** (port 5984)
- Stores: Current world state (latest values)
- Private data stored separately in peer's file system

### **4. Chaincode Containers**
- **dev-peer0.manufacturer.thermotrace.com-bladeinspection_1.9**
- **dev-peer0.mrolab.thermotrace.com-bladeinspection_1.9**
- Each peer runs its own instance
- Executes smart contract logic

### **5. Hyperledger Explorer**
- Web UI: http://localhost:8080
- Database: PostgreSQL
- Function: Reads blockchain and displays in UI
- Can be run by either org or both

---

## Data Flow

### **1. Adding an Inspection** (Write Transaction)

```
Client (Manufacturer)
    ↓
Submit Transaction: AddInspection(partNumber, serialNumber, inspector, ...)
    ↓
peer0.manufacturer.thermotrace.com (Endorsing Peer)
    ↓
Execute chaincode: Split data into public/private
    ↓
Return Endorsement (signed response)
    ↓
Client sends to Orderer
    ↓
orderer1.thermotrace.com
    ↓
Order transaction into a block
    ↓
Broadcast block to all peers
    ↓
├─→ peer0.manufacturer.thermotrace.com
│   ├─ Write public data to ledger
│   ├─ Write Manufacturer's private data to private store
│   └─ Commit block
│
└─→ peer0.mrolab.thermotrace.com
    ├─ Write public data to ledger
    ├─ Skip Manufacturer's private data (doesn't have permission)
    └─ Commit block
```

### **2. Reading an Inspection** (Query)

**Manufacturer queries:**
```
GetInspection("FINAL-TIC-1102")
    ↓
peer0.manufacturer.thermotrace.com
    ↓
├─ Read public data from ledger
├─ Read Manufacturer's private data
└─ Return: Full inspection (including inspector name)
```

**MRO Lab queries:**
```
GetInspection("FINAL-TIC-1102")
    ↓
peer0.mrolab.thermotrace.com
    ↓
├─ Read public data from ledger
├─ Try to read Manufacturer's private data → DENIED
└─ Return: Inspection WITHOUT inspector name (only measurements, part number, etc.)
```

### **3. Block Propagation** (Peer Gossip)

```
peer0.manufacturer.thermotrace.com
    ↕ (gossip protocol)
peer0.mrolab.thermotrace.com
```

Peers automatically synchronize:
- New blocks
- Missing blocks
- Public ledger data
- NOT private data (only hash is shared)

---

## Summary: Current vs Distributed

### **Current Setup (Local):**
```
✅ Everything on one machine
✅ All data in Docker volumes on your local disk
✅ Simulates distributed network
✅ Perfect for development and testing
✅ Blocks stored at: /var/lib/docker/volumes/
```

### **Production Setup (Distributed):**
```
✅ Each org on separate servers/cloud
✅ Each org controls their own peer and data
✅ Blockchain synchronized via Fabric gossip protocol
✅ Private data stays private
✅ True organizational separation
✅ Can revoke access by removing crypto material
```

### **Can you shift MRO Lab to another person?**

**YES! Here's how:**

1. **Package MRO Lab's files:**
   ```bash
   cd /home/lp502261/thermotrace-production
   tar -czf mrolab-deployment.tar.gz \
       organizations/peerOrganizations/mrolab.thermotrace.com/ \
       chaincode/ \
       network/configtx/ \
       docker-compose.yaml  # (create MRO Lab specific version)
   ```

2. **Send to MRO Lab person:**
   - Extract on their server
   - Run `docker-compose up -d`
   - Their peer automatically syncs all 46 blocks from network

3. **Remove from your machine:**
   ```bash
   # Stop MRO Lab peer locally
   docker stop peer0.mrolab.thermotrace.com couchdb0-mrolab

   # Remove crypto material (optional, for security)
   rm -rf organizations/peerOrganizations/mrolab.thermotrace.com/
   ```

4. **Network continues working:**
   - Manufacturer peer keeps running
   - MRO Lab peer now runs on their server
   - Orderers facilitate communication
   - Blockchain stays synchronized

---

## Key Insights

1. **Blocks are replicated:** Every peer has a full copy of the blockchain
2. **Private data is NOT replicated:** Only authorized peers store private collections
3. **Local storage:** Your Docker volumes contain everything
4. **Portable:** Entire network can be distributed across the globe
5. **Secure by design:** Cryptographic material controls access
6. **Production-ready:** This is real Hyperledger Fabric, not a simulation

---

## Next Steps to Distribute

If you want to test a real distributed setup:

1. Get a second machine (VM, cloud instance, or another physical server)
2. Install Docker on both
3. Split the docker-compose.yaml into two files
4. Configure network connectivity (IP addresses, DNS)
5. Start peers on separate machines
6. Watch them synchronize automatically!

**Your blockchain is ready for production deployment!** 🚀
