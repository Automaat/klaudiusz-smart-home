#!/usr/bin/env bash
# Generate wake word sample using homelab's Piper TTS

echo "Klaudiusz" | ssh homelab "echo 'Klaudiusz' | wyoming-piper --voice pl_PL-darkman-medium --output-file -" > klaudiusz_sample.wav

echo "Generated: klaudiusz_sample.wav"
