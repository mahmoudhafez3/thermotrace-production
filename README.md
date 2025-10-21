# ThermoTrace - Blockchain-Based NDT Traceability System

A production-ready Hyperledger Fabric network for aerospace non-destructive testing (NDT) traceability, specifically designed for pulse-thermography inspection data.

## 🎯 Project Overview

This system provides immutable, auditable traceability for NDT inspections in aerospace manufacturing and maintenance. Built on Hyperledger Fabric 2.5.14 with a 3-node Raft consensus cluster.

## 🏗️ Network Architecture

- **Organizations**: MRO Lab (Org1), Manufacturer (Org2)
- **Orderers**: 3-node Raft cluster for fault tolerance
- **Peers**: 1 peer per organization with CouchDB state database
- **Channel**: `inspection-channel` for NDT inspection records
- **Consensus**: Raft (CFT - Crash Fault Tolerant)

## 📋 Prerequisites

- Ubuntu 24.04 (or similar Linux)
- Docker Engine 20.10+
- Docker Compose v2+
- Go 1.21+
- Node.js 18 LTS (for applications)
- 16GB RAM minimum
- 50GB free disk space

## 🚀 Quick Start

### 1. Install Fabric Binaries
```bash
cd ~/thermotrace-production
curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.5.14 1.5.12
export PATH=$HOME/thermotrace-production/bin:$PATH
```

### 2. Generate Crypto Material & Artifacts
```bash
./network/scripts/setup-clean.sh
```

This script:
- Generates all certificates and keys using `cryptogen`
- Creates the genesis block for the orderer
- Generates the channel creation transaction

### 3. Start the Network
```bash
cd network
docker compose -f docker-compose-network.yaml up -d
```

### 4. Verify Network Status
```bash
docker ps --format "table {{.Names}}\t{{.Status}}"
docker logs peer0.mrolab.thermotrace.com --tail 10
```

## 📁 Project Structure
```
thermotrace-production/
├── network/
│   ├── configtx.yaml              # Channel & org definitions
│   ├── crypto-config.yaml         # Certificate generation config
│   ├── docker-compose-network.yaml # Network infrastructure
│   ├── channel-artifacts/         # Genesis block & channel tx
│   └── scripts/
│       └── setup-clean.sh         # Automated setup script
├── organizations/                  # Crypto material (generated)
│   ├── ordererOrganizations/
│   └── peerOrganizations/
├── chaincode/                      # Smart contracts (coming soon)
├── applications/                   # Client apps (coming soon)
├── evaluation/                     # Performance tests (coming soon)
└── docs/                          # Documentation
```

## 🔧 Management Commands

### Stop Network
```bash
cd network
docker compose -f docker-compose-network.yaml down
```

### Clean Everything & Restart
```bash
cd network
docker compose -f docker-compose-network.yaml down -v
cd ..
sudo rm -rf organizations/
./network/scripts/setup-clean.sh
cd network
docker compose -f docker-compose-network.yaml up -d
```

### View Logs
```bash
# All containers
docker compose -f network/docker-compose-network.yaml logs -f

# Specific container
docker logs -f orderer1.thermotrace.com
docker logs -f peer0.mrolab.thermotrace.com
```

## 🎓 Research Context

This system is being developed for a research paper targeting **IEEE Access** (January 2026 submission). The goal is to demonstrate how permissioned blockchain can enhance data integrity, transparency, and auditability in aerospace NDT workflows.

### Key Features for Research:
- Multi-organization endorsement policies
- Private data collections for sensitive inspection data
- Performance benchmarking (latency, throughput, storage)
- Fault tolerance testing
- Integration with AI-based defect detection

## 📊 Performance Targets

- Transaction Latency: < 500ms
- Throughput: > 100 TPS
- Storage Efficiency: < 10KB per inspection record
- Fault Recovery: < 30 seconds (single node failure)

## �� Security Features

- TLS encryption for all communications
- X.509 certificate-based identity management
- Multi-signature endorsement policies
- Private data collections for confidential information
- Immutable audit trail

## 🛠️ Technology Stack

- **Blockchain**: Hyperledger Fabric 2.5.14
- **Smart Contracts**: Go 1.21
- **State Database**: CouchDB 3.3.2
- **Consensus**: Raft
- **Container Orchestration**: Docker Compose
- **Monitoring** (planned): Prometheus + Grafana

## 📝 License

[To be determined - likely Apache 2.0 for open source]

## 👥 Contributors

- Mahmoud Hafez - Khalifa University

## 📧 Contact

For questions or collaboration: mahmoud.hafez@ku.ac.ae

---

**Status**: Active Development | Network Infrastructure Complete ✅
