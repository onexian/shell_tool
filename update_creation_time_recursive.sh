#!/bin/bash
# ==================================================
# Desc    : 修改项目文件创建时间及最后修改时间
# Author  : onexian
# Date    : 2025-04-14
# Version : v1.0
# ==================================================

# 设置当前时间（格式为 MM/DD/YYYY HH:MM:SS）
CURRENT_DATE=$(date +"%m/%d/%Y %H:%M:%S")
echo "设置创建时间和修改时间为：$CURRENT_DATE"

# 检查 SetFile 是否可用
if ! command -v SetFile &> /dev/null; then
    echo "错误：SetFile 命令未找到，请先安装 Xcode Command Line Tools："
    echo "运行：xcode-select --install"
    exit 1
fi

# 获取目标目录（默认当前目录）
TARGET_DIR="${1:-.}"

# 先设置目标目录本身
SetFile -d "$CURRENT_DATE" "$TARGET_DIR"
SetFile -m "$CURRENT_DATE" "$TARGET_DIR"

# 递归遍历所有文件和目录（深度优先）
find "$TARGET_DIR" -depth -print0 | while IFS= read -r -d '' item; do
    if [ -e "$item" ]; then
        SetFile -d "$CURRENT_DATE" "$item"
        SetFile -m "$CURRENT_DATE" "$item"
    fi
done

echo "✅ 所有文件和目录的创建时间 & 修改时间已更新为：$CURRENT_DATE"
