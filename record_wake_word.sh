#!/usr/bin/env bash
# Record wake word samples on Mac for training
# Records 16kHz mono WAV files compatible with openWakeWord

set -euo pipefail

SAMPLES_DIR="samples/klaudiusz_real"
NUM_SAMPLES="${1:-50}"

# Check if sox is installed
if ! command -v sox &> /dev/null; then
    echo "Error: sox not installed. Install with: brew install sox"
    exit 1
fi

# Create samples directory
mkdir -p "$SAMPLES_DIR"

echo "====================================="
echo "Wake Word Recording Script"
echo "====================================="
echo "Recording $NUM_SAMPLES samples of 'Klaudiusz'"
echo "Target: 16kHz, mono, 2 seconds each"
echo ""
echo "Tips:"
echo "- Speak clearly at normal volume"
echo "- Vary your intonation and speed"
echo "- Try different distances from mic"
echo "- Record in different room locations"
echo ""
read -p "Press Enter to start recording..."

for i in $(seq 1 "$NUM_SAMPLES"); do
    OUTPUT_FILE="$SAMPLES_DIR/real_$(printf %04d "$i").wav"

    echo ""
    echo "[$i/$NUM_SAMPLES] Recording in 3..."
    sleep 1
    echo "2..."
    sleep 1
    echo "1..."
    sleep 1
    echo "🔴 SAY 'KLAUDIUSZ' NOW!"

    # Record 2 seconds, 16kHz mono
    sox -d -r 16000 -c 1 -b 16 "$OUTPUT_FILE" trim 0 2 silence 1 0.1 1% 1 1.0 1% 2>/dev/null || true

    echo "✅ Recorded: $OUTPUT_FILE"

    # Play back for verification
    echo "Playing back..."
    afplay "$OUTPUT_FILE"

    # Pause between recordings
    if [ "$i" -lt "$NUM_SAMPLES" ]; then
        echo "Next recording in 2 seconds..."
        sleep 2
    fi
done

echo ""
echo "====================================="
echo "✅ Recording complete!"
echo "====================================="
echo "Recorded: $NUM_SAMPLES samples"
echo "Location: $SAMPLES_DIR"
echo "Total size: $(du -sh "$SAMPLES_DIR" | cut -f1)"
echo ""
echo "Next steps:"
echo "1. Review samples (delete bad ones)"
echo "2. Transfer to homelab: rsync -avz $SAMPLES_DIR/ homelab:/home/admin/wake-word-training/samples/klaudiusz_real/"
echo "3. SSH to homelab and retrain model"
