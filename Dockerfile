FROM nvidia/cuda:11.8.0-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3-pip \
    git \
    wget \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -u 1000 user
USER user

ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH \
    nnUNet_raw="/home/user/TIPs/nnUNet_raw" \
    nnUNet_preprocessed="/home/user/TIPs/nnUNet_preprocessed" \
    nnUNet_results="/home/user/TIPs/nnResults"

WORKDIR $HOME

RUN git clone https://github.com/TaoZhong11/TIPs.git $HOME/TIPs

RUN pip install --no-cache-dir torch==2.0.1 torchvision==0.15.2 --index-url https://download.pytorch.org/whl/cu118

RUN pip install --no-cache-dir causal-conv1d>=1.2.0 mamba-ssm

RUN cd $HOME/TIPs && pip install --no-cache-dir -e .

CMD ["python", "$HOME/TIPs/TIPs.py", "/data"]