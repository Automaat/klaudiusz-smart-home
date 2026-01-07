# Faster-Whisper GPU Benchmark

Benchmark tool for testing faster-whisper transcription performance with NVIDIA GPUs.

Tests multiple Whisper models (small, medium, large-v3) on GPU with Polish voice commands.

## Prerequisites

**Required:**
- Docker Desktop for Windows/Linux
- NVIDIA GPU with CUDA support
- NVIDIA GPU drivers (version 495.29+)

**Automatic:**
- NVIDIA Container Toolkit (included with Docker Desktop)
- CUDA 12.1 (included in Docker image)
- Python dependencies (included in Docker image)

## Quick Start

```bash
# 1. Pull Docker image
docker pull ghcr.io/mskalski/faster-whisper-benchmark:latest

# 2. Create directories
mkdir cache results

# 3. Run benchmark
docker run --gpus all \
  -v ./cache:/cache \
  -v ./results:/results \
  ghcr.io/mskalski/faster-whisper-benchmark:latest
```

## First Run

On first execution, models will be downloaded to `./cache` (~4GB total):
- small: ~1GB
- medium: ~1.5GB
- large-v3: ~2GB

This takes approximately 3-5 minutes depending on network speed.

**Progress indicators will be shown during download.**

## Subsequent Runs

Cached models are reused automatically. No download needed.

To run again:
```bash
docker run --gpus all -v ./cache:/cache -v ./results:/results ghcr.io/mskalski/faster-whisper-benchmark:latest
```

## Output

Results saved to `./results/benchmark_YYYYMMDD_HHMMSS.json`

**Example output:**
```
GPU: NVIDIA RTX 4090 (24GB)
Testing 10 audio samples (32.5s total)

small:     0.12s avg (270x realtime) | 1.2GB VRAM | WER: 0%
medium:    0.35s avg (93x realtime)  | 2.8GB VRAM | WER: 0%
large-v3:  0.95s avg (34x realtime)  | 5.1GB VRAM | WER: 0%

Results: ./results/benchmark_20260107_143022.json
```

## JSON Schema

```json
{
  "timestamp": "20260107_143022",
  "system": {
    "gpu_name": "NVIDIA RTX 4090",
    "cuda_version": "12.1",
    "driver_version": "545.29",
    "vram_total_mb": 24576
  },
  "results": [
    {
      "model": "small",
      "device": "cuda",
      "compute_type": "float16",
      "mean_latency_ms": 120,
      "p95_latency_ms": 145,
      "realtime_factor": 270,
      "vram_used_mb": 1200,
      "wer": 0.0
    }
  ]
}
```

## Disk Usage

**Docker image:** ~3GB
**Model cache:** ~4GB (after first run)
**Results:** <1MB per run

**Total:** ~7GB

## Cleanup

Remove model cache after benchmark:
```bash
rm -rf cache/
```

Remove results:
```bash
rm -rf results/
```

Remove Docker image:
```bash
docker rmi ghcr.io/mskalski/faster-whisper-benchmark:latest
```

## Troubleshooting

### GPU not detected
```
ERROR: CUDA is not available
```

**Solutions:**
1. Ensure NVIDIA drivers installed: `nvidia-smi`
2. Check Docker has GPU access: `docker run --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi`
3. Restart Docker Desktop
4. Update NVIDIA drivers to 495.29+

### Out of VRAM

```
torch.cuda.OutOfMemoryError
```

Models require minimum VRAM:
- small: 2GB
- medium: 4GB
- large-v3: 8GB

**Solutions:**
1. Close other GPU applications
2. Reduce beam_size in benchmark.py (edit before building)
3. Test fewer models

### Slow network download

First run downloads 4GB. On slow connections:
1. Wait for download to complete
2. Models cached for future runs
3. Or: pre-download models manually to `./cache/models/`

## Audio Files

Benchmark includes 10 pre-recorded Polish voice commands (bundled in Docker image):

1. `włącz światło w salonie`
2. `wyłącz wszystkie światła`
3. `ustaw jasność kuchnia na pięćdziesiąt procent`
4. `włącz scenę wieczór`
5. `otwórz rolety w sypialni`
6. `zamknij żaluzje`
7. `która jest godzina`
8. `jaka jest data`
9. `dodaj mleko do listy zakupów`
10. `wyłącz światło`

Format: 16kHz, mono, WAV

## Metrics Explained

**Mean Latency:** Average transcription time per audio file
**Real-time Factor:** How much faster than real-time (higher is better)
**VRAM Used:** GPU memory consumed by model
**WER:** Word Error Rate (0% = perfect transcription)

## Expected Performance (RTX 3060+)

| Model | Latency | Real-time | VRAM |
|-------|---------|-----------|------|
| small | 0.1-0.2s | 15-30x | 1-2GB |
| medium | 0.3-0.5s | 6-10x | 2-3GB |
| large-v3 | 0.8-1.2s | 2-4x | 5-6GB |

*For ~3s audio clips*

## Building from Source

```bash
cd benchmarks/faster-whisper
docker build -t faster-whisper-benchmark .
docker run --gpus all -v ./cache:/cache -v ./results:/results faster-whisper-benchmark
```

## Support

For issues or questions, open an issue at:
https://github.com/Automaat/klaudiusz-smart-home/issues
