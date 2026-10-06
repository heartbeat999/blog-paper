export const siteInfo: SiteInfo = {
  author: "heartbeat999", // Required
  social: {
    email: "hanbingmxcz15@gmail.com", // Required
    github: "https://github.com/heartbeat999", // Required
  },
  timeZone: "Asia/Shanghai", // Required, e.g. 'North America/New York', 'Asia/Shanghai'
  domain: "https://heartbeat999.github.io", // Required,Used to generate rss at build time
  friends: [
    {
      name: "Sansui233",
      link: "https://sansui233.com/",
    },
  ],
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
