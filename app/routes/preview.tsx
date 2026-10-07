import { Link, useLoaderData } from "react-router";
import type { Route } from "./+types/preview";

export async function loader({}: Route.LoaderArgs) {
  const { posts_db } = await import("lib/data/server/posts");

  return {
    posts: posts_db.velite.map((p) => ({
      title: p.title,
      slug: p.slug,
      date: p.date,
      draft: p.draft,
      categories: p.categories,
    })),
  };
}

export function meta({}: Route.MetaArgs) {
  return [{ title: "预览清单" }];
}

type PreviewPost = {
  title: string;
  slug: string;
  date: string;
  draft: boolean;
  categories?: string | null;
};

export default function Preview() {
  const { posts } = useLoaderData() as { posts: PreviewPost[] };

  return (
    <div className="mx-auto w-170 px-5 py-10 max-lg:w-auto max-lg:max-w-170">
      <h1 className="mb-2 text-2xl">预览清单</h1>
      <p className="text-text-gray mb-8 text-sm">
        共 {posts.length} 篇 · 点标题打开 · 草稿仅本地可见
      </p>

      <ul className="border-ui-line-gray divide-y border">
        {posts.map((p) => (
          <li key={p.slug} className="py-3">
            <Link
              to={`/posts/${p.slug}`}
              className="hover:underline flex flex-wrap items-baseline gap-3"
            >
              <span className="font-medium">{p.title}</span>
              {p.draft && (
                <span className="border-ui-line-gray rounded border px-1.5 py-0.5 text-xs">
                  草稿
                </span>
              )}
              <span className="text-text-gray text-sm">
                {p.date.split("T")[0]}
                {p.categories ? ` · ${p.categories}` : ""}
              </span>
            </Link>
            <div className="text-text-gray mt-1 text-xs">
              网址：/posts/{p.slug}
            </div>
          </li>
        ))}
      </ul>

      <div className="text-text-gray mt-10 text-sm">
        <p>微博页：/memos</p>
        <p>首页：/</p>
      </div>
    </div>
  );
}