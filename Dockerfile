FROM nvidia/cuda:11.8.0-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    python3.10 python3-pip git wget ninja-build \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -u 1000 user
USER user

ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH \
    nnUNet_raw="/home/user/TIPs/nnUNet_raw" \
    nnUNet_preprocessed="/home/user/TIPs/nnUNet_preprocessed" \
    nnUNet_results="/home/user/TIPs/nnResults" \
    CXXFLAGS="-D_GLIBCXX_USE_CXX11_ABI=0" \
    CFLAGS="-D_GLIBCXX_USE_CXX11_ABI=0" \
    TORCH_CUDA_ARCH_LIST="8.6" \
    MAX_JOBS=2

WORKDIR $HOME

RUN git clone https://github.com/TaoZhong11/TIPs.git $HOME/TIPs

RUN pip install --no-cache-dir \
    torch==2.0.1 torchvision==0.15.2 \
    --index-url https://download.pytorch.org/whl/cu118

RUN pip install --no-cache-dir 'numpy<2'

RUN pip install --no-cache-dir \
    packaging ninja psutil setuptools wheel pybind11

RUN printf "torch==2.0.1\ntorchvision==0.15.2\nnumpy<2\ntransformers==4.39.3\ntokenizers<0.19\nhuggingface-hub<1.0\n" > $HOME/constraints.txt

RUN pip install --no-cache-dir --no-build-isolation --constraint $HOME/constraints.txt \
    --retries 5 --timeout 120 \
    "causal-conv1d>=1.2.0.post1,<1.3"

RUN pip install --no-cache-dir --no-build-isolation --constraint $HOME/constraints.txt \
    --retries 5 --timeout 120 \
    "mamba-ssm>=1.2.0,<1.3"

RUN python3 -c "import torch, mamba_ssm, causal_conv1d; assert torch.__version__.startswith('2.0.1'), torch.__version__; print('OK:', torch.__version__)"

RUN cd $HOME/TIPs && pip install --no-cache-dir -e .

CMD ["python3", "$HOME/TIPs/TIPs.py", "/data"]