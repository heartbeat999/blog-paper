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
export PATH="$HOME/Library/pnpm/bin:$PATH"
pnpm pre
pnpm build

echo "==> 2/4 推送源码 (blog-paper)"
git add -A
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
