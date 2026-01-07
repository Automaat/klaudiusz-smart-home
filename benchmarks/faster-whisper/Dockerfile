FROM nvidia/cuda:12.2.2-cudnn8-runtime-ubuntu22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Install Python 3.11 and dependencies
RUN apt-get update && apt-get install -y \
    python3.11 \
    python3.11-dev \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Set Python 3.11 as default
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1

# Upgrade pip
RUN python3 -m pip install --no-cache-dir --upgrade pip

# Set working directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy audio samples and benchmark script
COPY audio/ /app/audio/
COPY benchmark.py /app/
COPY test-commands.txt /app/

# Create cache directory
RUN mkdir -p /cache/models

# Create non-root user for running benchmarks and fix permissions
RUN useradd -m -u 1000 benchmark && \
    chown -R benchmark:benchmark /app /cache

# Run benchmark as non-root user
USER benchmark

# Set entrypoint
ENTRYPOINT ["python", "benchmark.py"]
