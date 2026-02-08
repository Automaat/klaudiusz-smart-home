#!/usr/bin/env python3
"""Convert ONNX wake word model to TFLite format for Wyoming-openWakeWord."""

import os
import tempfile
import subprocess

def convert_onnx_to_tflite(onnx_path, tflite_path):
    """Convert ONNX model to TFLite format using onnx2tf."""
    print(f"Loading ONNX model: {onnx_path}")

    if not os.path.exists(onnx_path):
        raise FileNotFoundError(f"ONNX model not found: {onnx_path}")

    print("Converting to TFLite using onnx2tf...")

    # Create temp directory for intermediate outputs
    with tempfile.TemporaryDirectory() as tmp_dir:
        # Run onnx2tf conversion
        cmd = [
            "onnx2tf",
            "-i", onnx_path,
            "-o", tmp_dir,
            "-osd"  # Output SavedModel and TFLite
        ]

        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode != 0:
            print("STDOUT:", result.stdout)
            print("STDERR:", result.stderr)
            raise RuntimeError(f"onnx2tf conversion failed: {result.stderr}")

        # Find generated tflite file
        tflite_files = [f for f in os.listdir(tmp_dir) if f.endswith('.tflite')]

        if not tflite_files:
            raise RuntimeError(f"No .tflite file generated in {tmp_dir}")

        # Copy the tflite file to destination
        import shutil
        src = os.path.join(tmp_dir, tflite_files[0])
        shutil.copy(src, tflite_path)

    # Verify file was created
    if os.path.exists(tflite_path):
        size = os.path.getsize(tflite_path)
        print(f"✓ Conversion successful! Output: {tflite_path} ({size/1024:.1f} KB)")
    else:
        raise RuntimeError("Conversion failed - output file not created")

if __name__ == "__main__":
    onnx_path = "hosts/homelab/home-assistant/wake-words/pl_klaudiusz.onnx"
    tflite_path = "hosts/homelab/home-assistant/wake-words/pl_klaudiusz.tflite"

    convert_onnx_to_tflite(onnx_path, tflite_path)
