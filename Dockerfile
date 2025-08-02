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
# build-essential 包含 g++ gcc make ...
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

# Stage verilator_provider : Build Verilator from Source
FROM common_pkg_provider AS verilator_provider
USER root 
WORKDIR /tmp

# 安裝編譯 Verilator 所需的依賴套件
RUN apt-get update && apt-get install -y \
    git \
    make \
    autoconf \
    g++ \
    bison \
    flex \
    perl \
    libfl2 \
    libfl-dev \
    libgoogle-perftools-dev \
    libjson-perl \
    libyaml-perl \
    help2man \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# 從 GitHub 取得指定版本的 Verilator 原始碼並編譯
ARG VERILATOR_VERSION=v5.032
RUN git clone https://github.com/verilator/verilator.git \
    && cd verilator \
    && git checkout ${VERILATOR_VERSION} \
    && autoconf \
    && ./configure \
    && make -j$(nproc) \
    && make install \
    && cd .. \
    && rm -rf verilator

# 進行驗證，如果 Verilator 沒有正確安裝，建置就會失敗，能及早發現問題。
RUN verilator --version

# Stage systemc_provider : Build SystemC from Source
FROM common_pkg_provider AS systemc_provider

WORKDIR /tmp/systemc

# 安裝 SystemC 編譯所需的額外依賴
# 已經安裝了 g++, make, git 等基本工具
# 安裝 cmake 和 zlib1g-dev
RUN apt-get update && apt-get install -y \
    cmake \
    zlib1g-dev \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# 下載 SystemC 2.3.4 原始碼並解壓縮
ARG SYSTEMC_VERSION=2.3.4
RUN wget https://github.com/accellera-official/systemc/archive/refs/tags/${SYSTEMC_VERSION}.tar.gz \
    && tar -xzf ${SYSTEMC_VERSION}.tar.gz \
    && rm ${SYSTEMC_VERSION}.tar.gz

# 進行 CMake configure 與安裝
RUN cd systemc-${SYSTEMC_VERSION} \
    && mkdir build \
    && cd build \
    && cmake .. \
       -DCMAKE_INSTALL_PREFIX=/usr/local/systemc-${SYSTEMC_VERSION} \
       -DCMAKE_CXX_STANDARD=17 \
    && make -j$(nproc) \
    && make install \
    && rm -rf /tmp/systemc-${SYSTEMC_VERSION}


# Stage `final`: Final Image for Application Use
FROM common_pkg_provider AS final

# 從 `systemc_provider` 複製編譯好的 SystemC 安裝目錄
ARG SYSTEMC_VERSION=2.3.4
COPY --from=systemc_provider /usr/local/systemc-${SYSTEMC_VERSION} /usr/local/systemc-${SYSTEMC_VERSION}

# 從 `verilator_provider` 複製編譯好的 Verilator
# 因為 Verilator 是安裝到 /usr/local/bin 和 /usr/local/share，需要分別複製
COPY --from=verilator_provider /usr/local/bin /usr/local/bin
COPY --from=verilator_provider /usr/local/share /usr/local/share

# 設定環境變數
ARG USERNAME=appuser
ENV SYSTEMC_HOME=/usr/local/systemc-${SYSTEMC_VERSION}
ENV LD_LIBRARY_PATH=/usr/local/systemc-${SYSTEMC_VERSION}/lib:$LD_LIBRARY_PATH

# 設定工作目錄與切換使用者
WORKDIR /home/${USERNAME}
USER ${USERNAME}

# 預設執行 bash
CMD ["/bin/bash"]