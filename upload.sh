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
  echo "找不到 .env 文件。请复制 .env.example 为 .env 并填入 Cloudinary 密钥：" >&2
  echo "  cp .env.example .env" >&2
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

# macOS 用 shasum，Linux 用 sha1sum
if command -v shasum > /dev/null 2>&1; then
  sha1() { shasum -a 1 | awk '{print $1}'; }
else
  sha1() { sha1sum | awk '{print $1}'; }
fi

# Cloudinary 上传时同步压缩用 eager 字段（不是 transformation，那个会被静默忽略）。
# c_limit 只缩不放不裁切；q_auto 自动质量；f_auto 让浏览器按能力拿 WebP/AVIF。
# 宽图压到 1600px 以内，博客正文栏足够清晰；原图仍可在 Cloudinary 找到。
MAX_WIDTH="${UPLOAD_MAX_WIDTH:-1600}"
EAGER="c_limit,w_${MAX_WIDTH},q_auto,f_auto"

RESULT=""
for FILE in "$@"; do
  if [ ! -f "$FILE" ]; then
    echo "找不到文件: $FILE" >&2
    exit 1
  fi

  TIMESTAMP=$(date +%s)
  # 签名覆盖所有非文件参数（按字母序用 & 连接），末尾拼 api_secret
  SIGNATURE=$(printf 'eager=%s&timestamp=%s%s' \
    "$EAGER" "$TIMESTAMP" "$CLOUDINARY_API_SECRET" | sha1)

  RESPONSE=$(curl -s --max-time 60 -X POST \
    "https://api.cloudinary.com/v1_1/$CLOUDINARY_CLOUD_NAME/image/upload" \
    -F "file=@$FILE" \
    -F "api_key=$CLOUDINARY_API_KEY" \
    -F "timestamp=$TIMESTAMP" \
    -F "eager=$EAGER" \
    -F "signature=$SIGNATURE")

  # 解析响应：取 eager 衍生图的 URL（压缩版），回退到原图
  read -r URL DERIVED_BYTES <<< "$(printf '%s' "$RESPONSE" | node -e '
    let raw = "";
    process.stdin.on("data", (c) => (raw += c));
    process.stdin.on("end", () => {
      try {
        const d = JSON.parse(raw);
        if (d.error) { console.error(d.error.message); process.exit(1); }
        const eager = d.eager?.[0];
        process.stdout.write([eager?.secure_url ?? d.secure_url ?? "", eager?.bytes ?? ""].join(" "));
      } catch (e) { console.error("响应解析失败"); process.exit(1); }
    });
  ')" || { echo "上传失败: $FILE" >&2; exit 1; }

  if [ -z "$URL" ]; then
    echo "上传失败: $FILE" >&2
    exit 1
  fi

  ORIG_SIZE=$(wc -c < "$FILE" | tr -d ' ')
  WEB_SIZE=$(curl -sL -o /dev/null -w '%{size_download}' \
    -H 'Accept: image/avif,image/webp,image/*' --max-time 30 "$URL")

  NAME=$(basename "$FILE")
  MARKDOWN="![${NAME%.*}]($URL)"
  echo "$MARKDOWN"
  if [ -n "$ORIG_SIZE" ] && [ -n "$WEB_SIZE" ]; then
    ORIG_KB=$((ORIG_SIZE / 1024))
    WEB_KB=$((WEB_SIZE / 1024))
    if [ "$WEB_SIZE" -lt "$ORIG_SIZE" ]; then
      SAVE=$(((ORIG_SIZE - WEB_SIZE) * 100 / ORIG_SIZE))
      echo "    大小：${ORIG_KB} KB → ${WEB_KB} KB（省 ${SAVE}%）"
    else
      echo "    大小：${ORIG_KB} KB → ${WEB_KB} KB"
    fi
  fi
  if [ -z "$RESULT" ]; then
    RESULT="$MARKDOWN"
  else
    RESULT="$RESULT
$MARKDOWN"
  fi
done

# macOS 用 pbcopy，Linux 用 xclip 或 wl-copy
if command -v pbcopy > /dev/null 2>&1; then
  printf '%s' "$RESULT" | pbcopy
elif command -v wl-copy > /dev/null 2>&1; then
  printf '%s' "$RESULT" | wl-copy
elif command -v xclip > /dev/null 2>&1; then
  printf '%s' "$RESULT" | xclip -selection clipboard
else
  echo ""
  echo "未找到剪贴板工具（pbcopy/wl-copy/xclip），请手动复制上面的链接" >&2
  exit 0
fi

echo ""
echo "已复制到剪贴板，粘贴到 markdown 即可"