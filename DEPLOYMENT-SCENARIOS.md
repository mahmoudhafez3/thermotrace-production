# ThermoTrace - Deployment Scenarios & Costs

## Quick Answer to Your Questions:

### **Do you need a cloud server for each organization's peer?**
**It depends on your use case:**
- ❌ **NO** - If you're running everything yourself (testing/development)
- ✅ **YES** - If you want true organizational independence (production)

### **Do you need a cloud server for each orderer?**
**NO - Orderers can run together!**
- All 3 orderers can run on ONE server
- Or distribute them for higher availability (optional)

---

## Deployment Scenarios (From Simplest to Most Advanced)

### **Scenario 1: Single Server - Everything Together** ⭐ RECOMMENDED FOR STARTING

**What:** Run both organizations + all orderers on ONE cloud server

```
┌─────────────────────────────────────────┐
│    Single AWS EC2 Server ($30-50/month) │
├─────────────────────────────────────────┤
│ Manufacturer Peer (port 9051)           │
│ MRO Lab Peer (port 7051)                │
│ Orderer 1 (port 8050)                   │
│ Orderer 2 (port 9050)                   │
│ Orderer 3 (port 10050)                  │
│ 2x CouchDB databases                    │
│ Explorer (optional)                     │
└─────────────────────────────────────────┘
```

**Costs:**
- **Cloud server:** $30-50/month (t3.medium on AWS)
- **Total:** $30-50/month

**Pros:**
- ✅ Cheapest option
- ✅ Simplest to manage
- ✅ Network runs 24/7
- ✅ Fully functional blockchain
- ✅ All your current code works as-is

**Cons:**
- ❌ Not truly decentralized (you control everything)
- ❌ Single point of failure
- ❌ MRO Lab doesn't have independent control

**Best for:**
- Testing and development
- Single company managing multiple divisions
- Proof of concept
- When you don't need true organizational independence

**How to deploy:**
```bash
# Just copy your entire thermotrace-production folder to the cloud server
scp -r /home/lp502261/thermotrace-production ubuntu@<SERVER-IP>:/home/ubuntu/

# SSH into server
ssh ubuntu@<SERVER-IP>

# Start everything
cd thermotrace-production
docker compose -f network/docker-compose-network.yaml up -d
```

**That's it! Network runs 24/7 for $30-50/month.**

---

### **Scenario 2: Two Servers - One Per Organization** ⭐ RECOMMENDED FOR PRODUCTION

**What:** Each organization gets their own server, orderers on separate/shared server

```
┌──────────────────────┐       ┌──────────────────────┐
│ Manufacturer Server  │       │   MRO Lab Server     │
│ (Germany/Your choice)│       │ (USA/Their choice)   │
├──────────────────────┤       ├──────────────────────┤
│ Manufacturer Peer    │◄─────►│ MRO Lab Peer         │
│ CouchDB              │Internet│ CouchDB              │
│                      │       │                      │
│ $30-40/month         │       │ $30-40/month         │
└──────────────────────┘       └──────────────────────┘
           │                              │
           │                              │
           └──────────┬───────────────────┘
                      ↓
           ┌──────────────────────┐
           │  Orderer Server      │
           │  (Neutral location)  │
           ├──────────────────────┤
           │ Orderer 1            │
           │ Orderer 2            │
           │ Orderer 3            │
           │                      │
           │ $30-40/month         │
           └──────────────────────┘
```

**Costs:**
- **Manufacturer server:** $30-40/month (runs 1 peer + 1 CouchDB)
- **MRO Lab server:** $30-40/month (runs 1 peer + 1 CouchDB)
- **Orderer server:** $30-40/month (runs 3 orderers)
- **Total:** $90-120/month

**Who pays:**
- **Manufacturer:** Pays for their own server ($30-40/month)
- **MRO Lab:** Pays for their own server ($30-40/month)
- **Orderers:** Split cost 50/50 OR one org hosts OR use third party

**Pros:**
- ✅ True decentralization
- ✅ Each org controls their own infrastructure
- ✅ Each org can manage their own server
- ✅ Higher availability (if one server down, network continues)
- ✅ Geographic distribution (faster for each org)
- ✅ True privacy (each org only has their private data)

**Cons:**
- ❌ More expensive ($90-120/month total)
- ❌ More complex to set up
- ❌ Requires coordination between organizations

**Best for:**
- Production deployments
- True multi-organization scenarios
- When organizations don't trust each other
- Compliance/regulatory requirements

---

### **Scenario 3: Orderer Options - Who Runs Them?**

You have 3 orderers in your network. Here are the options:

#### **Option A: All Orderers on One Server** (Recommended)

```
┌─────────────────────────┐
│   Orderer Server        │
├─────────────────────────┤
│ orderer1 (port 8050)    │
│ orderer2 (port 9050)    │
│ orderer3 (port 10050)   │
└─────────────────────────┘

Cost: $30-40/month
Who pays: Split between orgs or one org hosts
```

**Pros:**
- ✅ Cheap - only one server
- ✅ Simple to manage
- ✅ Sufficient for most use cases

**Cons:**
- ❌ Single point of failure for ordering service

#### **Option B: One Orderer Per Server** (High Availability)

```
┌────────────────┐  ┌────────────────┐  ┌────────────────┐
│ Orderer Server1│  │ Orderer Server2│  │ Orderer Server3│
├────────────────┤  ├────────────────┤  ├────────────────┤
│ orderer1       │  │ orderer2       │  │ orderer3       │
│                │  │                │  │                │
│ $20-30/month   │  │ $20-30/month   │  │ $20-30/month   │
└────────────────┘  └────────────────┘  └────────────────┘

Total Cost: $60-90/month for orderers
```

**Pros:**
- ✅ Highest availability
- ✅ Can survive 1 orderer failure (Raft consensus with 3 nodes can lose 1)
- ✅ Geographic distribution

**Cons:**
- ❌ Most expensive
- ❌ Overkill for most use cases

**When to use:** Large enterprise deployments with high availability requirements

#### **Option C: Orderers Hosted by Organizations**

```
Manufacturer Server              MRO Lab Server
├─ Manufacturer Peer             ├─ MRO Lab Peer
└─ Orderer 1                     └─ Orderer 2

Third-Party/Shared Server
└─ Orderer 3
```

**Pros:**
- ✅ Lower cost (no dedicated orderer server)
- ✅ Orderers distributed

**Cons:**
- ❌ Peers and orderers compete for resources on same server
- ❌ Need bigger servers

**Cost:** Add ~$10-20/month to each peer server for bigger instance

---

## Recommended Deployment Strategy (Step by Step)

### **Phase 1: Start Simple (Months 1-3)**
Deploy **Scenario 1** - Everything on one server

**Action:**
1. Get one AWS EC2 t3.medium instance ($35-45/month)
2. Deploy your entire current setup
3. Run it 24/7
4. Test everything thoroughly

**Cost:** $35-45/month
**Effort:** 1-2 hours setup

**Result:** Production-ready network, single point of control

---

### **Phase 2: Add Second Organization (Months 3-6)**
Upgrade to **Scenario 2** - Distribute to MRO Lab

**Action:**
1. MRO Lab gets their own AWS server ($30-40/month)
2. Transfer MRO Lab peer to their server
3. Keep orderers on your server OR move to neutral server
4. Configure network connectivity

**Cost:** $65-85/month total ($35-45 yours + $30-40 theirs)
**Effort:** 4-6 hours coordination + setup

**Result:** True multi-org blockchain

---

### **Phase 3: High Availability (Optional - Month 6+)**
Enhance with dedicated orderer server

**Action:**
1. Create dedicated orderer server
2. Move all 3 orderers to it
3. Split cost between organizations

**Cost:** +$30-40/month (split = +$15-20 each org)
**Total:** $95-125/month
**Effort:** 2-3 hours

**Result:** Maximum decentralization and availability

---

## Server Sizing Guide

### **For Running 1 Peer + 1 CouchDB:**

**Small/Testing (Low traffic):**
- **AWS:** t3.small ($17/month)
- **RAM:** 2 GB
- **CPU:** 2 vCPU
- **Storage:** 20 GB
- **Good for:** Testing, <100 transactions/day

**Medium/Production (Recommended):**
- **AWS:** t3.medium ($35/month)
- **RAM:** 4 GB
- **CPU:** 2 vCPU
- **Storage:** 30 GB
- **Good for:** Production, <1000 transactions/day

**Large/Heavy Use:**
- **AWS:** t3.large ($70/month)
- **RAM:** 8 GB
- **CPU:** 2 vCPU
- **Storage:** 50 GB
- **Good for:** Heavy use, >1000 transactions/day

### **For Running All 3 Orderers:**

**Small Configuration:**
- **AWS:** t3.small ($17/month)
- **RAM:** 2 GB
- **CPU:** 2 vCPU
- **Storage:** 20 GB

**Recommended:**
- **AWS:** t3.medium ($35/month)
- **RAM:** 4 GB
- **CPU:** 2 vCPU
- **Storage:** 30 GB

---

## Real-World Cost Examples

### **Example 1: You Run Everything (Development/Testing)**

```
Deployment: Scenario 1
Server: AWS t3.medium

Components:
├─ 2 Peers
├─ 3 Orderers
├─ 2 CouchDB instances
└─ Explorer

Monthly Cost: $35-45
Your Cost: $35-45/month (you pay 100%)
```

---

### **Example 2: Two Independent Organizations (Production)**

```
Deployment: Scenario 2

Manufacturer Server (AWS Frankfurt):
├─ Manufacturer Peer
├─ CouchDB
└─ Cost: $35/month

MRO Lab Server (AWS Virginia):
├─ MRO Lab Peer
├─ CouchDB
└─ Cost: $35/month

Orderer Server (AWS Oregon - neutral):
├─ Orderer 1, 2, 3
└─ Cost: $35/month

Total Network Cost: $105/month
Manufacturer Pays: $35 + $17.50 (50% orderers) = $52.50/month
MRO Lab Pays: $35 + $17.50 (50% orderers) = $52.50/month
```

---

### **Example 3: Enterprise HA Setup**

```
Deployment: Scenario 2 + Scenario 3B

Manufacturer Server: $35/month
MRO Lab Server: $35/month
Orderer Server 1: $25/month
Orderer Server 2: $25/month
Orderer Server 3: $25/month

Total: $145/month
Split 50/50: $72.50 per organization
```

---

## Alternative: Orderer Hosting Services

Instead of running your own orderers, you could use:

### **Option: Blockchain-as-a-Service (BaaS)**

Some companies offer managed Fabric orderer services:
- **IBM Blockchain Platform:** ~$200-500/month (includes orderers + managed infrastructure)
- **Oracle Blockchain Cloud:** ~$300-600/month
- **AWS Managed Blockchain:** ~$400-800/month (includes orderers)

**Pros:**
- ✅ No orderer management
- ✅ Professional support
- ✅ Automatic updates

**Cons:**
- ❌ Very expensive
- ❌ Vendor lock-in
- ❌ Less control

**Verdict:** Not worth it for your use case. Running your own orderers is much cheaper and you have full control.

---

## My Recommendation for You

Based on your setup, here's what I recommend:

### **Short Term (Next 3-6 months):**

**Deploy Scenario 1:**
```
One AWS t3.medium server: $35-45/month
├─ Both peers
├─ All orderers
├─ Both CouchDB instances
└─ Explorer

Your cost: $35-45/month
Setup time: 2 hours
```

**Why:**
- Simple, cheap, proven
- Your network runs 24/7
- Perfect for getting started
- Can upgrade later

### **Long Term (6+ months):**

**Upgrade to Scenario 2 when:**
- You get a real MRO Lab partner
- You need regulatory compliance
- You want true decentralization

**Costs will be:**
- You: $50-60/month (your peer + orderer share)
- MRO Lab: $50-60/month (their peer + orderer share)
- Total network: $100-120/month

---

## Summary Table

| Scenario | Servers Needed | Monthly Cost | Best For | Setup Complexity |
|----------|----------------|--------------|----------|------------------|
| **1: Single Server** | 1 | $30-50 | Testing, Dev, Single org | ⭐ Easy |
| **2: Multi-Org** | 3 (2 peers + 1 orderer) | $90-120 | Production, Real multi-org | ⭐⭐ Medium |
| **3: High Availability** | 5+ | $140-200 | Enterprise, Critical systems | ⭐⭐⭐ Complex |

---

## Key Takeaways

### **Orderers:**
- ❌ **DON'T** need one server per orderer
- ✅ **DO** run all 3 orderers on one server
- 💡 **Optional:** Distribute orderers for high availability

### **Peers:**
- ❌ **DON'T** need separate servers if you control both orgs
- ✅ **DO** need separate servers for true organizational independence
- 💡 **Start simple:** One server, upgrade later

### **Costs:**
- **Development:** $30-50/month (one server)
- **Production:** $90-120/month (distributed)
- **Enterprise HA:** $140-200/month (overkill for most cases)

### **My Advice:**
1. Start with one AWS t3.medium server ($35-45/month)
2. Run everything on it for 3-6 months
3. Upgrade to multi-server when you have real MRO Lab partner
4. Don't over-engineer early - keep it simple!

**Your blockchain works the same whether on 1 server or 10 servers - the architecture is identical!** 🚀
