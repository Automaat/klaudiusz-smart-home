#!/usr/bin/env python3
"""
Faster-Whisper GPU Benchmark

Tests transcription performance of different Whisper models on NVIDIA GPU.
Downloads models on first run, caches for subsequent runs.
"""

import argparse
import json
import os
import platform
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional

import numpy as np
import soundfile as sf
import torch
from faster_whisper import WhisperModel
from jiwer import wer
from tqdm import tqdm

# Configuration
MODELS = ["small", "medium", "large-v3"]
ITERATIONS = 5
CACHE_DIR = Path("/cache/models")
AUDIO_DIR = Path("/app/audio")
RESULTS_DIR = Path("/results")
TEST_COMMANDS_FILE = Path("/app/test-commands.txt")


def get_gpu_info() -> Dict[str, str]:
    """Get NVIDIA GPU information."""
    try:
        result = subprocess.run(
            ["nvidia-smi", "--query-gpu=name,driver_version,memory.total", "--format=csv,noheader"],
            capture_output=True,
            text=True,
            check=True
        )
        gpu_name, driver_version, vram_total = result.stdout.strip().split(", ")

        cuda_version = torch.version.cuda if torch.cuda.is_available() else "N/A"

        return {
            "gpu_name": gpu_name,
            "driver_version": driver_version,
            "vram_total_mb": int(vram_total.replace(" MiB", "")),
            "cuda_version": cuda_version,
            "cuda_available": torch.cuda.is_available()
        }
    except Exception as e:
        return {
            "error": str(e),
            "cuda_available": torch.cuda.is_available()
        }


def get_vram_usage() -> int:
    """Get current VRAM usage in MB."""
    if torch.cuda.is_available():
        return torch.cuda.memory_allocated() // (1024 * 1024)
    return 0


def load_ground_truth() -> Dict[str, str]:
    """Load ground truth transcriptions from test-commands.txt."""
    ground_truth = {}
    if TEST_COMMANDS_FILE.exists():
        with open(TEST_COMMANDS_FILE, "r", encoding="utf-8") as f:
            for i, line in enumerate(f, start=1):
                ground_truth[f"{i:02d}.wav"] = line.strip()
    return ground_truth


def load_audio_files() -> List[Dict[str, any]]:
    """Load all WAV files from audio directory."""
    audio_files = []
    ground_truth = load_ground_truth()

    for wav_file in sorted(AUDIO_DIR.glob("*.wav")):
        try:
            audio, sample_rate = sf.read(wav_file)
            duration = len(audio) / sample_rate

            audio_files.append({
                "filename": wav_file.name,
                "path": wav_file,
                "duration": duration,
                "sample_rate": sample_rate,
                "ground_truth": ground_truth.get(wav_file.name, "")
            })
        except Exception as e:
            print(f"Warning: Could not load {wav_file}: {e}")

    return audio_files


def download_model(model_size: str) -> None:
    """Download and cache a Whisper model."""
    print(f"\nDownloading model: {model_size}")
    model_path = CACHE_DIR / model_size

    if model_path.exists():
        print(f"Model {model_size} already cached")
        return

    # Create a temporary model to trigger download
    print(f"Downloading {model_size} model (this may take a few minutes)...")
    _ = WhisperModel(
        model_size,
        device="cpu",  # Use CPU for download to avoid VRAM allocation
        compute_type="int8",
        download_root=str(CACHE_DIR)
    )
    print(f"✓ Model {model_size} downloaded and cached")


def benchmark_model(
    model_size: str,
    audio_files: List[Dict[str, any]],
    device: str,
    compute_type: str,
    iterations: int = ITERATIONS
) -> Dict[str, any]:
    """Benchmark a single model."""
    print(f"\n{'='*60}")
    print(f"Benchmarking: {model_size} (device={device}, compute_type={compute_type})")
    print(f"{'='*60}")

    # Load model
    print(f"Loading model...")
    if device == "cuda":
        torch.cuda.empty_cache()
    vram_before = get_vram_usage() if device == "cuda" else 0

    model = WhisperModel(
        model_size,
        device=device,
        compute_type=compute_type,
        download_root=str(CACHE_DIR)
    )

    vram_after = get_vram_usage() if device == "cuda" else 0
    vram_model = vram_after - vram_before

    if device == "cuda":
        print(f"Model loaded (VRAM: {vram_model} MB)")
    else:
        print(f"Model loaded (CPU mode)")

    # Warm-up run
    print("Warming up...")
    segments, _ = model.transcribe(str(audio_files[0]["path"]), language="pl", beam_size=5)
    list(segments)  # Force execution

    # Benchmark runs
    all_latencies = []
    all_transcriptions = []

    print(f"\nRunning {iterations} iterations on {len(audio_files)} audio files...")

    for iteration in range(iterations):
        for audio_info in tqdm(audio_files, desc=f"Iteration {iteration + 1}/{iterations}", leave=False):
            start_time = time.time()

            segments, info = model.transcribe(
                str(audio_info["path"]),
                language="pl",
                beam_size=5
            )

            # Force execution and collect transcription
            transcription = " ".join(segment.text for segment in segments).strip()

            end_time = time.time()
            latency = (end_time - start_time) * 1000  # Convert to ms

            all_latencies.append(latency)

            if iteration == 0:  # Only save transcriptions from first iteration
                all_transcriptions.append({
                    "filename": audio_info["filename"],
                    "transcription": transcription,
                    "ground_truth": audio_info["ground_truth"],
                    "duration": audio_info["duration"]
                })

    # Calculate metrics
    latencies = np.array(all_latencies)
    total_audio_duration = sum(a["duration"] for a in audio_files) * iterations
    total_processing_time = latencies.sum() / 1000  # Convert to seconds
    realtime_factor = total_audio_duration / total_processing_time

    # Calculate WER if ground truth available
    wer_score = None
    if all(t["ground_truth"] for t in all_transcriptions):
        references = [t["ground_truth"] for t in all_transcriptions]
        hypotheses = [t["transcription"] for t in all_transcriptions]
        wer_score = wer(references, hypotheses)

    results = {
        "model": model_size,
        "device": device,
        "compute_type": compute_type,
        "iterations": iterations,
        "audio_files_count": len(audio_files),
        "total_audio_duration_sec": round(total_audio_duration, 2),
        "total_processing_time_sec": round(total_processing_time, 2),
        "mean_latency_ms": round(float(np.mean(latencies)), 2),
        "median_latency_ms": round(float(np.median(latencies)), 2),
        "p95_latency_ms": round(float(np.percentile(latencies, 95)), 2),
        "p99_latency_ms": round(float(np.percentile(latencies, 99)), 2),
        "std_latency_ms": round(float(np.std(latencies)), 2),
        "realtime_factor": round(realtime_factor, 2),
        "vram_used_mb": vram_model if device == "cuda" else None,
        "wer": round(wer_score, 4) if wer_score is not None else None,
        "transcriptions": all_transcriptions
    }

    # Print summary
    print(f"\nResults:")
    print(f"  Mean latency:     {results['mean_latency_ms']:.2f} ms")
    print(f"  P95 latency:      {results['p95_latency_ms']:.2f} ms")
    print(f"  Real-time factor: {results['realtime_factor']:.1f}x")
    if device == "cuda":
        print(f"  VRAM used:        {results['vram_used_mb']} MB")
    if wer_score is not None:
        print(f"  WER:              {results['wer']:.2%}")

    # Cleanup
    del model
    if device == "cuda":
        torch.cuda.empty_cache()

    return results


def validate_setup(dry_run: bool = False, device: str = "cuda") -> Dict[str, any]:
    """Validate benchmark setup without running full benchmark."""
    print("Validating benchmark setup...")
    print("=" * 60)

    validation = {"errors": [], "warnings": [], "info": []}

    # Check audio files
    print("\n✓ Checking audio files...")
    ground_truth = load_ground_truth()
    audio_files = load_audio_files()

    if not audio_files:
        validation["errors"].append("No audio files found in /app/audio/")
    else:
        validation["info"].append(f"Found {len(audio_files)} audio files")
        total_duration = sum(a["duration"] for a in audio_files)
        validation["info"].append(f"Total audio duration: {total_duration:.2f}s")

        # Validate audio format
        for audio_info in audio_files:
            if audio_info["sample_rate"] != 16000:
                validation["warnings"].append(f"{audio_info['filename']}: sample rate {audio_info['sample_rate']}Hz (expected 16000Hz)")
            if audio_info["duration"] < 1.0:
                validation["warnings"].append(f"{audio_info['filename']}: duration {audio_info['duration']:.2f}s (very short)")

    # Check ground truth
    if ground_truth:
        validation["info"].append(f"Ground truth available for WER calculation")
    else:
        validation["warnings"].append("No ground truth found (WER will not be calculated)")

    # Check device (GPU or CPU)
    if not dry_run:
        if device == "cuda":
            print("\n✓ Checking GPU...")
            if not torch.cuda.is_available():
                validation["errors"].append("CUDA not available - GPU required for GPU benchmark")
            else:
                gpu_info = get_gpu_info()
                validation["info"].append(f"GPU: {gpu_info.get('gpu_name', 'Unknown')}")
                validation["info"].append(f"CUDA: {gpu_info.get('cuda_version', 'N/A')}")
                validation["info"].append(f"VRAM: {gpu_info.get('vram_total_mb', 0)} MB")
        else:
            print("\n✓ Checking CPU...")
            validation["info"].append(f"CPU mode enabled")
            validation["info"].append(f"Platform: {platform.platform()}")
    else:
        print("\n⊘ Skipping device check (dry-run mode)")
        validation["info"].append("Device check skipped (dry-run)")

    # Check cache directory
    print("\n✓ Checking cache directory...")
    if not CACHE_DIR.exists():
        validation["warnings"].append(f"Cache directory {CACHE_DIR} does not exist (will be created)")
    else:
        validation["info"].append(f"Cache directory: {CACHE_DIR}")

    # Check models (don't download in dry-run)
    print("\n✓ Checking models...")
    validation["info"].append(f"Models to test: {', '.join(MODELS)}")
    if not dry_run:
        for model_size in MODELS:
            model_path = CACHE_DIR / model_size
            if model_path.exists():
                validation["info"].append(f"Model {model_size}: cached")
            else:
                validation["info"].append(f"Model {model_size}: will download (~{_get_model_size(model_size)})")

    return validation


def _get_model_size(model: str) -> str:
    """Get approximate download size for model."""
    sizes = {"small": "1GB", "medium": "1.5GB", "large-v3": "2GB"}
    return sizes.get(model, "unknown")


def main():
    """Main benchmark function."""
    parser = argparse.ArgumentParser(description="Faster-Whisper Benchmark")
    parser.add_argument("--dry-run", action="store_true",
                       help="Validate setup without running benchmark")
    parser.add_argument("--cpu", action="store_true",
                       help="Run benchmark on CPU instead of GPU (for baseline comparison)")
    args = parser.parse_args()

    # Determine device and compute type
    if args.cpu:
        device = "cpu"
        compute_type = "int8"
        device_label = "CPU"
    else:
        device = "cuda"
        compute_type = "float16"
        device_label = "GPU"

    print(f"Faster-Whisper Benchmark ({device_label})")
    print("=" * 60)

    if args.dry_run:
        print("\n[DRY RUN MODE - Validation Only]\n")

    # Validate setup
    validation = validate_setup(dry_run=args.dry_run, device=device)

    # Print validation results
    print("\n" + "=" * 60)
    print("VALIDATION RESULTS")
    print("=" * 60)

    if validation["info"]:
        print("\n✓ Info:")
        for info in validation["info"]:
            print(f"  • {info}")

    if validation["warnings"]:
        print("\n⚠ Warnings:")
        for warning in validation["warnings"]:
            print(f"  • {warning}")

    if validation["errors"]:
        print("\n✗ Errors:")
        for error in validation["errors"]:
            print(f"  • {error}")
        print("\n" + "=" * 60)
        print("VALIDATION FAILED")
        print("=" * 60)
        sys.exit(1)

    print("\n" + "=" * 60)
    print("VALIDATION PASSED")
    print("=" * 60)

    # Exit if dry-run
    if args.dry_run:
        print("\nDry-run complete. Setup is valid.")
        print("Run without --dry-run to execute benchmark.")
        sys.exit(0)

    # Continue with actual benchmark
    print(f"\nStarting benchmark on {device_label}...")

    # Print system info
    if device == "cuda":
        # Check GPU availability
        if not torch.cuda.is_available():
            print("ERROR: CUDA is not available. Use --cpu for CPU benchmark or install CUDA drivers.")
            sys.exit(1)

        gpu_info = get_gpu_info()
        print(f"\nGPU: {gpu_info.get('gpu_name', 'Unknown')}")
        print(f"CUDA Version: {gpu_info.get('cuda_version', 'N/A')}")
        print(f"Driver Version: {gpu_info.get('driver_version', 'N/A')}")
        print(f"VRAM: {gpu_info.get('vram_total_mb', 0)} MB")
    else:
        print(f"\nCPU: {platform.processor() or platform.machine()}")
        print(f"Platform: {platform.platform()}")

    # Create output directory
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)

    # Download models if needed
    print("\n" + "=" * 60)
    print("Checking model cache...")
    print("=" * 60)
    for model_size in MODELS:
        download_model(model_size)

    # Load audio files
    print("\n" + "=" * 60)
    print("Loading audio files...")
    print("=" * 60)
    audio_files = load_audio_files()

    if not audio_files:
        print("ERROR: No audio files found in /app/audio/")
        sys.exit(1)

    print(f"Loaded {len(audio_files)} audio files")
    total_duration = sum(a["duration"] for a in audio_files)
    print(f"Total audio duration: {total_duration:.2f} seconds")

    # Run benchmarks
    all_results = []
    for model_size in MODELS:
        try:
            result = benchmark_model(model_size, audio_files, device, compute_type)
            all_results.append(result)
        except Exception as e:
            print(f"\nERROR benchmarking {model_size}: {e}")
            import traceback
            traceback.print_exc()

    # Save results
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_file = RESULTS_DIR / f"benchmark_{timestamp}.json"

    # Build system info
    system_info = {
        "platform": platform.platform(),
        "python_version": platform.python_version()
    }
    if device == "cuda":
        system_info.update(get_gpu_info())
    else:
        system_info["cpu"] = platform.processor() or platform.machine()

    output_data = {
        "timestamp": timestamp,
        "system": system_info,
        "config": {
            "device": device,
            "compute_type": compute_type,
            "iterations": ITERATIONS,
            "models": MODELS
        },
        "audio": {
            "count": len(audio_files),
            "total_duration_sec": round(total_duration, 2),
            "files": [
                {
                    "filename": a["filename"],
                    "duration": round(a["duration"], 2),
                    "sample_rate": a["sample_rate"]
                }
                for a in audio_files
            ]
        },
        "results": all_results
    }

    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(output_data, f, indent=2, ensure_ascii=False)

    print("\n" + "=" * 60)
    print("BENCHMARK COMPLETE")
    print("=" * 60)
    print(f"\nResults saved to: {output_file}")
    print("\nSummary:")
    for result in all_results:
        print(f"\n{result['model']}:")
        print(f"  Latency:      {result['mean_latency_ms']:.2f} ms (mean)")
        print(f"  Throughput:   {result['realtime_factor']:.1f}x realtime")
        if result['vram_used_mb'] is not None:
            print(f"  VRAM:         {result['vram_used_mb']} MB")
        if result['wer'] is not None:
            print(f"  WER:          {result['wer']:.2%}")


if __name__ == "__main__":
    main()
