#!/bin/bash
set -e

echo "=========================================="
echo "Importing Blade Inspection Data"
echo "=========================================="

export PATH=$HOME/thermotrace-production/bin:$PATH
export FABRIC_CFG_PATH=$PWD/../../config

# Set environment for MROLab peer
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="MROLabMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/../../organizations/peerOrganizations/mrolab.thermotrace.com/peers/peer0.mrolab.thermotrace.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=$PWD/../../organizations/peerOrganizations/mrolab.thermotrace.com/users/Admin@mrolab.thermotrace.com/msp
export CORE_PEER_ADDRESS=peer0.mrolab.thermotrace.com:7051
export ORDERER_CA=$PWD/../../organizations/ordererOrganizations/thermotrace.com/orderers/orderer1.thermotrace.com/msp/tlscacerts/tlsca.thermotrace.com-cert.pem

# Function to parse measurement (convert inches to mm, handle N/A)
parse_measurement() {
    local value="$1"
    
    # Remove spaces and quotes
    value=$(echo "$value" | tr -d ' "')
    
    # Handle empty or N/A
    if [ -z "$value" ] || [ "$value" = "N/A" ]; then
        echo "0.0"
        return
    fi
    
    # Check if it has "mm" suffix
    if [[ "$value" == *"mm"* ]]; then
        # Remove "mm" and return
        echo "$value" | sed 's/mm//'
        return
    fi
    
    # If numeric and < 20, assume inches and convert to mm
    if [[ "$value" =~ ^[0-9.]+$ ]]; then
        if (( $(echo "$value < 20" | bc -l) )); then
            # Convert inches to mm (multiply by 25.4)
            echo "$value * 25.4" | bc -l
            return
        fi
    fi
    
    # Otherwise return as-is
    echo "$value" | sed 's/[^0-9.]//g'
}

# Function to import CSV file
import_csv() {
    local csv_file=$1
    local occasion=$2
    
    echo ""
    echo "Processing: $csv_file ($occasion)"
    echo "----------------------------------------"
    
    if [ ! -f "$csv_file" ]; then
        echo "Error: File not found: $csv_file"
        return
    fi
    
    local count=0
    local success=0
    local errors=0
    
    # Skip header line and process data
    tail -n +2 "$csv_file" | while IFS=',' read -r pn sn ar ap an am al ak aj ah ag af ae ad ac ab rest; do
        # Skip empty lines
        [ -z "$pn" ] && continue
        
        count=$((count + 1))
        
        # Clean part number and serial number
        pn=$(echo "$pn" | tr -d ' "')
        sn=$(echo "$sn" | tr -d ' "')
        
        # Parse all measurements
        ar_val=$(parse_measurement "$ar")
        ap_val=$(parse_measurement "$ap")
        an_val=$(parse_measurement "$an")
        am_val=$(parse_measurement "$am")
        al_val=$(parse_measurement "$al")
        ak_val=$(parse_measurement "$ak")
        aj_val=$(parse_measurement "$aj")
        ah_val=$(parse_measurement "$ah")
        ag_val=$(parse_measurement "$ag")
        af_val=$(parse_measurement "$af")
        ae_val=$(parse_measurement "$ae")
        ad_val=$(parse_measurement "$ad")
        ac_val=$(parse_measurement "$ac")
        ab_val=$(parse_measurement "$ab")
        
        # Create JSON for inspection
        inspection_json=$(cat <<INSPJSON
{
  "partNumber": "$pn",
  "serialNumber": "$sn",
  "occasion": "$occasion",
  "inspectionDate": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "inspector": "DataImport",
  "organization": "MROLabMSP",
  "measurements": {
    "ar": $ar_val,
    "ap": $ap_val,
    "an": $an_val,
    "am": $am_val,
    "al": $al_val,
    "ak": $ak_val,
    "aj": $aj_val,
    "ah": $ah_val,
    "ag": $ag_val,
    "af": $af_val,
    "ae": $ae_val,
    "ad": $ad_val,
    "ac": $ac_val,
    "ab": $ab_val
  },
  "csvHash": "",
  "recordedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
INSPJSON
)
        
        # Submit to blockchain
        echo -n "  Importing ${pn}_${sn}_${occasion}... "
        
        if peer chaincode invoke \
            -o orderer1.thermotrace.com:7050 \
            --ordererTLSHostnameOverride orderer1.thermotrace.com \
            --tls --cafile ${ORDERER_CA} \
            -C inspection-channel \
            -n bladeinspection \
            --peerAddresses peer0.mrolab.thermotrace.com:7051 \
            --tlsRootCertFiles $PWD/../../organizations/peerOrganizations/mrolab.thermotrace.com/peers/peer0.mrolab.thermotrace.com/tls/ca.crt \
            --peerAddresses peer0.manufacturer.thermotrace.com:9051 \
            --tlsRootCertFiles $PWD/../../organizations/peerOrganizations/manufacturer.thermotrace.com/peers/peer0.manufacturer.thermotrace.com/tls/ca.crt \
            -c "{\"function\":\"AddInspection\",\"Args\":[\"$inspection_json\"]}" \
            2>&1 | grep -q "Chaincode invoke successful"; then
            echo "✓"
            success=$((success + 1))
        else
            echo "✗"
            errors=$((errors + 1))
        fi
        
        # Small delay to avoid overwhelming the network
        sleep 1
    done
    
    echo "  Processed: $(tail -n +2 "$csv_file" | wc -l) records"
}

# Import all three CSV files
DATA_DIR="$PWD/../../sample-data"

import_csv "$DATA_DIR/before_surfacing.csv" "before_surfacing"
import_csv "$DATA_DIR/manual.csv" "manual"
import_csv "$DATA_DIR/after_surfacing.csv" "after_surfacing"

echo ""
echo "=========================================="
echo "Import Complete!"
echo "=========================================="
echo ""
echo "Querying total inspection count..."
peer chaincode query -C inspection-channel -n bladeinspection -c '{"Args":["GetInspectionCount"]}'

echo ""
echo "Checking blockchain height..."
peer channel getinfo -c inspection-channel
