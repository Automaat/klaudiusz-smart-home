#!/usr/bin/env bash
# Transfer samples to homelab and retrain wake word model

set -euo pipefail

SAMPLES_DIR="samples/klaudiusz_real"

if [ ! -d "$SAMPLES_DIR" ]; then
    echo "Error: $SAMPLES_DIR not found. Run ./record_wake_word.sh first."
    exit 1
fi

SAMPLE_COUNT=$(find "$SAMPLES_DIR" -name "*.wav" | wc -l | tr -d ' ')

if [ "$SAMPLE_COUNT" -lt 10 ]; then
    echo "Error: Only $SAMPLE_COUNT samples found. Need at least 10."
    echo "Run ./record_wake_word.sh to record more samples."
    exit 1
fi

echo "====================================="
echo "Wake Word Retraining"
echo "====================================="
echo "Found: $SAMPLE_COUNT real voice samples"
echo ""

# Step 1: Transfer samples
echo "Step 1: Transferring samples to homelab..."
ssh -o MACs=hmac-sha2-512-etm@openssh.com homelab "mkdir -p /home/admin/wake-word-training/samples/klaudiusz_real"
rsync -avz -e "ssh -o MACs=hmac-sha2-512-etm@openssh.com" "$SAMPLES_DIR/" homelab:/home/admin/wake-word-training/samples/klaudiusz_real/

# Step 2: Replace synthetic with real samples
echo ""
echo "Step 2: Mixing real samples with synthetic..."
ssh -o MACs=hmac-sha2-512-etm@openssh.com homelab "cd /home/admin/wake-word-training && \
    cp samples/klaudiusz_real/*.wav samples/klaudiusz/"

# Step 3: Retrain model
echo ""
echo "Step 3: Training model (this takes ~10-15 minutes)..."
ssh -o MACs=hmac-sha2-512-etm@openssh.com homelab "cd /home/admin/wake-word-training && \
    ./run-training.sh"

# Step 4: Convert to TFLite
echo ""
echo "Step 4: Converting to TFLite format..."
ssh -o MACs=hmac-sha2-512-etm@openssh.com homelab "cd /home/admin/wake-word-training && \
    python3 convert_to_tflite.py"

# Step 5: Copy to repo
echo ""
echo "Step 5: Copying model back to Mac..."
scp -o MACs=hmac-sha2-512-etm@openssh.com \
    homelab:/home/admin/wake-word-training/pl_klaudiusz.tflite \
    hosts/homelab/home-assistant/wake-words/
scp -o MACs=hmac-sha2-512-etm@openssh.com \
    homelab:/home/admin/wake-word-training/pl_klaudiusz.onnx \
    hosts/homelab/home-assistant/wake-words/

echo ""
echo "====================================="
echo "✅ Retraining complete!"
echo "====================================="
echo ""
echo "Next steps:"
echo "1. Commit updated model: git add hosts/homelab/home-assistant/wake-words/*.{onnx,tflite}"
echo "2. Create PR with new model"
echo "3. After merge, Comin will auto-deploy to homelab"
echo ""
echo "Or test immediately on homelab:"
echo "  ssh homelab 'sudo systemctl restart wyoming-openwakeword'"
