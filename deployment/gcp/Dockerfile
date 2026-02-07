# Dockerfile for Persona Plex deployment
# Optimized for NVIDIA GPU with CUDA 12.1

FROM nvidia/cuda:12.1.0-cudnn8-runtime-ubuntu22.04

# Metadata
LABEL maintainer="VoiceControlAgent"
LABEL description="Persona Plex Voice AI - Full Duplex Agentic Voice Layer"
LABEL version="1.0"

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=${CUDA_HOME}/bin:${PATH}
ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3-pip \
    python3-dev \
    build-essential \
    git \
    curl \
    wget \
    ffmpeg \
    libsndfile1 \
    libsndfile1-dev \
    portaudio19-dev \
    libasound2-dev \
    libportaudio2 \
    libportaudiocpp0 \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip
RUN pip3 install --no-cache-dir --upgrade pip setuptools wheel

# Install PyTorch with CUDA support
RUN pip3 install --no-cache-dir \
    torch==2.1.0 \
    torchvision==0.16.0 \
    torchaudio==2.1.0 \
    --index-url https://download.pytorch.org/whl/cu121

# Install core ML libraries
RUN pip3 install --no-cache-dir \
    transformers==4.36.0 \
    accelerate==0.25.0 \
    bitsandbytes==0.41.3 \
    sentencepiece==0.1.99 \
    protobuf==4.25.1

# Install audio processing libraries
RUN pip3 install --no-cache-dir \
    librosa==0.10.1 \
    soundfile==0.12.1 \
    webrtcvad==2.0.10 \
    pydub==0.25.1 \
    numpy==1.24.3 \
    scipy==1.11.4

# Install server and API frameworks
RUN pip3 install --no-cache-dir \
    fastapi==0.108.0 \
    uvicorn[standard]==0.25.0 \
    websockets==12.0 \
    pydantic==2.5.3 \
    python-multipart==0.0.6 \
    aiohttp==3.9.1

# Install utilities
RUN pip3 install --no-cache-dir \
    python-dotenv==1.0.0 \
    pyyaml==6.0.1 \
    tqdm==4.66.1 \
    requests==2.31.0

# Install monitoring
RUN pip3 install --no-cache-dir \
    prometheus-client==0.19.0 \
    python-json-logger==2.0.7

# Create application directory
WORKDIR /app

# Create directories for models and data
RUN mkdir -p /app/models /app/data /app/logs

# Copy application files (to be added later)
# COPY ./app /app

# Expose ports
# 8000: Main API
# 8080: WebSocket for voice streaming
# 9090: Metrics
EXPOSE 8000 8080 9090

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Default command (to be customized)
CMD ["python3", "-c", "print('Persona Plex container ready. Please mount your application code.')"]
