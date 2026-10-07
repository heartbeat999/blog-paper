#!/usr/bin/env bash
# 新建文章文件，自动填好标题和当前时间
# 用法：./new-post.sh 我的教程
#       ./new-post.sh            （不带标题，会提示输入）
set -e

cd "$(dirname "$0")"

TITLE="$1"

if [ -z "$TITLE" ]; then
  echo -n "文章标题："
  read -r TITLE
fi

if [ -z "$TITLE" ]; then
  echo "标题不能为空" >&2
  exit 1
fi

# 文件名用标题，中文和空格都能处理
FILENAME="$TITLE.md"
TARGET="content/posts/$FILENAME"

if [ -f "$TARGET" ]; then
  echo "文件已存在：$TARGET" >&2
  echo "换个标题试试" >&2
  exit 1
fi

DATE=$(date "+%Y-%m-%d %H:%M:%S")

cat > "$TARGET" <<EOF
---
title: $TITLE
date: $DATE
categories: 其他
draft: false
tags:
  - 随笔
---

## 开始写正文

EOF

echo "已创建：$TARGET"
echo "标题：$TITLE"
echo "日期：$DATE"
echo ""
echo "下一步："
echo "  code \"$TARGET\"      # 用 VS Code 打开"
echo "  pnpm dev              # 另开终端启动预览"
echo "  浏览器打开 http://localhost:3000/preview 点标题看效果"