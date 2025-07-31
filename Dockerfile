# base image
FROM ubuntu:24.04

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

# 設定工作目錄與切換使用者
WORKDIR /home/${USERNAME}
USER ${USERNAME}

# 預設執行 bash
CMD ["/bin/bash"]