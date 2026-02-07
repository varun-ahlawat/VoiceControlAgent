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

### **MVP Recommendation: n1-standard-4 with NVIDIA T4 (16GB)**

**Instance Configuration:**
```
Machine Type: n1-standard-4
- vCPUs: 4
- Memory: 15 GB RAM
- GPU: 1x NVIDIA T4 (16GB)
- Storage: 200 GB SSD Persistent Disk
- Region: us-central1 (Iowa)
- Network: Default VPC
```

### Why This Instance Type for MVP?

#### 1. **GPU Selection: NVIDIA T4**
- **Memory**: 16GB sufficient for 7B parameter models with INT8 quantization
- **Cost**: ~$0.67/hour — $300 GCP free credits give ~18 days of 24/7 usage
- **Turing Architecture**: Good inference performance for real-time voice
- **Widely Available**: Easy to get quota approved quickly

#### 2. **CPU Selection: n1-standard-4**
- **4 vCPUs**: Sufficient for audio preprocessing and API handling
- **15 GB RAM**: Adequate for model loading and request queuing
- **Cost-effective**: Half the cost of n1-standard-8

#### 3. **Default VPC Networking**
- No custom VPC permissions required (works with new GCP accounts)
- Simplified setup — uses GCP's built-in default network
- Firewall rules added for SSH, HTTP, and WebSocket access

#### 4. **Cost-Performance Balance**
- **T4**: ~$0.67/hour (on-demand)
- **Free credits**: $300 = ~18 days of 24/7 usage
- **Stop when idle**: Run only when needed to extend credit lifetime

### Upgrade Options

#### **Production: n1-standard-8 with NVIDIA A100 (40GB)**
```
Machine Type: n1-standard-8
- vCPUs: 8
- Memory: 30 GB RAM
- GPU: 1x NVIDIA A100 (40GB)
- Cost: ~$2.95/hour
```
**Pros**: 40GB VRAM for larger models, higher throughput
**Cons**: Significantly more expensive

#### **High-Performance: a2-highgpu-1g with NVIDIA A100 80GB**
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

### MVP Pricing (T4):
```
Instance: n1-standard-4 + T4
- Compute: ~$0.67/hour × 730 hours = $489/month
- Storage: 200GB SSD × $0.17/GB = $34/month
- Network: ~$20/month (estimated)
- Total: ~$543/month
- With $300 free credits: ~18 days of 24/7 usage
```

### Production Pricing (A100, if upgrading later):
```
Instance: n1-standard-8 + A100 40GB
- Compute: ~$2.95/hour × 730 hours = $2,153/month
- Storage: 500GB SSD × $0.17/GB = $85/month
- Network: ~$50/month (estimated)
- Total: ~$2,288/month
```

### Cost Optimization Tips:
1. Use Preemptible/Spot instances for development: Save 60-70%
2. Use Committed Use Discounts for production: Save 35-55%
3. Implement auto-scaling to shut down during low usage
4. Use Cloud Storage for model weights (cheaper than persistent disks for infrequent access)

## 6. Scaling Recommendations

### MVP/Development (Current):
- 1x T4 instance (16GB) with INT8 quantization
- Default VPC networking
- Cost: ~$489/month on-demand

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

**For MVP, we recommend:**
- **Instance**: n1-standard-4 with 1x NVIDIA T4
- **Region**: us-central1 (Iowa)
- **Storage**: 200GB SSD Persistent Disk
- **Network**: Default VPC
- **Estimated Cost**: ~$0.67/hour (~$489/month), with $300 free credits lasting ~18 days

This provides:
- ✅ Sufficient VRAM for 7B models with quantization
- ✅ Low latency for real-time interaction
- ✅ Cost efficiency for MVP
- ✅ Easy upgrade path to A100 later
- ✅ Simple setup with default VPC
