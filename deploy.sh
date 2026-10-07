#!/bin/bash
# 一键部署：构建 + 推送源码 + 推送静态站点
# 用法：./deploy.sh "更新说明"
#
# github.com 直连经常超时，所有网络操作都会自动重试。
set -e

SITE_REPO="https://github.com/heartbeat999/heartbeat999.github.io.git"
BRANCH="main"
MSG="${1:-Update at $(date '+%Y-%m-%d %H:%M:%S')}"

cd "$(dirname "$0")"

# git 默认 HTTP/2 在不稳定网络下容易断，强制 1.1 并放宽超时
git config http.version HTTP/1.1
git config http.lowSpeedLimit 1
git config http.lowSpeedTime 600

# 最多重试 5 次，退避等待
retry() {
  local desc="$1"
  shift
  local n=1
  while [ $n -le 5 ]; do
    if "$@"; then
      return 0
    fi
    echo "    [$desc] 第 $n 次失败，10 秒后重试..." >&2
    sleep 10
    n=$((n + 1))
  done
  echo "    [$desc] 重试 5 次仍失败，放弃" >&2
  return 1
}

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
  retry "推送源码" git push origin "$BRANCH"
fi

echo "==> 3/4 推送静态站点 (heartbeat999.github.io)"
WORKDIR=$(mktemp -d)
retry "克隆站点仓库" git clone --depth=1 -b "$BRANCH" "$SITE_REPO" "$WORKDIR/site"
# 清空旧文件但保留 .git
find "$WORKDIR/site" -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf {} +
cp -R build/client/. "$WORKDIR/site/"
cd "$WORKDIR/site"
git add -A
if git diff --cached --quiet; then
  echo "    站点无变化"
else
  git commit -m "$MSG"
  retry "推送站点" git push origin "$BRANCH"
fi
cd - > /dev/null
rm -rf "$WORKDIR"

echo "==> 4/4 完成"
echo "    网站地址: https://heartbeat999.github.io"