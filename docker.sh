#!/bin/bash

# 定義映像檔名稱，可以根據需求修改
IMAGE_NAME="aoc2026-env"
DOCKERFILE="Dockerfile"

# 函數：檢查映像檔是否存在
# 傳回值：0 (存在) 或 1 (不存在)
function image_exists() {
    # 使用 docker images -q 查詢映像檔 ID，如果結果非空，則表示存在
    docker images -q "${IMAGE_NAME}" | grep -q .
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
        echo "---"
        echo "提示: 映像檔 '${IMAGE_NAME}' 已經存在。"
        echo "如果你想重建它，請先執行以下指令:"
        echo "  docker rmi ${IMAGE_NAME}"
        echo "---"
    else
        echo "映像檔 '${IMAGE_NAME}' 不存在，正在使用 ${DOCKERFILE} 進行建立..."
        # 執行 Docker build 指令
        docker build --no-cache -t "${IMAGE_NAME}" -f "${DOCKERFILE}" .

        # 檢查 build 指令是否成功
        if [ $? -eq 0 ]; then
            echo ""
            echo "✔ 成功: 映像檔 '${IMAGE_NAME}' 已經建立完成！"
        else
            echo ""
            echo "✘ 錯誤: 建立映像檔 '${IMAGE_NAME}' 失敗。"
            exit 1
        fi
    fi
    echo "---------------------------"
}

# 呼叫主函數
build_docker_image