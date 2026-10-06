export const siteInfo: SiteInfo = {
  author: "heartbeat999", // Required
  social: {
    // Required（RSS feed 与联系入口会用到）。不想公开真实邮箱就保留占位值
    email: "yourname@example.com",
    github: "https://github.com/heartbeat999", // Required
  },
  timeZone: "Asia/Shanghai", // Required, e.g. 'North America/New York', 'Asia/Shanghai'
  domain: "https://heartbeat999.github.io", // Required,Used to generate rss at build time
  // Optional，友情链接。填了才会显示，留空/删除则不显示
  friends: [],
} as const;

type SiteInfo = {
  author: string;
  social: {
    email: string;
    github: string;
  };
  friends?: {
    name: string;
    link: string;
  }[];
  timeZone?: string; // e.g. 'Asia/Shanghai'

  // Sites
  domain: string; // Used to generate rss at build time
  walineApi?: string; // Waline 评论系统后端地址
  GAId?: string; // Google Analytics id
};
