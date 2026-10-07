#!/usr/bin/env bash
# 新建微博段落并插入到 memos 文件靠上位置，时间自动填好
# 用法：./new-memo.sh "今天写了个新功能"
set -e

cd "$(dirname "$0")"

CONTENT="$1"

if [ -z "$CONTENT" ]; then
  echo -n "微博内容："
  read -r CONTENT
fi

if [ -z "$CONTENT" ]; then
  echo "内容不能为空" >&2
  exit 1
fi

TARGET="content/memos/001.md"
DATE=$(date "+%Y-%m-%d %H:%M:%S")

if [ ! -f "$TARGET" ]; then
  echo "找不到 $TARGET" >&2
  exit 1
fi

# 插到 frontmatter 结束（第二个 ---）之后，保证新微博排在最上面
python3 - "$TARGET" "$DATE" "$CONTENT" <<'PYEOF'
import sys

path, date, content = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path, encoding="utf-8") as f:
    lines = f.read().split("\n")

# 找到 frontmatter 结束位置（第二个 ---）
end = None
for i, line in enumerate(lines):
    if i > 0 and line.strip() == "---":
        end = i
        break

if end is None:
    print("错误：找不到 frontmatter 结束标记", file=sys.stderr)
    sys.exit(1)

block = ["", f"## {date}", "", content, ""]
new = lines[: end + 1] + block + lines[end + 1 :]

with open(path, "w", encoding="utf-8") as f:
    f.write("\n".join(new))
PYEOF

echo "已插入微博到 $TARGET"
echo "时间：$DATE"
echo ""
echo "下一步：刷新 http://localhost:3000/memos 看效果"
echo "上线：./deploy.sh"