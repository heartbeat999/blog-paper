#!/usr/bin/env bash
# 上传图片到 Cloudinary，并把 markdown 图片链接输出到剪贴板
#
# 用法：
#   ./upload.sh 图片路径            上传单张
#   ./upload.sh 图片1 图片2 ...     上传多张
#
# 上传后剪贴板里会是这样一行，直接粘到 markdown 里：
#   ![图片名](https://res.cloudinary.com/...)
set -e

cd "$(dirname "$0")"

if [ ! -f .env ]; then
  echo "找不到 .env 文件，请先创建并填入 Cloudinary 密钥" >&2
  exit 1
fi

set -a
source .env
set +a

MISSING=""
[ -z "$CLOUDINARY_CLOUD_NAME" ] && MISSING="$MISSING CLOUDINARY_CLOUD_NAME"
[ -z "$CLOUDINARY_API_KEY" ] && MISSING="$MISSING CLOUDINARY_API_KEY"
[ -z "$CLOUDINARY_API_SECRET" ] && MISSING="$MISSING CLOUDINARY_API_SECRET"
if [ -n "$MISSING" ]; then
  echo ".env 缺少以下变量:$MISSING" >&2
  exit 1
fi

if [ $# -eq 0 ]; then
  echo "用法: ./upload.sh 图片路径 [更多图片...]" >&2
  exit 1
fi

# cloudinary 要求带 f_auto,q_auto 自动选格式和压缩质量
TRANSFORM="f_auto,q_auto"

RESULT=""
for FILE in "$@"; do
  if [ ! -f "$FILE" ]; then
    echo "找不到文件: $FILE" >&2
    exit 1
  fi

  TIMESTAMP=$(date +%s)
  # 签名覆盖所有非文件参数（按字母序用 & 连接），末尾拼 api_secret
  SIGNATURE=$(printf 'timestamp=%s&transformation=%s%s' \
    "$TIMESTAMP" "$TRANSFORM" "$CLOUDINARY_API_SECRET" \
    | shasum -a 1 | awk '{print $1}')

  RESPONSE=$(curl -s --max-time 60 -X POST \
    "https://api.cloudinary.com/v1_1/$CLOUDINARY_CLOUD_NAME/image/upload" \
    -F "file=@$FILE" \
    -F "api_key=$CLOUDINARY_API_KEY" \
    -F "timestamp=$TIMESTAMP" \
    -F "transformation=$TRANSFORM" \
    -F "signature=$SIGNATURE")

  URL=$(printf '%s' "$RESPONSE" | sed -n 's/.*"secure_url":"\([^"]*\)".*/\1/p')
  if [ -z "$URL" ]; then
    echo "上传失败: $FILE" >&2
    printf '%s\n' "$RESPONSE" >&2
    exit 1
  fi

  NAME=$(basename "$FILE")
  MARKDOWN="![${NAME%.*}]($URL)"
  echo "$MARKDOWN"
  if [ -z "$RESULT" ]; then
    RESULT="$MARKDOWN"
  else
    RESULT="$RESULT
$MARKDOWN"
  fi
done

printf '%s' "$RESULT" | pbcopy
echo ""
echo "已复制到剪贴板，粘贴到 markdown 即可"
