import { siteInfo } from "site.config";
import { OneColLayout } from "~/components/common/layout";
import type { Route } from "./+types/about";
import "./about.css";

export function meta({}: Route.MetaArgs) {
  return [
    { title: `About ${siteInfo.author}` },
    { name: "description", content: "A personal blog about work and life" },
  ];
}

export default function About() {
  return (
    <>
      {/* Hero Section */}
      <h1 className="about-hero">
        <span>{`Hi, I'm ${siteInfo.author}`}</span>
      </h1>

      <OneColLayout>
        {/* Page Description */}
        <div className="text-text-gray-2 text-right text-sm italic">
          / 记录一些思考和吐槽 /
        </div>

        {/* Content */}
        <div className="markdown-wrapper animate-bottom-fade-in">
          <p>
            GitHub：
            <a href={siteInfo.social.github}>
              {siteInfo.social.github.replace("https://github.com/", "")}
            </a>
            <br />
            E-mail：
            <a href={`mailto:${siteInfo.social.email}`}>
              {siteInfo.social.email}
            </a>
          </p>

          <h4>About</h4>
          <p>这里写你自己的介绍。改 app/routes/about/about.tsx 这个文件即可。</p>

          <h4>Tech</h4>
          <p>常用技术栈。</p>

          <h4>Projects</h4>
          <p>在做的项目。</p>

          <h4>Game</h4>
          <p>在玩的游戏。</p>
        </div>
      </OneColLayout>
    </>
  );
}
