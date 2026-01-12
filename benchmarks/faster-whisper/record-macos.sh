#!/usr/bin/env bash
#
# Interactive audio recording script for macOS
# Records 10 Polish voice commands for Whisper benchmark
#
# Requirements: sox (brew install sox) or nix-shell -p sox

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUDIO_DIR="${SCRIPT_DIR}/audio"
COMMANDS_FILE="${SCRIPT_DIR}/test-commands.txt"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check for sox
if ! command -v sox &> /dev/null; then
    echo -e "${RED}Error: sox is not installed${NC}"
    echo "Install with: brew install sox"
    exit 1
fi

if ! command -v rec &> /dev/null; then
    echo -e "${RED}Error: rec command not found (should come with sox)${NC}"
    exit 1
fi

# Create audio directory
mkdir -p "${AUDIO_DIR}"

# Load commands
if [ ! -f "${COMMANDS_FILE}" ]; then
    echo -e "${RED}Error: ${COMMANDS_FILE} not found${NC}"
    exit 1
fi

# Read commands into array (bash 3.2 compatible)
COMMANDS=()
while IFS= read -r line; do
    COMMANDS+=("$line")
done < "${COMMANDS_FILE}"

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Faster-Whisper Benchmark - Audio Recording   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Recording ${#COMMANDS[@]} Polish voice commands${NC}"
echo ""
echo "Format: 16kHz, mono, WAV"
echo "Press ${GREEN}ENTER${NC} to start recording, ${GREEN}ENTER${NC} again to stop"
echo ""
echo -e "${YELLOW}Tips:${NC}"
echo "  • Speak naturally at normal volume"
echo "  • Typical distance from microphone"
echo "  • Avoid background noise"
echo ""

read -p "Press ENTER to begin..."
echo ""

for i in "${!COMMANDS[@]}"; do
    NUM=$((i + 1))
    FILENAME=$(printf "%02d.wav" "${NUM}")
    FILEPATH="${AUDIO_DIR}/${FILENAME}"
    COMMAND="${COMMANDS[i]}"

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Recording ${NUM}/${#COMMANDS[@]}:${NC} ${YELLOW}${COMMAND}${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Wait for user to be ready
    read -p "Press ENTER to start recording..."

    # Record with visual feedback
    echo -e "${RED}● RECORDING... (auto-stops after 2s silence)${NC}"

    # Use rec with 16kHz mono 16-bit (matches Wyoming/HA Voice Preview)
    # Auto-stops on silence: 1s of silence at start, 2s at end
    rec -r 16000 -c 1 -b 16 "${FILEPATH}" silence 1 0.1 3% 1 2.0 3% 2>/dev/null || true

    # Normalize audio
    if [ -f "${FILEPATH}" ]; then
        if sox "${FILEPATH}" "${FILEPATH}.tmp" norm 2>/dev/null; then
            mv "${FILEPATH}.tmp" "${FILEPATH}"
        else
            echo -e "${YELLOW}Warning: Normalization failed, keeping original${NC}"
        fi
    else
        echo -e "${RED}Error: Recording failed${NC}"
        continue
    fi

    # Get duration
    DURATION=$(soxi -D "${FILEPATH}" 2>/dev/null || echo "unknown")

    echo -e "${GREEN}✓ Saved:${NC} ${FILENAME} (${DURATION}s)"
    echo ""
done

echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          Recording Complete!                   ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo "Recorded ${#COMMANDS[@]} audio files to: ${AUDIO_DIR}"
echo ""
echo "Next steps:"
echo "  1. Review recordings: ls -lh ${AUDIO_DIR}/*.wav"
echo "  2. Commit files: git add ${AUDIO_DIR}/*.wav"
echo "  3. Build Docker image"
echo ""
