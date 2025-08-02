FROM nvidia/cuda:12.1.0-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    bash \
    wget \
    bzip2 \
    curl \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    bash Miniconda3-latest-Linux-x86_64.sh -b -p /root/miniconda3 && \
    rm Miniconda3-latest-Linux-x86_64.sh

ENV PATH="/root/miniconda3/bin:$PATH"

# Accept TOS and create conda env
COPY ./OpenRL /workspace/OpenRL

WORKDIR /workspace/OpenRL
RUN bash -c "\
    conda init bash && \
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main && \
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r && \
    conda create -y --name OpenRL python=3.10 && \
    source /root/miniconda3/bin/activate OpenRL && \
    pip install torch torchvision"

RUN bash -c "\
    source /root/miniconda3/bin/activate OpenRL && \
    pip install -e .[vllm] && \
    pip install flash-attn --no-build-isolation"

RUN bash -c "\
    source /root/miniconda3/bin/activate OpenRL && \
    pip install wandb debugpy ipykernel && \
    python -m ipykernel install --user --name OpenRL --display-name 'Python (OpenRL)'"

WORKDIR /
# docker buildx build --platform linux/amd64 --build-arg GH_TOKEN="$GH_TOKEN" -t openrl-image -f Base.DockerFile .