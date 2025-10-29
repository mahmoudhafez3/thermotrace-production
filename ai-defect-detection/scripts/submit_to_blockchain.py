#!/usr/bin/env python3
"""
AI Defect Detection - Blockchain Integration Script

This script processes thermal inspection data, uploads files to IPFS,
and submits the results to the ThermoTrace blockchain.

Usage:
    python submit_to_blockchain.py \
        --video path/to/video.npy \
        --image path/to/processed_image.jpg \
        --part-number COMP-PANEL-1234 \
        --serial-number SN-2025-001 \
        --material-type "Carbon Fiber Composite" \
        --inspector "Dr. John Smith" \
        --bbox 74,308,192,412 \
        --confidence 0.95
"""

import argparse
import hashlib
import json
import subprocess
import sys
from datetime import datetime
from pathlib import Path


def calculate_sha256(file_path):
    """Calculate SHA-256 hash of a file."""
    sha256_hash = hashlib.sha256()
    with open(file_path, "rb") as f:
        for byte_block in iter(lambda: f.read(4096), b""):
            sha256_hash.update(byte_block)
    return sha256_hash.hexdigest()


def upload_to_ipfs(file_path):
    """
    Upload a file to IPFS and return the CID.

    Args:
        file_path: Path to the file to upload

    Returns:
        str: IPFS CID (Content Identifier)
    """
    try:
        result = subprocess.run(
            [str(Path.home() / "bin" / "ipfs"), "add", "-q", str(file_path)],
            capture_output=True,
            text=True,
            check=True
        )
        cid = result.stdout.strip()
        print(f"✓ Uploaded {Path(file_path).name} to IPFS: {cid}")
        return cid
    except subprocess.CalledProcessError as e:
        print(f"✗ Failed to upload to IPFS: {e.stderr}")
        sys.exit(1)


def submit_to_blockchain(inspection_data, org="manufacturer"):
    """
    Submit inspection data to the blockchain.

    Args:
        inspection_data: Dictionary containing inspection information
        org: Organization name ('manufacturer' or 'mrolab')
    """
    # Convert inspection data to JSON
    inspection_json = json.dumps(inspection_data)

    # Prepare peer command based on organization
    if org.lower() == "manufacturer":
        peer_env = {
            "CORE_PEER_TLS_ENABLED": "true",
            "CORE_PEER_LOCALMSPID": "ManufacturerMSP",
            "CORE_PEER_TLS_ROOTCERT_FILE": "${PWD}/organizations/peerOrganizations/manufacturer.thermotrace.com/peers/peer0.manufacturer.thermotrace.com/tls/ca.crt",
            "CORE_PEER_MSPCONFIGPATH": "${PWD}/organizations/peerOrganizations/manufacturer.thermotrace.com/users/Admin@manufacturer.thermotrace.com/msp",
            "CORE_PEER_ADDRESS": "peer0.manufacturer.thermotrace.com:9051",
        }
    else:  # mrolab
        peer_env = {
            "CORE_PEER_TLS_ENABLED": "true",
            "CORE_PEER_LOCALMSPID": "MROLabMSP",
            "CORE_PEER_TLS_ROOTCERT_FILE": "${PWD}/organizations/peerOrganizations/mrolab.thermotrace.com/peers/peer0.mrolab.thermotrace.com/tls/ca.crt",
            "CORE_PEER_MSPCONFIGPATH": "${PWD}/organizations/peerOrganizations/mrolab.thermotrace.com/users/Admin@mrolab.thermotrace.com/msp",
            "CORE_PEER_ADDRESS": "peer0.mrolab.thermotrace.com:7051",
        }

    # Build peer chaincode invoke command
    cmd = f"""
    export FABRIC_CFG_PATH=$PWD/config && \\
    export {' && export '.join(f'{k}={v}' for k, v in peer_env.items())} && \\
    peer chaincode invoke \\
        -o orderer1.thermotrace.com:7050 \\
        --tls \\
        --cafile $PWD/organizations/ordererOrganizations/thermotrace.com/orderers/orderer1.thermotrace.com/msp/tlscacerts/tlsca.thermotrace.com-cert.pem \\
        -C inspection-channel \\
        -n aidefectinspection \\
        -c '{{"Args":["AddDefectInspection","{inspection_json}"]}}' \\
        --peerAddresses peer0.manufacturer.thermotrace.com:9051 \\
        --tlsRootCertFiles $PWD/organizations/peerOrganizations/manufacturer.thermotrace.com/peers/peer0.manufacturer.thermotrace.com/tls/ca.crt \\
        --peerAddresses peer0.mrolab.thermotrace.com:7051 \\
        --tlsRootCertFiles $PWD/organizations/peerOrganizations/mrolab.thermotrace.com/peers/peer0.mrolab.thermotrace.com/tls/ca.crt
    """

    print("\n📤 Submitting to blockchain...")
    print(f"Command: peer chaincode invoke -C inspection-channel -n aidefectinspection")

    # Note: Actual execution would require proper shell environment
    # For now, we'll print the command
    print("\n" + "="*60)
    print("BLOCKCHAIN SUBMISSION COMMAND:")
    print("="*60)
    print(cmd)
    print("="*60)

    return cmd


def main():
    parser = argparse.ArgumentParser(
        description="Submit AI defect detection results to ThermoTrace blockchain"
    )

    # Required arguments
    parser.add_argument("--video", required=True, help="Path to raw thermal video (.npy)")
    parser.add_argument("--image", required=True, help="Path to processed image (.jpg)")
    parser.add_argument("--part-number", required=True, help="Part number (e.g., COMP-PANEL-1234)")
    parser.add_argument("--serial-number", required=True, help="Serial number (e.g., SN-2025-001)")

    # Optional arguments
    parser.add_argument("--material-type", default="Carbon Fiber Composite", help="Material type")
    parser.add_argument("--inspector", required=True, help="Inspector name (will be private)")
    parser.add_argument("--bbox", help="Bounding box: x1,y1,x2,y2")
    parser.add_argument("--confidence", type=float, default=0.0, help="Confidence score (0.0-1.0)")
    parser.add_argument("--defect-type", default="thermal defect", help="Type of defect detected")
    parser.add_argument("--roi", default="74,308,192,412", help="ROI coordinates: y1,y2,x1,x2")
    parser.add_argument("--iou", type=float, default=0.0, help="Intersection over Union")
    parser.add_argument("--organization", default="manufacturer", choices=["manufacturer", "mrolab"],
                        help="Organization submitting the inspection")

    args = parser.parse_args()

    # Validate file paths
    video_path = Path(args.video)
    image_path = Path(args.image)

    if not video_path.exists():
        print(f"✗ Video file not found: {video_path}")
        sys.exit(1)

    if not image_path.exists():
        print(f"✗ Image file not found: {image_path}")
        sys.exit(1)

    print("\n" + "="*60)
    print("AI DEFECT DETECTION - BLOCKCHAIN SUBMISSION")
    print("="*60)
    print(f"Part Number: {args.part_number}")
    print(f"Serial Number: {args.serial_number}")
    print(f"Material: {args.material_type}")
    print(f"Inspector: {args.inspector} (will be private)")
    print(f"Organization: {args.organization.upper()}")
    print("="*60 + "\n")

    # Step 1: Calculate file hashes
    print("Step 1: Calculating file hashes...")
    video_hash = calculate_sha256(video_path)
    image_hash = calculate_sha256(image_path)
    video_size = video_path.stat().st_size

    print(f"  Video hash: {video_hash}")
    print(f"  Video size: {video_size:,} bytes ({video_size/1024/1024:.2f} MB)")
    print(f"  Image hash: {image_hash}\n")

    # Step 2: Upload to IPFS
    print("Step 2: Uploading files to IPFS...")
    video_cid = upload_to_ipfs(video_path)
    image_cid = upload_to_ipfs(image_path)
    print(f"  Video IPFS URL: ipfs://{video_cid}")
    print(f"  Image IPFS URL: ipfs://{image_cid}")
    print(f"  Public gateway: https://ipfs.io/ipfs/{image_cid}\n")

    # Step 3: Parse ROI and bounding box
    roi_parts = args.roi.split(',')
    roi_y1, roi_y2, roi_x1, roi_x2 = map(int, roi_parts)

    bbox_x1, bbox_y1, bbox_x2, bbox_y2 = 0.0, 0.0, 0.0, 0.0
    defect_detected = False
    if args.bbox:
        bbox_parts = args.bbox.split(',')
        bbox_x1, bbox_y1, bbox_x2, bbox_y2 = map(float, bbox_parts)
        defect_detected = True

    # Step 4: Prepare inspection data
    inspection_data = {
        "partNumber": args.part_number,
        "serialNumber": args.serial_number,
        "materialType": args.material_type,
        "inspectionDate": datetime.now().isoformat(),
        "inspectionType": "Active Thermography",
        "inspector": args.inspector,
        "organization": "",  # Will be set by chaincode
        "rawVideoHash": f"sha256:{video_hash}",
        "rawVideoIPFS": video_cid,
        "rawVideoSize": video_size,
        "processedImageHash": f"sha256:{image_hash}",
        "processedImageIPFS": image_cid,
        "roi_y1": roi_y1,
        "roi_y2": roi_y2,
        "roi_x1": roi_x1,
        "roi_x2": roi_x2,
        "pulseTime": 13,  # Default from your notebook
        "pcaComponents": 10,
        "sequenceLength": 2000,
        "modelName": "cnn_attention_grdino",
        "modelVersion": "v1.0",
        "modelHash": "placeholder",  # TODO: Calculate model hash
        "defectDetected": defect_detected,
        "defectType": args.defect_type if defect_detected else "",
        "confidenceScore": args.confidence,
        "bbox_x1": bbox_x1,
        "bbox_y1": bbox_y1,
        "bbox_x2": bbox_x2,
        "bbox_y2": bbox_y2,
        "iou": args.iou,
        "centerDistance": 0.0,  # TODO: Calculate if ground truth available
        "normCenterDistance": 0.0,
        "hasGroundTruth": False,
        "gt_bbox_x1": 0.0,
        "gt_bbox_y1": 0.0,
        "gt_bbox_x2": 0.0,
        "gt_bbox_y2": 0.0,
        "txID": "",
        "blockchainTimestamp": "",
        "submittedAt": ""
    }

    print("Step 3: Preparing blockchain submission...")
    print(json.dumps(inspection_data, indent=2))
    print()

    # Step 5: Submit to blockchain
    cmd = submit_to_blockchain(inspection_data, args.organization)

    # Save command to file for manual execution
    script_path = Path("/home/lp502261/thermotrace-production/submit_inspection.sh")
    with open(script_path, "w") as f:
        f.write("#!/bin/bash\n")
        f.write("# Auto-generated blockchain submission script\n")
        f.write(f"# Generated: {datetime.now().isoformat()}\n\n")
        f.write(cmd)

    script_path.chmod(0o755)

    print(f"\n✓ Blockchain submission script saved to: {script_path}")
    print(f"\nTo submit to blockchain, run:")
    print(f"  cd /home/lp502261/thermotrace-production")
    print(f"  ./submit_inspection.sh")
    print("\n" + "="*60)
    print("SUMMARY")
    print("="*60)
    print(f"✓ Files hashed and uploaded to IPFS")
    print(f"✓ Video CID: {video_cid}")
    print(f"✓ Image CID: {image_cid}")
    print(f"✓ Ready for blockchain submission")
    print("="*60 + "\n")


if __name__ == "__main__":
    main()
