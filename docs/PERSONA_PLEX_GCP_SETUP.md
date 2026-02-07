# Persona Plex GCP Deployment Guide

## 1. About Persona Plex

Persona Plex is NVIDIA's advanced multimodal conversational AI model designed for full-duplex voice interactions. It's part of NVIDIA's ADLR (Applied Deep Learning Research) lab innovations.

### Model Characteristics:
- **Type**: Large Language Model with voice interaction capabilities
- **Primary Use**: Full-duplex agentic voice layer for AI agents with complex tool use
- **Architecture**: Transformer-based multimodal model
- **Modalities**: Text and Audio (speech)
- **Key Features**:
  - Real-time voice interaction
  - Complex reasoning and tool use
  - State management system
  - Full-duplex communication (simultaneous speaking and listening)

### Estimated Model Specifications:
Based on NVIDIA's recent model releases and voice AI requirements:
- **Model Size**: Estimated 7B-13B parameters (for inference efficiency)
- **Precision**: FP16/BF16 for inference (2 bytes per parameter)
- **Memory Requirements**: 
  - Model weights: ~14-26 GB (for 7B-13B params in FP16)
  - Runtime overhead: ~4-8 GB
  - Audio processing buffers: ~2-4 GB
  - **Total VRAM needed**: 24-40 GB minimum
- **Compute Requirements**: High throughput for real-time voice processing

## 2. Recommended GCP Instance Type

### **Primary Recommendation: n1-standard-8 with NVIDIA A100 (40GB or 80GB)**

**Instance Configuration:**
```
Machine Type: n1-standard-8
- vCPUs: 8
- Memory: 30 GB RAM
- GPU: 1x NVIDIA A100 (40GB or 80GB)
- Storage: 500 GB SSD Persistent Disk
- Region: us-central1 (Iowa) or us-west1 (Oregon)
```

### Why This Instance Type?

#### 1. **GPU Selection: NVIDIA A100**
- **Tensor Cores**: A100 has 3rd generation Tensor Cores optimized for transformer models
- **Memory**: 40GB or 80GB HBM2e provides ample space for:
  - Model weights (14-26 GB)
  - Activation memory during inference
  - Batch processing for efficiency
  - Audio processing buffers
- **Performance**: 312 TFLOPS FP16, 624 TFLOPS with sparsity
- **Memory Bandwidth**: 1,555 GB/s (40GB) or 2,039 GB/s (80GB)
- **Multi-Instance GPU (MIG)**: Can partition GPU if needed for development/testing
- **NVLink**: High-speed inter-GPU communication if scaling to multi-GPU

#### 2. **CPU Selection: n1-standard-8**
- **8 vCPUs**: Sufficient for:
  - Preprocessing audio streams
  - Managing API requests
  - Running auxiliary services
  - Parallel data loading
- **30 GB RAM**: Adequate for:
  - Model loading and caching
  - Request queuing
  - Operating system and dependencies
  - Development tools

#### 3. **Cost-Performance Balance**
- **A100 40GB**: ~$2.95/hour (on-demand)
- **A100 80GB**: ~$3.67/hour (on-demand)
- **Committed Use Discounts**: Save up to 55% with 1-year or 3-year commitments
- **Preemptible/Spot**: Save up to 70% for non-critical workloads

#### 4. **Availability and Support**
- Available in multiple GCP regions
- Strong ecosystem support for ML workloads
- Compatible with GKE (Google Kubernetes Engine) for orchestration
- Integrates with Vertex AI for MLOps

### Alternative Options

#### **Budget Option: n1-standard-4 with NVIDIA T4**
```
Machine Type: n1-standard-4
- vCPUs: 4
- Memory: 15 GB RAM
- GPU: 1x NVIDIA T4 (16GB)
- Cost: ~$0.95/hour
```
**Pros**: Much cheaper, good for development/testing
**Cons**: Limited VRAM (16GB) may require model quantization (INT8), slower inference

#### **High-Performance Option: a2-highgpu-1g with NVIDIA A100 80GB**
```
Machine Type: a2-highgpu-1g
- vCPUs: 12
- Memory: 85 GB RAM
- GPU: 1x NVIDIA A100 (80GB)
- Cost: ~$3.67/hour
```
**Pros**: More VRAM for larger batches, better CPU performance
**Cons**: Higher cost, may be overkill for single model deployment

#### **Multi-GPU Production: a2-highgpu-4g**
```
Machine Type: a2-highgpu-4g
- vCPUs: 48
- Memory: 340 GB RAM
- GPU: 4x NVIDIA A100 (80GB each)
- Cost: ~$14.68/hour
```
**Pros**: High availability, load balancing, redundancy
**Cons**: Expensive, complex setup

## 3. Detailed Technical Justification

### Memory Requirements Breakdown:

```
Component                          Memory Usage
================================================
Model Weights (7B @ FP16)         14 GB
Model Weights (13B @ FP16)        26 GB
KV Cache (batch size 4)           4-6 GB
Activation Memory                 2-4 GB
Audio Processing Buffers          2 GB
Framework Overhead (PyTorch)      2-3 GB
Operating Margin (20%)            5-8 GB
================================================
Total (7B model)                  29-37 GB
Total (13B model)                 41-53 GB
```

**Conclusion**: A100 40GB is sufficient for 7B models, A100 80GB recommended for 13B+ models

### Compute Requirements:

For real-time voice interaction:
- **Latency Target**: < 200ms for natural conversation
- **Token Generation**: ~50-100 tokens/second required
- **A100 Performance**: Can achieve 150-300 tokens/second for 7B models

### Network and I/O:

- **Audio Streaming**: Requires consistent bandwidth (128-256 kbps per stream)
- **WebSocket/gRPC**: Low-latency connections for real-time interaction
- **GCP Network**: Premium tier recommended for consistent low latency

## 4. Regional Recommendations

**Primary Regions:**
1. **us-central1 (Iowa)**: Best price-performance, high GPU availability
2. **us-west1 (Oregon)**: Good for West Coast users, renewable energy
3. **us-east4 (Virginia)**: Good for East Coast users

**Considerations:**
- Choose region closest to your users for lowest latency
- Check GPU availability (A100s can be limited in some regions)
- Consider data residency requirements

## 5. Estimated Costs (Monthly)

### On-Demand Pricing:
```
Instance: n1-standard-8 + A100 40GB
- Compute: ~$2.95/hour × 730 hours = $2,153/month
- Storage: 500GB SSD × $0.17/GB = $85/month
- Network: ~$50/month (estimated)
- Total: ~$2,288/month
```

### With Committed Use (1-year):
```
- Compute: ~$1,327/month (38% savings)
- Storage: $85/month
- Network: ~$50/month
- Total: ~$1,462/month
```

### Cost Optimization Tips:
1. Use Preemptible/Spot instances for development: Save 60-70%
2. Use Committed Use Discounts for production: Save 35-55%
3. Implement auto-scaling to shut down during low usage
4. Use Cloud Storage for model weights (cheaper than persistent disks for infrequent access)

## 6. Scaling Recommendations

### Development/Testing:
- 1x T4 instance (16GB) with INT8 quantization
- Cost: ~$700/month on-demand

### Production (Low-Medium Traffic):
- 1x A100 40GB instance
- Cost: ~$1,500/month with committed use

### Production (High Traffic):
- 2-4x A100 instances behind load balancer
- Kubernetes cluster for orchestration
- Auto-scaling based on request queue depth

### Enterprise (24/7 High Availability):
- Multi-region deployment
- 4-8x A100 instances (2-4 per region)
- Redis for state management
- Cloud CDN for static assets

## Summary

**For most use cases, we recommend:**
- **Instance**: n1-standard-8 with 1x NVIDIA A100 40GB
- **Region**: us-central1 (Iowa)
- **Storage**: 500GB SSD Persistent Disk
- **Estimated Cost**: $1,500-2,300/month depending on commitment

This provides the best balance of:
- ✅ Sufficient VRAM for the model
- ✅ Low latency for real-time interaction
- ✅ Cost efficiency
- ✅ Easy scaling path
- ✅ GCP ecosystem integration
