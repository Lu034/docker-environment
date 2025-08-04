#!/bin/bash

# 設置錯誤處理：任何指令失敗，腳本將終止
set -e

help() {
cat <<EOF
Usage:    
    eman check-verilator            : print the version of the first found Verilator (if there are multiple version of Verilator installed)
    eman verilator-example <PATH>   : compile and run the Verilator example(s) with example path, ex: /home/appuser/projects/aoc_lab0/c_cpp/arrays/multidim_array
    eman c-compiler-version         : print the version of default C compiler and the version of GNU Make
    eman c-compiler-example <PATH>  : compile and run the C/C++ example(s) with example path ex: /home/appuser/projects/aoc_lab0/verilog/counter
EOF
}

# 函數：檢查 Verilator 版本
eman_check_verilator() {
    echo "--- 正在檢查 Verilator 版本 ---"
    verilator --version
    echo "Verilator 檢查完成。"
}

# 函數：運行 Verilator 範例
eman_verilator_example() {
    # 檢查是否傳入路徑參數
    if [ -z "$1" ]; then
        echo "錯誤：請指定 Verilator 範例專案路徑。"
        help
        exit 1
    fi

    echo "--- 正在運行 Verilator 範例 ---"
    cd "$1"
    # 執行 make，Makefile 將會負責編譯、運行和驗證
    make clean all
    echo "Verilator 範例運行完成。"
}
    
# 函數：檢查 C 編譯器和 GNU Make 版本
eman_c_compiler_version() {
    echo "--- 正在檢查 C 編譯器和 GNU Make 版本 ---"
    g++ --version | head -n 1
    make --version | head -n 1
    echo "檢查完成。"
}

# 函數：運行 C/C++ 範例
eman_c_compiler_example() {
    if [ -z "$1" ]; then
        echo "錯誤：請指定 C/C++ 範例專案路徑。"
        help
        exit 1
    fi

    echo "--- 正在編譯並運行 C/C++ 範例 ---"
    cd "$1"
    # 執行 make，Makefile 將會負責編譯、運行和驗證
    make clean all
    echo "C/C++ 範例運行完成。"
}

# 主邏輯：根據傳入的子指令執行對應的函數
case "$1" in
    help|--help|-h) 
        help
        ;;
    check-verilator)
        eman_check_verilator
        ;;
    verilator-example)
        shift
        eman_verilator_example "$1"
        ;;
    c-compiler-version)
        eman_c_compiler_version
        ;;
    c-compiler-example)
        shift
        eman_c_compiler_example "$1"
        ;;
    *)
        echo "錯誤：未知的指令 '$1'"
        help
        exit 1
        ;;
        
esac