#!/bin/bash
# Decode all base64 encoded data in a Fabric block

BLOCK_FILE=$1

if [ -z "$BLOCK_FILE" ]; then
    echo "Usage: ./decode_block.sh block_N.json"
    exit 1
fi

OUTPUT_FILE="${BLOCK_FILE%.json}_decoded.json"

# Decode base64 args if they exist
cat "$BLOCK_FILE" | jq '
  walk(
    if type == "object" and has("args") and (.args | type == "array") then
      .args |= map(
        if type == "string" and (. | test("^[A-Za-z0-9+/=]+$")) then
          (. | @base64d // .)
        else
          .
        end
      )
    else
      .
    end
  )
' > "$OUTPUT_FILE"

echo "Decoded block saved to: $OUTPUT_FILE"
