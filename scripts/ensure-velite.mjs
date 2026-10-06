// 全新 clone 后 .velite/ 下只有被 git 跟踪的 index.js/index.d.ts，
// 缺少 posts.json、memos.json（这两个是 velite 的输出，被 gitignore）。
// 而 velite 加载配置时会走 velite.config.ts -> lib/data/server/rss.ts -> posts.ts
// -> import { posts } from "../../../.velite"，index.js 又 re-export 那两个 json，
// 于是 esbuild 在 velite 写出真实数据之前就解析失败：
//   ERROR Could not resolve "./posts.json"
// 所以先放空数组占位，等 velite 正常覆盖。
//
// 一旦上游 velite 自身修好了这个加载顺序（或改为延迟导入），本文件即可删除，
// 同时把 package.json 的 pre 脚本恢复为 "velite"。
import { existsSync, mkdirSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const veliteDir = join(root, ".velite");

mkdirSync(veliteDir, { recursive: true });

for (const file of ["posts.json", "memos.json"]) {
  const target = join(veliteDir, file);
  if (!existsSync(target)) {
    writeFileSync(target, "[]");
  }
}