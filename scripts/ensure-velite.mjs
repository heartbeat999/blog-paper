// Velite 生成 posts.json/memos.json 之前，config 的导入链会先引用它们，
// 全新 clone 后直接跑 velite 会报 "Could not resolve"。这里先放占位文件。
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
