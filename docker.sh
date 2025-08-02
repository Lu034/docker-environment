#!/bin/bash

# 定義映像檔與容器名稱
IMAGE_NAME="aoc2026-env"
CONTAINER_NAME="aoc2026-container"
DOCKERFILE="Dockerfile"

# 函數：檢查映像檔是否存在
# 傳回值：0 (存在) 或 1 (不存在)
function image_exists() {
    # 使用 docker images -q 查詢映像檔 ID，如果結果非空，則表示存在
    docker images -q "${IMAGE_NAME}" | grep -q .
}

# 函數：檢查容器是否存在
function container_exists() {
    # 檢查所有狀態的容器
    docker ps -a --filter "name=${CONTAINER_NAME}" | grep -q "${CONTAINER_NAME}"
}

# 函數：檢查容器是否正在運行
function container_is_running() {
    # 只檢查正在運行的容器
    docker ps --filter "name=${CONTAINER_NAME}" | grep -q "${CONTAINER_NAME}"
}

# 函數：顯示成功訊息
function success_message() {
    echo -e "\n\033[32m✔ 成功: $1\033[0m\n"
}

# 函數：顯示警告訊息
function warning_message() {
    echo -e "\n\033[33m提示: $1\033[0m\n"
}

# 函數：顯示錯誤訊息
function error_message() {
    echo -e "\n\033[31m✘ 錯誤: $1\033[0m\n"
    exit 1
}

# 函數：建立 Docker 映像檔
function build_docker_image() {
    echo "--- 開始建立 Docker 映像檔 ---"

    # 確認 Dockerfile 是否存在
    if [ ! -f "${DOCKERFILE}" ]; then
        echo "錯誤: 找不到 ${DOCKERFILE} 檔案。請確認它在同一目錄下。"
        exit 1
    fi

    # 檢查映像檔是否已存在
    if image_exists; then
        warning_message "映像檔 '${IMAGE_NAME}' 已經存在。如果你想重建，請先執行 'docker rmi ${IMAGE_NAME}'。"
    else
        echo "映像檔 '${IMAGE_NAME}' 不存在，正在使用 ${DOCKERFILE} 進行建立..."
        # 執行 Docker build 指令
        docker build --no-cache -t "${IMAGE_NAME}" -f "${DOCKERFILE}" .

        # 檢查 build 指令是否成功
        if [ $? -eq 0 ]; then
            success_message "映像檔 '${IMAGE_NAME}' 建立成功。"
        else
            error_message "建立映像檔 '${IMAGE_NAME}' 失敗。"
        fi
    fi
    echo "---------------------------"
}

# 函數：運行 Docker 容器
function run_docker_container() {
    echo "--- 執行 run 任務 ---"

    # 確認映像檔是否存在，若不存在則先建立
    if ! image_exists; then
        warning_message "映像檔 '${IMAGE_NAME}' 不存在，正在自動建立..."
        build_docker_image
    fi
    
    # 根據容器狀態做不同處理
    if container_is_running; then
        warning_message "容器 '${CONTAINER_NAME}' 正在運行中。正在進入..."
        docker exec -it "${CONTAINER_NAME}" bash -c "exec bash"
    elif container_exists; then
        warning_message "容器 '${CONTAINER_NAME}' 已存在但處於停止狀態。正在啟動並進入..."
        docker start "${CONTAINER_NAME}"
        docker exec -it "${CONTAINER_NAME}" bash -c "exec bash"
    else
        echo "容器 '${CONTAINER_NAME}' 不存在，正在建立並啟動一個新的..."
        # 這裡可以使用 --rm 參數，以便在容器停止時自動刪除
        docker run -it --name "${CONTAINER_NAME}" "${IMAGE_NAME}" 
    fi
    
    if container_is_running || container_exists; then
      success_message "已退出容器 '${CONTAINER_NAME}'。"
    else
      success_message "已進入並退出新的容器 '${CONTAINER_NAME}'。"
    fi

    echo "-----------------------"
}


# 主程式
# 根據第一個參數來呼叫對應的函數
if [ "$1" == "run" ]; then
    run_docker_container
elif [ "$1" == "build" ]; then
    build_docker_image
else
    echo "使用方式: ./docker.sh [run|build]"
    exit 1
fi
