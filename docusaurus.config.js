// @ts-check
// Note: type annotations allow type checking and IDEs autocompletion

const lightCodeTheme = require("prism-react-renderer/themes/github");
const darkCodeTheme = require("prism-react-renderer/themes/dracula");

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: "My Site Update",
  tagline: "Dinosaurs are really cool",
  url: "https://louiscklaw.github.io/",
  baseUrl: "/radxa-e24c-share/",
  onBrokenLinks: "throw",
  onBrokenMarkdownLinks: "warn",
  favicon: "img/avatar.jpg",
  organizationName: "louislabs", // Usually your GitHub org/user name.
  projectName: "radxa-e24c-share", // Usually your repo name.
  deploymentBranch: "gh-pages",

  presets: [
    [
      "classic",
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          remarkPlugins: [require("mdx-mermaid")],
          sidebarPath: require.resolve("./sidebars.js"),
          // Please change this to your repo.
          editUrl: "https://github.com/louiscklaw/radxa-e24c-share/tree/master/",
        },
        blog: {
          showReadingTime: true,
          // Please change this to your repo.
          editUrl: "https://github.com/louiscklaw/radxa-e24c-share/tree/master/",
        },
        theme: {
          customCss: require.resolve("./src/css/custom.css"),
        },
      }),
    ],
  ],

  themes: [
    // ... Your other themes.
    [
      require.resolve("@easyops-cn/docusaurus-search-local"),
      {
        // ... Your options.
        // `hashed` is recommended as long-term-cache of index file is possible.
        hashed: true,
        // For Docs using Chinese, The `language` is recommended to set to:
        // ```
        // language: ["en", "zh"],
        // ```
      },
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      navbar: {
        title: "My Site",
        logo: {
          alt: "My Site Logo",
          src: "img/logo.jpg",
        },
        items: [
          {
            type: "doc",
            docId: "intro",
            position: "left",
            label: "My-Share 我的分享",
          },
          // { to: "/blog", label: "Blog", position: "left" },
          {
            // TODO: add link redirector here,
            // i want to add link redirector as the carousell user profile link may change
            // i want to create a repository to host the links
            //
            href: "https://portfolio.louislabs.com/r/carousell_profile",
            label: "carousell-profile",
            position: "right",
          },

          {
            href: "https://portfolio.louislabs.com/r/my_selling",
            label: "my-selling",
            position: "right",
          },
        ],
      },
      footer: {
        style: "dark",
        links: [
          {
            label: "Share",
            to: "/docs/intro",
          },
          // {
          //   label: "Blog",
          //   to: "/blog",
          // },
          {
            label: "GitHub",
            href: "https://github.com/louiscklaw/radxa-e24c-share",
          },
        ],
        copyright: `Copyright © ${new Date().getFullYear()} louiscklaw. Built with Docusaurus.`,
      },
      prism: {
        theme: lightCodeTheme,
        darkTheme: darkCodeTheme,
      },
    }),
};

module.exports = config;
