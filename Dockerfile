# 使用 Ubuntu 24.04 作為 base image
FROM ubuntu:24.04

# 設定時區避免互動式詢問 (可選)
ENV DEBIAN_FRONTEND=noninteractive

# 更新套件資訊
RUN apt-get update && apt-get upgrade -y

# 預設工作目錄
WORKDIR /root

# 指定 container 啟動時進入 bash
CMD ["/bin/bash"]