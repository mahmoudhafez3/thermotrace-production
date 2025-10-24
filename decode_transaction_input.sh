#!/bin/bash

# Script to decode transaction input from Explorer database
# Usage: ./decode_transaction_input.sh <transaction_id>

TXID=$1

if [ -z "$TXID" ]; then
    echo "Usage: $0 <transaction_id>"
    exit 1
fi

echo "Fetching chaincode input for transaction: $TXID"
echo "================================================"
echo ""

# Get the hex-encoded chaincode input from Explorer database
HEX_INPUT=$(docker exec explorerdb.mynetwork.com psql -U hppoc -d fabricexplorer -t -c \
    "SELECT chaincode_proposal_input FROM transactions WHERE txhash = '$TXID';")

if [ -z "$HEX_INPUT" ]; then
    echo "Transaction not found in Explorer database"
    exit 1
fi

# Split by comma (multiple arguments are comma-separated)
IFS=',' read -ra ARGS <<< "$HEX_INPUT"

echo "Number of arguments: ${#ARGS[@]}"
echo ""

ARG_NUM=0
for arg in "${ARGS[@]}"; do
    # Trim whitespace
    arg=$(echo "$arg" | tr -d '[:space:]')

    echo "=== Argument $ARG_NUM ==="

    # Convert hex to ASCII
    decoded=$(echo "$arg" | xxd -r -p 2>/dev/null)

    # Check if it's a Buffer object (contains "type":"Buffer")
    if echo "$decoded" | grep -q '"type":"Buffer"'; then
        # It's a Buffer object, extract the data array and convert
        echo "$decoded" | jq -r '.data | map(. | tostring) | join(" ")' | \
        while read -r bytes; do
            for byte in $bytes; do
                printf "\\x$(printf '%02x' $byte)"
            done
        done | xxd -r
    else
        # Just print the decoded string
        echo "$decoded"
    fi

    echo ""
    echo ""

    ARG_NUM=$((ARG_NUM + 1))
done
