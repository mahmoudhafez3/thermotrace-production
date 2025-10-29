# ThermoTrace Network - Startup & Deployment Guide

## Quick Start Commands

### **Start the Network**
```bash
cd /home/lp502261/thermotrace-production
docker compose -f network/docker-compose-network.yaml up -d
```

### **Stop the Network**
```bash
docker compose -f network/docker-compose-network.yaml down
```

### **Restart the Network**
```bash
docker compose -f network/docker-compose-network.yaml restart
```

### **Check Network Status**
```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "peer|orderer|couchdb"
```

### **Start Hyperledger Explorer** (Optional - for visualization)
```bash
cd /home/lp502261/thermotrace-production/blockchain-explorer
docker compose up -d
```
Access at: http://localhost:8080 (exploreradmin / exploreradminpw)

---

## Problem: Network Goes Down When Laptop Shuts Down

### **Why This Happens:**
Your network runs in Docker containers on your laptop. When you shut down the laptop, Docker stops, and all containers stop.

### **Solutions:**

---

## Solution 1: Deploy to a Cloud Server (Recommended for Production)

This keeps your network running 24/7 without needing your laptop on.

### **Best Cloud Providers:**

#### **Option A: AWS (Amazon Web Services)**
- **Service:** EC2 (Elastic Compute Cloud)
- **Recommended Instance:** t3.medium or t3.large
- **Cost:** ~$30-60/month (24/7)
- **Steps:**
  1. Create AWS account
  2. Launch Ubuntu 22.04 EC2 instance
  3. Install Docker on EC2
  4. Transfer your ThermoTrace folder
  5. Run: `docker compose -f network/docker-compose-network.yaml up -d`
  6. Network stays up 24/7!

**Setup Guide:**
```bash
# On AWS EC2 instance (SSH into it):
sudo apt update
sudo apt install -y docker.io docker-compose
sudo usermod -aG docker $USER
newgrp docker

# Transfer your files (from your laptop):
scp -r /home/lp502261/thermotrace-production ubuntu@<EC2-IP>:/home/ubuntu/

# On EC2, start network:
cd thermotrace-production
docker compose -f network/docker-compose-network.yaml up -d
```

#### **Option B: Google Cloud Platform (GCP)**
- **Service:** Compute Engine
- **Recommended:** e2-medium VM
- **Cost:** ~$25-50/month
- **Similar steps to AWS**

#### **Option C: Microsoft Azure**
- **Service:** Azure Virtual Machines
- **Recommended:** B2s or B2ms
- **Cost:** ~$30-70/month

#### **Option D: DigitalOcean (Easiest for beginners)**
- **Service:** Droplets
- **Recommended:** 4 GB / 2 CPU droplet
- **Cost:** ~$24/month
- **Very simple interface!**

---

## Solution 2: Deploy to a Local Server

Buy a small dedicated server that runs 24/7.

### **Option A: Raspberry Pi (Budget Option)**
- **Cost:** ~$100 one-time
- **Pros:** Low power, runs 24/7, cheap
- **Cons:** Less powerful, may be slow with heavy load
- **Recommended:** Raspberry Pi 5 (8GB RAM)

### **Option B: Mini PC / NUC**
- **Cost:** ~$300-500 one-time
- **Pros:** More powerful, runs 24/7
- **Cons:** Higher initial cost
- **Recommended:** Intel NUC or similar

### **Setup:**
```bash
# Install Ubuntu Server on the device
# Install Docker
sudo apt update
sudo apt install -y docker.io docker-compose

# Copy your ThermoTrace folder
# Start network
docker compose -f network/docker-compose-network.yaml up -d

# Enable Docker to start on boot
sudo systemctl enable docker
```

---

## Solution 3: Keep Laptop Running (Not Recommended)

Configure your laptop to never sleep and keep network running.

**Ubuntu/Linux:**
```bash
# Prevent laptop from sleeping when lid closed
sudo nano /etc/systemd/logind.conf

# Change these lines:
HandleLidSwitch=ignore
HandleLidSwitchDocked=ignore

# Restart service
sudo systemctl restart systemd-logind

# Enable Docker to start on boot
sudo systemctl enable docker

# Auto-start network on boot
sudo crontab -e
# Add this line:
@reboot cd /home/lp502261/thermotrace-production && docker compose -f network/docker-compose-network.yaml up -d
```

**Cons:**
- Laptop gets hot running 24/7
- Wastes electricity
- Laptop battery degrades
- Not reliable (power outages, crashes)

---

## Recommended Architecture for Production

### **Scenario 1: Single Organization Testing**
```
Your Cloud Server (AWS/GCP/Azure)
├── Both organizations (Manufacturer + MRO Lab)
├── 3 Orderers
├── Running 24/7
└── Cost: ~$30-60/month
```

**Good for:** Testing, development, single company controlling everything

---

### **Scenario 2: True Distributed Multi-Org Production**
```
Manufacturer's Cloud Server          |  MRO Lab's Cloud Server
(AWS Frankfurt)                       |  (AWS Virginia)
├── peer0.manufacturer                |  ├── peer0.mrolab
├── couchdb0-manufacturer             |  ├── couchdb0-mrolab
└── orderer1 (optional)               |  └── orderer2 (optional)
                                      |
           Connected via Internet     |
                                      |
Third-Party Orderer Service           |
(Neutral cloud server)                |
├── orderer1.thermotrace.com          |
├── orderer2.thermotrace.com          |
└── orderer3.thermotrace.com          |
```

**Good for:** Real multi-organization setup, maximum decentralization

**Costs:**
- Manufacturer's server: ~$30-50/month
- MRO Lab's server: ~$30-50/month
- Orderer service: ~$30-50/month
- **Total:** ~$90-150/month

---

## Answer: Will Blocks Be Stored on MRO Lab's Laptop?

### **YES! Here's exactly what happens:**

### **Initial State (Before Transfer):**
```
Your Laptop (All 46 blocks):
├── Manufacturer peer: blocks 0-45 (270 KB)
├── MRO Lab peer: blocks 0-45 (270 KB)
└── Orderers: blocks 0-45 (270 KB each)

Total: 5 complete copies of blockchain on YOUR machine
```

### **After Transfer to MRO Lab Person:**

#### **Step 1: MRO Lab Sets Up Their Server**
```bash
# On MRO Lab's laptop/server:
cd /home/mrolab-user/thermotrace
docker compose -f docker-compose-mrolab.yaml up -d
```

#### **Step 2: Initial Sync - Blockchain Downloads Automatically**
```
MRO Lab's Machine (empty)
├── peer0.mrolab starts
├── Connects to network via orderers
├── Discovers other peers
└── Downloads ALL 46 blocks from network
    Time: ~1-5 seconds (blocks are small)
```

**After sync:**
```
MRO Lab's Laptop:
├── peer0.mrolab.thermotrace.com
├── Full blockchain: blocks 0-45 (270 KB)
├── Private data: Only MRO Lab's private collections
└── Running independently!
```

### **Step 3: Remove from Your Laptop (Optional)**
```bash
# On your laptop:
docker stop peer0.mrolab.thermotrace.com couchdb0-mrolab
docker rm peer0.mrolab.thermotrace.com couchdb0-mrolab

# Optional: Delete their crypto material for security
rm -rf organizations/peerOrganizations/mrolab.thermotrace.com/
```

**After removal:**
```
Your Laptop:
├── Manufacturer peer: blocks 0-45
├── Orderers: blocks 0-45
└── NO MRO Lab peer (they run it themselves now)

MRO Lab's Laptop:
├── MRO Lab peer: blocks 0-45
└── Connected to your orderers via internet
```

---

## Key Points About Block Storage When Distributed:

### **1. Automatic Synchronization**
- When MRO Lab starts their peer, it automatically downloads all blocks from the network
- Uses Fabric's "gossip protocol" - peers share blocks with each other
- No manual copying needed!

### **2. Each Peer Has Full Blockchain**
- MRO Lab's peer: **Full copy of all blocks** (270 KB currently, grows over time)
- Your peer: **Full copy of all blocks**
- Orderers: **Full copy of all blocks**

**This is blockchain's core feature:** Every participant has complete transaction history!

### **3. Private Data Stays Separate**
```
MRO Lab's Storage:
├── Blocks (public): All 46 blocks ✅
│   ├── Block 0: Genesis
│   ├── Block 1: Channel creation
│   ├── ...
│   └── Block 45: Latest transaction
│
├── Private Data:
│   ├── Their private collections: ✅ FULL DATA
│   └── Manufacturer's private collections: ❌ ONLY HASH (can't read)
```

### **4. Future Blocks Sync Automatically**
```
You create Block 47:
    ↓
Your peer creates block
    ↓
Orderer distributes to network
    ↓
MRO Lab's peer downloads block 47 automatically
    ↓
Both peers now have blocks 0-47
```

**Time to sync:** Usually 1-3 seconds!

### **5. Storage Requirements**

**Current:**
- 46 blocks = 270 KB
- Tiny! Fits on any device

**Future Growth:**
- Estimate: ~6 KB per block
- 1000 blocks ≈ 6 MB
- 10,000 blocks ≈ 60 MB
- 100,000 blocks ≈ 600 MB

**Even with 100,000 inspections, storage is minimal!**

### **6. What if MRO Lab's Server Goes Offline?**

```
Scenario: MRO Lab shuts down their server for maintenance

Your Network:
├── Manufacturer peer: ✅ Still running
├── Orderers: ✅ Still running
├── MRO Lab peer: ❌ Offline
└── Network continues! New blocks created

When MRO Lab comes back online:
├── Peer starts up
├── Detects it's behind (missing blocks 47-50)
├── Automatically downloads missing blocks from your peer
└── Back in sync in seconds!
```

**Blockchain is resilient!** Network continues as long as at least one peer and orderers are online.

---

## Complete Deployment Example: Transferring MRO Lab

### **Preparation (You do this):**

1. **Create MRO Lab deployment package:**
```bash
cd /home/lp502261/thermotrace-production

# Create directory structure
mkdir -p mrolab-deployment/organizations/peerOrganizations
mkdir -p mrolab-deployment/chaincode

# Copy MRO Lab's crypto material
cp -r organizations/peerOrganizations/mrolab.thermotrace.com/ \
      mrolab-deployment/organizations/peerOrganizations/

# Copy chaincode
cp -r chaincode/blade-inspection/ mrolab-deployment/chaincode/

# Create MRO Lab specific docker-compose
cat > mrolab-deployment/docker-compose.yaml << 'EOF'
version: '3.7'

services:
  couchdb0-mrolab:
    container_name: couchdb0-mrolab
    image: couchdb:3.3.2
    environment:
      - COUCHDB_USER=admin
      - COUCHDB_PASSWORD=adminpw
    ports:
      - 5984:5984
    networks:
      - thermotrace

  peer0.mrolab.thermotrace.com:
    container_name: peer0.mrolab.thermotrace.com
    image: hyperledger/fabric-peer:2.5.14
    environment:
      # Peer settings
      - CORE_PEER_ID=peer0.mrolab.thermotrace.com
      - CORE_PEER_ADDRESS=peer0.mrolab.thermotrace.com:7051
      - CORE_PEER_LISTENADDRESS=0.0.0.0:7051
      - CORE_PEER_CHAINCODEADDRESS=peer0.mrolab.thermotrace.com:7052
      - CORE_PEER_CHAINCODELISTENADDRESS=0.0.0.0:7052

      # MSP
      - CORE_PEER_LOCALMSPID=MROLabMSP
      - CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/msp

      # Gossip - CHANGE THESE TO REAL IPs/DOMAINS
      - CORE_PEER_GOSSIP_BOOTSTRAP=<MANUFACTURER_IP>:9051
      - CORE_PEER_GOSSIP_EXTERNALENDPOINT=<YOUR_PUBLIC_IP>:7051

      # TLS
      - CORE_PEER_TLS_ENABLED=true
      - CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/fabric/tls/server.crt
      - CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/fabric/tls/server.key
      - CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/tls/ca.crt

      # CouchDB
      - CORE_LEDGER_STATE_STATEDATABASE=CouchDB
      - CORE_LEDGER_STATE_COUCHDBCONFIG_COUCHDBADDRESS=couchdb0-mrolab:5984
      - CORE_LEDGER_STATE_COUCHDBCONFIG_USERNAME=admin
      - CORE_LEDGER_STATE_COUCHDBCONFIG_PASSWORD=adminpw

    working_dir: /opt/gopath/src/github.com/hyperledger/fabric/peer
    command: peer node start
    volumes:
      - ./organizations/peerOrganizations/mrolab.thermotrace.com/peers/peer0.mrolab.thermotrace.com/msp:/etc/hyperledger/fabric/msp
      - ./organizations/peerOrganizations/mrolab.thermotrace.com/peers/peer0.mrolab.thermotrace.com/tls:/etc/hyperledger/fabric/tls
      - peer0.mrolab.thermotrace.com:/var/hyperledger/production
    ports:
      - 7051:7051
    depends_on:
      - couchdb0-mrolab
    networks:
      - thermotrace

networks:
  thermotrace:
    name: thermotrace_network

volumes:
  peer0.mrolab.thermotrace.com:
EOF

# Package everything
tar -czf mrolab-deployment.tar.gz mrolab-deployment/
```

2. **Send to MRO Lab:**
```bash
# Via email, cloud storage, or scp
scp mrolab-deployment.tar.gz mrolab-user@their-server:/home/mrolab-user/
```

---

### **Deployment (MRO Lab does this on their machine):**

```bash
# Extract package
tar -xzf mrolab-deployment.tar.gz
cd mrolab-deployment

# Edit docker-compose.yaml - replace placeholders:
# <MANUFACTURER_IP> with your public IP or domain
# <YOUR_PUBLIC_IP> with their public IP or domain

# Install Docker (if not installed)
sudo apt update
sudo apt install -y docker.io docker-compose
sudo usermod -aG docker $USER
newgrp docker

# Start their peer
docker compose up -d

# Wait 10 seconds for sync
sleep 10

# Verify sync - should show all 46 blocks
docker exec peer0.mrolab.thermotrace.com peer channel getinfo -c inspection-channel
```

**Output should show:**
```
Blockchain info: {"height":47,"currentBlockHash":"...","previousBlockHash":"..."}
```

Height 47 means blocks 0-46 (47 total blocks) ✅

---

## Summary

### **To Start Network:**
```bash
cd /home/lp502261/thermotrace-production
docker compose -f network/docker-compose-network.yaml up -d
```

### **To Keep Network Always Running:**
1. **Best:** Deploy to cloud server (AWS/GCP/Azure) - ~$30-60/month
2. **Good:** Deploy to local server (Raspberry Pi/NUC) - ~$100-500 one-time
3. **Not recommended:** Keep laptop running 24/7

### **When MRO Lab Gets Their Own Server:**
- ✅ They download ALL blocks automatically (currently 270 KB)
- ✅ Blockchain syncs in seconds via gossip protocol
- ✅ They store blocks on THEIR local disk (laptop/server)
- ✅ Future blocks sync automatically
- ✅ Network continues even if one peer goes offline
- ✅ Each peer has complete blockchain copy

### **Block Storage:**
- **Your machine:** Full blockchain in Docker volume
- **Their machine:** Full blockchain in Docker volume (automatically synced)
- **Size:** Currently tiny (270 KB), grows slowly (~6 KB per block)

**Your blockchain is production-ready and highly resilient!** 🚀
