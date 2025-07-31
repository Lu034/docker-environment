# base image
FROM ubuntu:24.04 AS base

# 避免安裝過程中要求使用者互動輸入
ENV DEBIAN_FRONTEND=noninteractive

# 設定時區與基本環境（例如 tzdata、sudo）
RUN apt-get update && \
    apt-get install -y tzdata sudo && \
    ln -fs /usr/share/zoneinfo/Asia/Taipei /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

# 建立固定 UID/GID 的非 root 使用者
# UID/GID可依照需要修改
ARG USERNAME=appuser
ARG UID=1001
ARG GID=1001

RUN groupadd -g ${GID} ${USERNAME} && \
    useradd -m -u ${UID} -g ${GID} -s /bin/bash ${USERNAME} && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Stage `common_pkg_provider`: Core CLI Tools & Python and pip & Miniconda
FROM base AS common_pkg_provider

# 切換回 root 才能安裝套件
USER root  

# 安裝 Core CLI Tools & Python and pip
RUN apt-get update && apt-get install -y --no-install-recommends \
    vim \
    git \
    curl \
    wget \
    ca-certificates \
    build-essential \
    python3.12 \
    python3.12-venv \
    python3.12-dev \
    python3-pip && \
    ln -sf /usr/bin/python3.12 /usr/bin/python3 && \
    ln -sf /usr/bin/pip3 /usr/bin/pip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 設定 Conda 安裝位置
ENV CONDA_DIR=/opt/conda
ENV PATH=$CONDA_DIR/bin:$PATH

# 安裝 Miniconda，並連結 conda.sh 以支援 conda activate
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        MINICONDA=Miniconda3-py312_25.5.1-1-Linux-x86_64.sh; \
    elif [ "$ARCH" = "aarch64" ]; then \
        MINICONDA=Miniconda3-py312_25.5.1-1-Linux-aarch64.sh; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    curl -fsSL https://repo.anaconda.com/miniconda/$MINICONDA -o /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p $CONDA_DIR && \
    rm /tmp/miniconda.sh && \
    ln -s $CONDA_DIR/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". $CONDA_DIR/etc/profile.d/conda.sh" >> /etc/bash.bashrc && \
    conda clean -afy && \
    chown -R ${USERNAME}:${USERNAME} $CONDA_DIR && \
    echo ". $CONDA_DIR/etc/profile.d/conda.sh" >> /home/${USERNAME}/.bashrc

# 設定工作目錄與切換使用者
WORKDIR /home/${USERNAME}
USER ${USERNAME}

# 預設執行 bash
CMD ["/bin/bash"]