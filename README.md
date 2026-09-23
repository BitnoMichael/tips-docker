---
title: TIPs Segmentation
emoji: 🦷
colorFrom: blue
colorTo: green
sdk: docker
app_port: 7860
pinned: false
---

# TIPs: Tooth Instances and Pulp Segmentation from CBCT

An accurate and automated AI tool called **TIPs** for **T**ooth **I**nstances and **P**ulp **s**egmentation from CBCT.

TIPs works out-of-the-box without requiring any retraining. By inputting a CBCT image, users can obtain both **semantic** and **instance** segmentation for teeth and pulps. The final instance labeling follows the **FDI World Dental Federation** notation.

![Example](https://github.com/TaoZhong11/TIPs/blob/main/Example.png)

---

## About this Space

This Space provides a **Docker image** built specifically for running TIPs on Hugging Face infrastructure. The image includes:

- Ubuntu 22.04 with CUDA 11.8 (runtime)
- Python 3.10
- PyTorch 2.0.1 (cu118)
- `causal-conv1d` and `mamba-ssm`
- The TIPs source code, installed as an editable package
- Pre-configured `nnUNet_raw`, `nnUNet_preprocessed`, and `nnUNet_results` environment variables

This Space is **not a web application**. It is designed to be used as a base image for **Hugging Face Jobs** — batch inference tasks that run on GPU.

---

## Usage

### Prerequisites

- A Hugging Face account with an access token
- `huggingface_hub` installed locally: `pip install -U huggingface_hub`
- Logged in via CLI: `hf auth login`

### Running a Job

Once this Space is built, its image is available at:
registry.hf.space/MihaelBit/TIPs:latest

Run a job on GPU (e.g., A10G) with the following command:

```bash
hf jobs run \
  --flavor a10g-small \
  --timeout 2h \
  -v /absolute/path/to/your/cbct_scans:/data \
  -v hf://buckets/<YOUR_USERNAME>/tips-results:/output \
  registry.hf.space/<YOUR_USERNAME>/<SPACE_NAME>:latest \
  -- bash -c "cd /home/user/TIPs && python TIPs.py /data && cp -r /home/user/TIPs/nnResults/* /output/"
