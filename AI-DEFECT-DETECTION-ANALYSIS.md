# AI-Based Defect Detection System - Analysis & Blockchain Integration

## System Overview

Your colleague's code implements an **advanced AI-based composite material defect detection system** using:

### **Pipeline:**
```
Video Input (Active Thermography)
    ↓
Frame Processing & ROI Selection
    ↓
PCA (Principal Component Analysis)
    ↓
CNN + Attention Autoencoder
    ↓
Feature Extraction (10 components)
    ↓
Image Generation (Defect Visualization)
    ↓
Grounding DINO (Zero-Shot Object Detection)
    ↓
Defect Localization (Bounding Box)
    ↓
Metrics: IoU, Center Distance, Confidence
```

---

## Input/Output Analysis

### **INPUT (What the system takes):**

1. **Raw Thermal Video** (.npy files)
   - Format: NumPy array
   - Shape: (height, width, num_frames)
   - Example: `Flash_refl_50Hz_5J_Tamb_2_0000.npy`
   - Size: ~345 × 640 × 4527 frames
   - Typical video from active thermography inspection

2. **Region of Interest (ROI)**
   - Coordinates: y1, y2, x1, x2
   - Example: [74, 308, 192, 412]
   - Selected area to analyze

3. **Processing Parameters:**
   - Pulse time (t_pulse): 13
   - PCA components: 10
   - Target sequence length: 2000 frames
   - Text prompts: ["a defect", "a thermal defect", "an anomaly", "a thermal anomaly"]

### **OUTPUT (What the system produces):**

1. **Processed PCA Image** (img_rgb)
   - RGB image showing defect thermal signature
   - Resolution: 234 × 220 pixels (from ROI)
   - Format: uint8 RGB
   - Saved as: temp_image.jpg

2. **Defect Detection Results:**
   ```python
   {
       "original": img_rgb,           # The processed thermal image
       "gt_box": [x1, y1, x2, y2],   # Ground truth bounding box
       "pred_box": [x1, y1, x2, y2], # Predicted defect location
       "confidence": float,           # Detection confidence score
       "label": str,                  # Detected label
       "iou": float,                  # Intersection over Union
       "center_distance": float,      # Distance between boxes
       "norm_center_distance": float  # Normalized distance
   }
   ```

3. **Performance Metrics:**
   - IoU (Intersection over Union)
   - Center Distance
   - Normalized Center Distance
   - Detection confidence score

---

## What to Store on Blockchain

### **Current Blade Inspection Data** (14 fields):
```go
type BladeInspection struct {
    PartNumber     string
    SerialNumber   string
    OccasionLabel  string
    Inspector      string  // Private
    InspectionDate string
    Measurements   ChordMeasurements  // 5 floats
    CSVHash        string
    // ...
}
```

### **Proposed: AI Defect Inspection Data**

```go
type AIDefectInspection struct {
    // Identity
    PartNumber          string  // e.g., "COMP-PANEL-1234"
    SerialNumber        string  // e.g., "SN-2025-001"
    MaterialType        string  // e.g., "Carbon Fiber Composite"

    // Inspection Metadata
    InspectionDate      string  // ISO 8601 timestamp
    InspectionType      string  // "Active Thermography"
    Inspector           string  // Private (who ran the test)
    Organization        string  // "Manufacturer" or "MRO Lab"

    // Video/Image Data (External Storage)
    RawVideoHash        string  // SHA-256 hash of .npy file
    RawVideoURL         string  // IPFS CID or S3 URL
    RawVideoSize        int64   // File size in bytes
    ProcessedImageHash  string  // SHA-256 of processed thermal image
    ProcessedImageURL   string  // IPFS CID or S3 URL

    // ROI Parameters
    ROI_Y1              int
    ROI_Y2              int
    ROI_X1              int
    ROI_X2              int

    // Processing Parameters
    PulseTime           int     // t_pulse
    PCAComponents       int     // Number of components (e.g., 10)
    SequenceLength      int     // Resampled length (e.g., 2000)

    // AI Model Information
    ModelName           string  // "cnn_attention_grdino"
    ModelVersion        string  // "v1.0"
    ModelHash           string  // Hash of model weights

    // Detection Results
    DefectDetected      bool    // true if defect found
    DefectType          string  // "thermal defect", "anomaly", etc.
    ConfidenceScore     float64 // 0.0 to 1.0

    // Bounding Box (if defect detected)
    BBox_X1             float64
    BBox_Y1             float64
    BBox_X2             float64
    BBox_Y2             float64

    // Metrics
    IoU                 float64 // Intersection over Union
    CenterDistance      float64
    NormCenterDistance  float64

    // Ground Truth (if available)
    HasGroundTruth      bool
    GT_BBox_X1          float64
    GT_BBox_Y1          float64
    GT_BBox_X2          float64
    GT_BBox_Y2          float64

    // Blockchain Metadata
    TxID                string
    BlockchainTimestamp string
    SubmittedAt         string
}
```

---

## External Storage Strategy

### **Problem:**
- Raw thermal videos (.npy files) are **HUGE** (~hundreds of MB)
- Blockchain should NOT store large files
- Only store **hashes** and **references**

### **Solution: Hybrid Storage**

```
┌─────────────────────────────────────────────┐
│           Data Storage Architecture         │
├─────────────────────────────────────────────┤
│                                             │
│  Blockchain (Immutable Record)              │
│  ├─ Metadata                                │
│  ├─ File hashes (SHA-256)                   │
│  ├─ Detection results                       │
│  └─ Reference URLs                          │
│                                             │
│  ↓ References ↓                             │
│                                             │
│  External Storage (Actual Files)            │
│  ├─ Option 1: IPFS (Decentralized)          │
│  ├─ Option 2: AWS S3 (Centralized)          │
│  └─ Option 3: MinIO (Self-hosted)           │
│                                             │
└─────────────────────────────────────────────┘
```

### **Recommended: IPFS (InterPlanetary File System)**

**Why IPFS:**
- ✅ Decentralized (fits blockchain philosophy)
- ✅ Content-addressed (file hash = address)
- ✅ Immutable (files can't be changed)
- ✅ Free public nodes available
- ✅ Can pin files for persistence

**How it works:**
```python
# 1. Upload video to IPFS
ipfs_hash = ipfs_client.add("Flash_refl_50Hz_5J_Tamb_2_0000.npy")
# Returns: "QmX7Mg... " (Content ID)

# 2. Store IPFS CID + SHA-256 hash on blockchain
blockchain.submit({
    "rawVideoURL": "ipfs://QmX7Mg...",
    "rawVideoHash": "sha256:abc123...",
    "rawVideoSize": 123456789
})

# 3. Later: Retrieve and verify
file_data = ipfs_client.get("QmX7Mg...")
verify_hash(file_data) == "sha256:abc123..."  # Integrity check!
```

**Access URL:**
```
https://ipfs.io/ipfs/QmX7Mg...
```

---

## Proposed Workflow

### **Step 1: Inspection Process**

```python
# Run thermal inspection
video_data = record_thermography_video()
save_video("raw_video.npy", video_data)

# Process with AI model
roi = select_roi(video_data)
pca_image = apply_pca_and_cnn(video_data, roi)
defect_results = detect_defects(pca_image)

# Upload to IPFS
raw_video_cid = upload_to_ipfs("raw_video.npy")
processed_image_cid = upload_to_ipfs("processed_image.jpg")

# Prepare blockchain record
inspection_record = {
    "partNumber": "COMP-PANEL-1234",
    "serialNumber": "SN-2025-001",
    "rawVideoURL": f"ipfs://{raw_video_cid}",
    "rawVideoHash": sha256("raw_video.npy"),
    "processedImageURL": f"ipfs://{processed_image_cid}",
    "defectDetected": defect_results["detected"],
    "confidenceScore": defect_results["confidence"],
    "boundingBox": defect_results["bbox"],
    # ... more fields
}

# Submit to blockchain
blockchain.addInspection(inspection_record)
```

### **Step 2: Verification**

```python
# Anyone can verify the inspection
inspection = blockchain.getInspection("SN-2025-001")

# Download raw video from IPFS
raw_video = download_from_ipfs(inspection.rawVideoURL)

# Verify integrity
assert sha256(raw_video) == inspection.rawVideoHash  # ✅

# Re-run AI model (reproducibility)
our_results = reprocess(raw_video, inspection.roi, inspection.model)

# Compare results
assert our_results["bbox"] == inspection.boundingBox  # ✅
```

---

## Storage Cost Comparison

### **Option 1: IPFS (Recommended)**

**Setup:**
```bash
# Install IPFS
wget https://dist.ipfs.io/kubo/latest/kubo_latest_linux-amd64.tar.gz
tar -xvzf kubo_latest_linux-amd64.tar.gz
cd kubo
sudo bash install.sh

# Initialize
ipfs init
ipfs daemon &
```

**Costs:**
- Self-hosted: FREE (use your own storage)
- Pinning services: ~$0.02-0.15 per GB/month
  - Pinata: Free tier 1GB, then $20/TB/month
  - web3.storage: FREE (backed by Filecoin)
  - Infura IPFS: Free tier, then ~$0.08/GB/month

**For your use case:**
- 100 inspections × 200 MB each = 20 GB
- Cost: ~$0-4/month

### **Option 2: AWS S3**

**Costs:**
- Storage: $0.023 per GB/month
- 20 GB = $0.46/month
- Data transfer OUT: $0.09 per GB
- 100 downloads/month = $1.80/month
- **Total: ~$2-3/month**

**Pros:**
- Very reliable
- Fast access
- Easy integration

**Cons:**
- Centralized (single point of control)
- Vendor lock-in
- Not aligned with blockchain philosophy

### **Option 3: MinIO (Self-Hosted S3)**

**Setup:**
```bash
docker run -d \
  -p 9000:9000 \
  -p 9001:9001 \
  --name minio \
  -v minio_storage:/data \
  quay.io/minio/minio server /data --console-address ":9001"
```

**Costs:**
- FREE (use your own server storage)
- Same server as blockchain: $0 extra

**Pros:**
- Full control
- S3-compatible API
- No external costs

**Cons:**
- You manage backups
- Limited by your storage

---

## Integration Architecture

```
┌─────────────────────────────────────────────────────┐
│              AI Defect Detection System             │
├─────────────────────────────────────────────────────┤
│                                                     │
│  1. Thermography Inspection                         │
│     └─ Record video (.npy)                          │
│                                                     │
│  2. AI Processing                                   │
│     ├─ PCA                                          │
│     ├─ CNN + Attention                              │
│     └─ Grounding DINO                               │
│                                                     │
│  3. Upload to IPFS                                  │
│     ├─ Raw video → IPFS CID                         │
│     ├─ Processed image → IPFS CID                   │
│     └─ Calculate SHA-256 hashes                     │
│                                                     │
│  4. Submit to Blockchain                            │
│     ├─ Metadata                                     │
│     ├─ IPFS CIDs                                    │
│     ├─ File hashes                                  │
│     ├─ Detection results                            │
│     └─ Metrics (IoU, confidence, etc.)              │
│                                                     │
│  5. Query & Verify                                  │
│     ├─ Get inspection from blockchain               │
│     ├─ Download files from IPFS                     │
│     ├─ Verify hashes                                │
│     └─ Reproduce results                            │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## Suggested Folder Rename

**Current:** `mahmoud`

**Suggested Names:**
1. **`ai-defect-detection`** ⭐ RECOMMENDED
   - Clear and descriptive
   - Professional
   - Self-explanatory

2. **`thermal-ai-inspection`**
   - Emphasizes thermography aspect

3. **`composite-defect-ai`**
   - Highlights composite materials

4. **`ndt-ai-system`**
   - NDT = Non-Destructive Testing (industry term)

5. **`thermography-ml`**
   - Machine Learning focus

**Recommended:** `ai-defect-detection`

---

## Next Steps

### **Phase 1: Rename & Organize** (1 hour)
```bash
mv mahmoud ai-defect-detection
cd ai-defect-detection
mkdir -p {models,data,outputs,docs}
mv *.ipynb models/
```

### **Phase 2: Design New Chaincode** (2-3 hours)
- Create `AIDefectInspection` struct
- Add functions:
  - `AddDefectInspection`
  - `GetDefectInspection`
  - `GetDefectInspectionsByPart`
  - `QueryDefectsByConfidence`

### **Phase 3: Set Up IPFS** (1 hour)
- Install IPFS locally
- Test file upload/download
- Integrate with Python script

### **Phase 4: Create Integration Script** (3-4 hours)
- Python script that:
  1. Runs AI inference
  2. Uploads to IPFS
  3. Submits to blockchain

### **Phase 5: Update Web App** (2-3 days)
- Upload video interface
- Display defect detection results
- Show thermal images
- Bounding box visualization

---

## Questions to Answer

1. **Do you want to keep the blade inspection chaincode** or replace it entirely?
   - **Recommended:** Keep both (two different inspection types)
   - Blade measurements: `bladeinspection` chaincode
   - AI defect detection: `aidefectinspection` chaincode (new)

2. **Storage preference:**
   - IPFS (decentralized, free)
   - AWS S3 (centralized, $2-3/month)
   - MinIO (self-hosted, free)

3. **Privacy requirements:**
   - Should raw videos be private (org-specific)?
   - Should AI model details be private?
   - Should detection results be public or private?

4. **Integration timeline:**
   - Quick prototype (1-2 weeks)?
   - Full production system (1-2 months)?

---

## My Recommendation

**Hybrid Approach:**
1. **Keep** existing blade inspection chaincode (manual measurements)
2. **Add** new AI defect inspection chaincode (automated detection)
3. **Use** IPFS for file storage (decentralized + free)
4. **Create** Python integration script
5. **Build** web interface to upload videos and view results

This gives you:
- ✅ Two complementary inspection systems
- ✅ Decentralized storage
- ✅ Low cost
- ✅ Full traceability
- ✅ Reproducible AI results

Ready to proceed? Let me know which direction you want to go! 🚀
