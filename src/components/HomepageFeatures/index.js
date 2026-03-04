import React from "react";
import clsx from "clsx";
import styles from "./styles.module.css";

const FeatureList = [
  {
    title: "我的筆記 / My-Note",
    Svg: require("@site/static/img/undraw_docusaurus_mountain.svg").default,
    description: <>這裡放一些我對 radxa e24c 的個人心得</>,
    href: "docs/intro",
    blank: false,
  },
  {
    title: "我的 carousell",
    Svg: require("@site/static/img/undraw_docusaurus_tree.svg").default,
    description: <>這裡放一些我 carousell 拍賣</>,
    href: "https://www.carousell.com.hk/u/louis_coding/",
    blank: true,
  },
  // {
  //   title: "Powered by React",
  //   Svg: require("@site/static/img/undraw_docusaurus_react.svg").default,
  //   description: <>Extend or customize your website layout by reusing React. Docusaurus can be extended while reusing the same header and footer.</>,
  // },
];

function Feature({ Svg, title, description, href, blank }) {
  if (href) {
    return (
      <div className={clsx("col col--6 FeatureHover")}>
        <a href={href} target={blank ? "_blank" : "_self"}>
          <div className="text--center">
            <Svg className={styles.featureSvg} role="img" />
          </div>
          <div className="text--center padding-horiz--md">
            <h3>{title}</h3>
            <p>{description}</p>
          </div>
        </a>
      </div>
    );
  } else {
    return (
      <div className={clsx("col col--6")}>
        <div className="text--center">
          <Svg className={styles.featureSvg} role="img" />
        </div>
        <div className="text--center padding-horiz--md">
          <h3>{title}</h3>
          <p>{description}</p>
        </div>
      </div>
    );
  }
}

export default function HomepageFeatures() {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
