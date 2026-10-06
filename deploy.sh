#!/bin/bash
# 一键部署：构建 + 推送源码 + 推送静态站点
# 用法：./deploy.sh "更新说明"
set -e

SRC_REPO="https://github.com/heartbeat999/blog-paper.git"
SITE_REPO="https://github.com/heartbeat999/heartbeat999.github.io.git"
BRANCH="main"
MSG="${1:-Update at $(date '+%Y-%m-%d %H:%M:%S')}"

cd "$(dirname "$0")"

echo "==> 1/4 构建站点"
# pnpm 可能装在系统路径，也可能装在用户目录（非交互 shell 读不到 ~/.zshrc）
if ! command -v pnpm > /dev/null 2>&1; then
  export PATH="$HOME/Library/pnpm/bin:$PATH"
fi
pnpm pre
pnpm build

echo "==> 2/4 推送源码 (blog-paper)"
git add -A
# 防止误提交密钥类文件（.env.example 是模板，允许提交）
if git diff --cached --name-only \
  | grep -v '\.env\.example$' \
  | grep -qE '(^|/)\.env($|\.)|\.pem$|\.key$|secret'; then
  echo "暂存区包含疑似密钥文件，已中止部署：" >&2
  git diff --cached --name-only \
    | grep -v '\.env\.example$' \
    | grep -E '(^|/)\.env($|\.)|\.pem$|\.key$|secret' >&2
  exit 1
fi
if git diff --cached --quiet; then
  echo "    源码无变化"
else
  git commit -m "$MSG"
  git push origin "$BRANCH"
fi

echo "==> 3/4 推送静态站点 (heartbeat999.github.io)"
WORKDIR=$(mktemp -d)
git clone --depth=1 -b "$BRANCH" "$SITE_REPO" "$WORKDIR/site"
# 清空旧文件但保留 .git
find "$WORKDIR/site" -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf {} +
cp -R build/client/. "$WORKDIR/site/"
cd "$WORKDIR/site"
git add -A
if git diff --cached --quiet; then
  echo "    站点无变化"
else
  git commit -m "$MSG"
  git push origin "$BRANCH"
fi
cd - > /dev/null
rm -rf "$WORKDIR"

echo "==> 4/4 完成"
echo "    网站地址: https://heartbeat999.github.io"