#!/bin/bash

# 定義映像檔與容器名稱，為腳本的預設值，可以被命令列參數覆蓋
IMAGE_NAME="aoc2026-env:v2"
CONTAINER_NAME="aoc2026-container"
DOCKERFILE="Dockerfile"
MOUNT_PATHS=()
USERNAME="appuser"
HOST_NAME="aoc2026"

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
    
    local run_options="-it"
    local exec_options="-it"

    # 如果有指定 username
    if [[ -n "$USERNAME" ]]; then
        run_options+=" --user ${USERNAME}"
        exec_options+=" --user ${USERNAME}"
    fi

    # 如果有指定 hostname
    if [[ -n "$HOST_NAME" ]]; then
        run_options+=" --hostname ${HOST_NAME}"
    fi

    # 處理 mount paths
    for path in "${MOUNT_PATHS[@]}"; do
        echo "Mount: ${MOUNT_PATHS}"
        run_options+=" -v ${path}"
    done

    # 根據容器狀態做不同處理
    if container_is_running; then
        warning_message "容器 '${CONTAINER_NAME}' 正在運行中。正在進入..."
        docker exec ${exec_options} "${CONTAINER_NAME}" bash -c "exec bash"
    elif container_exists; then
        warning_message "容器 '${CONTAINER_NAME}' 已存在但處於停止狀態。正在啟動並進入..."
        docker start "${CONTAINER_NAME}"
        docker exec ${exec_options} "${CONTAINER_NAME}" bash -c "exec bash"
    else
        echo "容器 '${CONTAINER_NAME}' 不存在，正在建立並啟動一個新的..."
        # 這裡可以使用 --rm 參數，以便在容器停止時自動刪除
        docker run ${run_options} --name "${CONTAINER_NAME}" "${IMAGE_NAME}" 
    fi
    
    success_message "已退出容器 '${CONTAINER_NAME}'。"
    echo "-----------------------"
}

# 顯示腳本用法
function show_usage() {
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  run                  運行 Docker 容器並進入其 shell"
    echo "  build                建立 Docker image"
    echo ""
    echo "Options:"
    echo "  --image-name <name>  指定 image 名稱 (預設: ${IMAGE_NAME})"
    echo "  --cont-name <name>   指定 container 名稱 (預設: ${CONTAINER_NAME})"
    echo "  --username <name>    指定進入容器時的用戶名稱 (預設: ${USERNAME})，注意!目前只有appuser 和 root 兩個可用用戶名稱"
    echo "  --hostname <name>    指定容器的 hostname (預設: ${HOST_NAME})"
    echo "  --mount <path>       綁定主機目錄到容器內 (可多次使用)"
    echo "                       格式: /host/path:/container/path"
    echo "                       範例: --mount "$(pwd)/src:/app/src""
    echo ""
}

# Customized Command Line Arguments
function parse_args() {
    # 儲存第一個參數為命令
    COMMAND="$1"
    shift

    while (( "$#" )); do
        case "$1" in
            --image-name)
                IMAGE_NAME="$2"
                shift 2
                ;;
            --cont-name)
                CONTAINER_NAME="$2"
                shift 2
                ;;
            --username)
                USERNAME="$2"
                shift 2
                ;;
            --hostname)
                HOST_NAME="$2"
                shift 2
                ;;
            --mount)
                MOUNT_PATHS+=("$2")
                shift 2
                ;;
            *)
                error_message "未知參數: $1"
                ;;
        esac
    done
}

# 主程式
# 解析參數並執行對應指令
parse_args "$@"

case "$COMMAND" in
    run)
        run_docker_container
        ;;
    build)
        build_docker_image
        ;;
    *)
        show_usage
        exit 1
        ;;
esac

