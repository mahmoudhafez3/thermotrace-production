# AI-Based Defect Detection System
## ThermoTrace Production - Composite Material Inspection

This system uses active thermography, PCA, CNN+Attention, and Grounding DINO for automated defect detection in composite materials, with results stored on blockchain via IPFS.

---

## System Overview

```
Active Thermography Video (.npy)
    ↓
PCA + CNN-Attention Feature Extraction
    ↓
Processed Thermal Image
    ↓
Grounding DINO Zero-Shot Detection
    ↓
Defect Localization & Metrics
    ↓
Upload to IPFS (decentralized storage)
    ↓
Submit to Blockchain (immutable record)
```

---

## Directory Structure

```
ai-defect-detection/
├── models/                    # Jupyter notebooks with AI models
│   ├── cnn_attention_grdino.ipynb    # Main model (recommended)
│   ├── cnn_attention_cogvlm.ipynb
│   └── cnn_attention_qwen.ipynb
├── data/                      # Raw thermal videos (.npy files)
├── outputs/                   # Processed images and results
├── scripts/                   # Integration scripts
│   └── submit_to_blockchain.py
├── docs/                      # Documentation
└── README.md                  # This file
```

---

## Quick Start

### 1. Run AI Defect Detection

```bash
# Navigate to models directory
cd ai-defect-detection/models

# Open the main notebook
jupyter notebook cnn_attention_grdino.ipynb

# Follow the notebook to:
# - Load thermal video
# - Apply PCA
# - Run CNN+Attention
# - Detect defects with Grounding DINO
# - Get bounding box and metrics
```

### 2. Submit Results to Blockchain

```bash
cd /home/lp502261/thermotrace-production

# Submit inspection to blockchain via IPFS
python ai-defect-detection/scripts/submit_to_blockchain.py \\
    --video ai-defect-detection/data/Flash_refl_50Hz_5J_Tamb_2_0000.npy \\
    --image ai-defect-detection/outputs/processed_defect_image.jpg \\
    --part-number COMP-PANEL-1234 \\
    --serial-number SN-2025-001 \\
    --material-type "Carbon Fiber Composite" \\
    --inspector "Dr. Jane Smith" \\
    --bbox 120,250,180,310 \\
    --confidence 0.92 \\
    --iou 0.85 \\
    --organization manufacturer
```

### 3. View on Blockchain

```bash
# Query inspection from blockchain
export FABRIC_CFG_PATH=$PWD/config
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID=ManufacturerMSP
export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/organizations/peerOrganizations/manufacturer.thermotrace.com/peers/peer0.manufacturer.thermotrace.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=$PWD/organizations/peerOrganizations/manufacturer.thermotrace.com/users/Admin@manufacturer.thermotrace.com/msp
export CORE_PEER_ADDRESS=peer0.manufacturer.thermotrace.com:9051

peer chaincode query \\
    -C inspection-channel \\
    -n aidefectinspection \\
    -c '{"Args":["GetDefectInspection","SN-2025-001"]}'
```

---

## Data Flow

### Input Data

- **Raw Thermal Video:** NumPy array (.npy)
  - Dimensions: (height, width, num_frames)
  - Example: 345 × 640 × 4527 frames
  - Size: ~200-500 MB

### Processing Pipeline

1. **ROI Selection:** Extract region of interest
2. **PCA:** Reduce dimensionality to 10 components
3. **CNN-Attention:** Extract features with transformer
4. **Image Generation:** Create thermal defect visualization
5. **Grounding DINO:** Zero-shot object detection
6. **Metrics:** Calculate IoU, center distance, confidence

### Output Data

1. **Processed Image:** Thermal visualization (JPG)
2. **Defect Location:** Bounding box coordinates
3. **Metrics:** Confidence, IoU, distances
4. **IPFS CIDs:** Content addresses for files
5. **Blockchain Record:** Immutable inspection record

---

## Blockchain Storage

### What's Stored ON-Chain (Public Ledger)

✅ File hashes (SHA-256)
✅ IPFS CIDs (content addresses)
✅ Detection results (bbox, confidence, metrics)
✅ Metadata (part number, date, org)
✅ Processing parameters
✅ Model information

### What's Stored OFF-Chain (IPFS)

📦 Raw thermal videos (.npy files)
📦 Processed images (.jpg files)
📦 Model weights (optional)

### What's PRIVATE (PDC)

🔒 Inspector name (org-specific)

---

## Key Features

### 1. Zero-Shot Detection
- No training data required
- Uses Grounding DINO pre-trained model
- Text prompts: "a defect", "thermal anomaly"

### 2. Decentralized Storage (IPFS)
- Files stored on IPFS network
- Content-addressed (hash = address)
- Immutable and verifiable
- Accessible via: `https://ipfs.io/ipfs/{CID}`

### 3. Blockchain Traceability
- Immutable audit trail
- Cross-organizational verification
- Private inspector data (PDC)
- Reproducible results

### 4. Privacy Controls
- Public: Detection results, metrics, IPFS links
- Private: Inspector name (per organization)
- Each org only sees their own inspector names

---

## IPFS Commands

### Upload a File
```bash
~/bin/ipfs add path/to/file.npy
# Returns: QmX... (CID)
```

### Retrieve a File
```bash
~/bin/ipfs get QmX...
```

### Check IPFS Status
```bash
~/bin/ipfs id
```

### Start IPFS Daemon (for hosting)
```bash
~/bin/ipfs daemon &
```

### Pin a File (prevent garbage collection)
```bash
~/bin/ipfs pin add QmX...
```

---

## Blockchain Commands

### Deploy AI Defect Chaincode

```bash
cd /home/lp502261/thermotrace-production

# Package chaincode
peer lifecycle chaincode package aidefectinspection.tar.gz \\
    --path chaincode/ai-defect-inspection/go \\
    --lang golang \\
    --label aidefectinspection_1.0

# Install on Manufacturer peer
export CORE_PEER_LOCALMSPID=ManufacturerMSP
export CORE_PEER_ADDRESS=peer0.manufacturer.thermotrace.com:9051
export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/organizations/peerOrganizations/manufacturer.thermotrace.com/peers/peer0.manufacturer.thermotrace.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=$PWD/organizations/peerOrganizations/manufacturer.thermotrace.com/users/Admin@manufacturer.thermotrace.com/msp

peer lifecycle chaincode install aidefectinspection.tar.gz

# Install on MRO Lab peer
export CORE_PEER_LOCALMSPID=MROLabMSP
export CORE_PEER_ADDRESS=peer0.mrolab.thermotrace.com:7051
export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/organizations/peerOrganizations/mrolab.thermotrace.com/peers/peer0.mrolab.thermotrace.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=$PWD/organizations/peerOrganizations/mrolab.thermotrace.com/users/Admin@mrolab.thermotrace.com/msp

peer lifecycle chaincode install aidefectinspection.tar.gz

# Get package ID
peer lifecycle chaincode queryinstalled

# Approve for Manufacturer
export PACKAGE_ID=aidefectinspection_1.0:xxxxx
peer lifecycle chaincode approveformyorg \\
    -o orderer1.thermotrace.com:8051 \\
    --tls --cafile $PWD/organizations/ordererOrganizations/thermotrace.com/orderers/orderer1.thermotrace.com/msp/tlscacerts/tlsca.thermotrace.com-cert.pem \\
    --channelID inspection-channel \\
    --name aidefectinspection \\
    --version 1.0 \\
    --package-id $PACKAGE_ID \\
    --sequence 1 \\
    --collections-config chaincode/ai-defect-inspection/collections_config.json

# Approve for MRO Lab (switch to MRO Lab peer settings, then run above command)

# Commit chaincode
peer lifecycle chaincode commit \\
    -o orderer1.thermotrace.com:8051 \\
    --tls --cafile $PWD/organizations/ordererOrganizations/thermotrace.com/orderers/orderer1.thermotrace.com/msp/tlscacerts/tlsca.thermotrace.com-cert.pem \\
    --channelID inspection-channel \\
    --name aidefectinspection \\
    --version 1.0 \\
    --sequence 1 \\
    --collections-config chaincode/ai-defect-inspection/collections_config.json \\
    --peerAddresses peer0.manufacturer.thermotrace.com:9051 \\
    --tlsRootCertFiles $PWD/organizations/peerOrganizations/manufacturer.thermotrace.com/peers/peer0.manufacturer.thermotrace.com/tls/ca.crt \\
    --peerAddresses peer0.mrolab.thermotrace.com:7051 \\
    --tlsRootCertFiles $PWD/organizations/peerOrganizations/mrolab.thermotrace.com/peers/peer0.mrolab.thermotrace.com/tls/ca.crt
```

---

## Verification Workflow

### 1. Verify File Integrity

```python
import hashlib

def verify_file(ipfs_cid, expected_hash):
    # Download from IPFS
    file_data = ipfs_client.get(ipfs_cid)

    # Calculate hash
    actual_hash = hashlib.sha256(file_data).hexdigest()

    # Compare
    return actual_hash == expected_hash
```

### 2. Verify Detection Results

```python
# Download video from IPFS
video = download_from_ipfs(inspection.rawVideoIPFS)

# Verify hash
assert sha256(video) == inspection.rawVideoHash

# Re-run AI model
results = run_defect_detection(video, inspection.roi)

# Compare results
assert results["bbox"] == inspection.boundingBox
assert abs(results["confidence"] - inspection.confidenceScore) < 0.01
```

---

## Model Information

### CNN-Attention Architecture

- **Input:** Thermal sequence (2000 time steps)
- **Encoder:** 3x Conv1D layers with MaxPooling
- **Bottleneck:** 128 channels with Transformer
- **Latent Space:** 10 dimensions (PCA components)
- **Decoder:** 3x ConvTranspose1D layers
- **Output:** Reconstructed sequence

### Grounding DINO

- **Model:** IDEA-Research/grounding-dino-base
- **Type:** Zero-shot object detection
- **Input:** Image + text prompts
- **Output:** Bounding boxes + confidence scores

---

## Example Inspection Record

```json
{
  "partNumber": "COMP-PANEL-1234",
  "serialNumber": "SN-2025-001",
  "materialType": "Carbon Fiber Composite",
  "inspectionDate": "2025-10-29T15:00:00Z",
  "inspectionType": "Active Thermography",
  "inspector": "Dr. Jane Smith",
  "organization": "ManufacturerMSP",
  "rawVideoHash": "sha256:abc123...",
  "rawVideoIPFS": "QmX7Mg...",
  "rawVideoSize": 234567890,
  "processedImageHash": "sha256:def456...",
  "processedImageIPFS": "QmY8Nh...",
  "roi_y1": 74,
  "roi_y2": 308,
  "roi_x1": 192,
  "roi_x2": 412,
  "defectDetected": true,
  "defectType": "thermal defect",
  "confidenceScore": 0.92,
  "bbox_x1": 120.5,
  "bbox_y1": 250.3,
  "bbox_x2": 180.7,
  "bbox_y2": 310.9,
  "iou": 0.85,
  "centerDistance": 15.2,
  "normCenterDistance": 0.05,
  "modelName": "cnn_attention_grdino",
  "modelVersion": "v1.0",
  "txID": "abc123...",
  "blockchainTimestamp": "2025-10-29T15:00:05Z"
}
```

---

## Next Steps

### For Testing (Without Real Data)

1. **Use Mock Data:**
   ```bash
   # Create dummy files for testing
   dd if=/dev/urandom of=test_video.npy bs=1M count=10
   cp ai-defect-detection/outputs/temp_image.jpg test_image.jpg

   # Test IPFS upload
   ~/bin/ipfs add test_video.npy
   ~/bin/ipfs add test_image.jpg

   # Test blockchain script
   python ai-defect-detection/scripts/submit_to_blockchain.py \\
       --video test_video.npy \\
       --image test_image.jpg \\
       --part-number TEST-001 \\
       --serial-number TEST-SN-001 \\
       --inspector "Test Inspector" \\
       --confidence 0.75
   ```

### For Production

1. **Deploy AI Defect Chaincode** (see commands above)
2. **Set up IPFS daemon** for 24/7 availability
3. **Process real thermal videos** with the notebook
4. **Submit results** using the Python script
5. **Verify on blockchain** and IPFS

---

## Troubleshooting

### IPFS Issues

**Problem:** `ipfs: command not found`
**Solution:** Add to PATH: `export PATH=$PATH:~/bin`

**Problem:** IPFS repo not initialized
**Solution:** Run `~/bin/ipfs init`

### Blockchain Issues

**Problem:** Chaincode not found
**Solution:** Make sure aidefectinspection chaincode is deployed

**Problem:** Permission denied
**Solution:** Check MSP configuration and peer settings

---

## Contact & Support

For questions or issues, refer to:
- Main docs: `/home/lp502261/thermotrace-production/ARCHITECTURE.md`
- Deployment guide: `/home/lp502261/thermotrace-production/STARTUP-GUIDE.md`
- AI analysis: `/home/lp502261/thermotrace-production/AI-DEFECT-DETECTION-ANALYSIS.md`

---

**System Status:** ✅ Configured and ready for testing
**IPFS:** ✅ Installed at `~/bin/ipfs`
**Chaincode:** ✅ Created at `chaincode/ai-defect-inspection/`
**Integration Script:** ✅ Available at `ai-defect-detection/scripts/submit_to_blockchain.py`
