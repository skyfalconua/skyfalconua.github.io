#!/usr/bin/env -S deno run -A

//
// find . -type f | entr -np ./make-index.jsx
//

import { parse } from "@std/yaml";
import { renderToString } from "preact-render-to-string";

const GITHUB_BASE = "https://github.com/skyfalconua";
const GITHUB_PAGES = "https://skyfalconua.github.io";
const TRIM_SLASH = /^\/+|\/+$/g;

const Icon = ({ kind = "item" }) => (
  <svg class={`icon icon-${kind}`}>
    <use href={`#${kind}IconSymbol`}></use>
  </svg>
);

const IconsSprite = () => (
  <svg style={{ display: "none" }}>
    <defs>
      {/* -- folder icon -- -- -- */}
      <symbol
        id="folderIconSymbol"
        viewBox="0 0 202 168"
        style="fill-rule:evenodd;clip-rule:evenodd;stroke-linejoin:round;stroke-miterlimit:2;"
      >
        <path
          d="M155.235,130.062l-46.148,0c-4.62,0 -8.392,-3.776 -8.392,-8.391c0,-4.616 3.772,-8.391 8.392,-8.391l46.148,0c4.62,0 8.392,3.775 8.392,8.391c0,4.615 -3.772,8.391 -8.392,8.391Zm20.977,-109.084l-71.325,0c-1.425,0 -3.06,-2.56 -5.407,-6.419c-3.443,-5.79 -8.73,-14.559 -19.763,-14.559l-54.54,0c-13.177,0 -25.177,11.999 -25.177,25.173l0,117.476c0,12.922 12.255,25.174 25.177,25.174l151.035,0c12.922,0 25.178,-12.251 25.178,-25.174l0,-96.497c0,-12.922 -12.255,-25.173 -25.178,-25.173Z"
          style="fill:#f7c800;fill-rule:nonzero;"
        />
        <path
          d="M163.627,121.671c0,4.615 -3.772,8.391 -8.392,8.391l-46.148,0c-4.62,0 -8.392,-3.776 -8.392,-8.391c0,-4.616 3.772,-8.391 8.392,-8.391l46.148,0c4.62,0 8.392,3.775 8.392,8.391Z"
          style="fill:#f7d331;fill-rule:nonzero;"
        />
      </symbol>
      {/* -- item icon -- -- -- */}
      <symbol
        id="itemIconSymbol"
        viewBox="0 0 168 202"
        style="fill-rule:evenodd;clip-rule:evenodd;stroke-linejoin:round;stroke-miterlimit:2;"
      >
        <path
          d="M125.865,67.133c-13.883,0 -25.17,-11.288 -25.17,-25.178l0,-41.955l-75.525,0c-13.883,0 -25.17,11.288 -25.17,25.177l0,151.035c0,13.89 11.288,25.178 25.17,25.178l117.48,0c13.883,0 25.17,-11.288 25.17,-25.178l0,-109.08l-41.955,0Z"
          style="fill:#c5cae9;fill-rule:nonzero;"
        />
        <path
          d="M167.82,60.795l0,6.337l-41.955,0c-13.883,0 -25.17,-11.288 -25.17,-25.178l0,-41.955l6.33,0c6.72,0 13.095,2.648 17.835,7.387l35.58,35.58c4.74,4.74 7.38,11.115 7.38,17.828Z"
          style="fill:#6e6e78;fill-rule:nonzero;"
        />
      </symbol>
      {/* -- web icon -- -- -- */}
      <symbol
        id="webIconSymbol"
        viewBox="0 0 202 202"
        style="fill-rule:evenodd;clip-rule:evenodd;stroke-linejoin:round;stroke-miterlimit:2;"
      >
        <path
          d="M201.39,100.695c0,55.613 -45.082,100.695 -100.695,100.695c-55.612,0 -100.695,-45.082 -100.695,-100.695c0,-55.612 45.083,-100.695 100.695,-100.695c55.613,0 100.695,45.083 100.695,100.695Z"
          style="fill:#1f3cb5;fill-rule:nonzero;"
        />
        <path
          d="M0.383,109.088c3.608,44.01 35.745,80.093 77.783,89.7c-21.023,-29.745 -32.475,-59.782 -34.32,-89.7l-43.463,0Z"
          style="fill:#27a5e8;fill-rule:nonzero;"
        />
        <path
          d="M78.165,2.603c-42.038,9.607 -74.175,45.69 -77.783,89.7l43.463,0c1.845,-29.91 13.297,-59.955 34.32,-89.7Z"
          style="fill:#27a5e8;fill-rule:nonzero;"
        />
        <path
          d="M60.668,109.088c2.1,30.375 15.487,61.17 40.027,91.965c24.547,-30.795 37.928,-61.59 40.028,-91.965l-80.055,0Z"
          style="fill:#27a5e8;fill-rule:nonzero;"
        />
        <path
          d="M140.723,92.303c-2.1,-30.375 -15.48,-61.17 -40.028,-91.965c-24.54,30.795 -37.927,61.59 -40.027,91.965l80.055,0Z"
          style="fill:#27a5e8;fill-rule:nonzero;"
        />
        <path
          d="M123.225,198.788c42.038,-9.607 74.175,-45.69 77.782,-89.7l-43.462,0c-1.845,29.918 -13.297,59.955 -34.32,89.7Z"
          style="fill:#27a5e8;fill-rule:nonzero;"
        />
        <path
          d="M201.008,92.303c-3.607,-44.01 -35.745,-80.092 -77.782,-89.7c21.023,29.745 32.475,59.79 34.32,89.7l43.462,0Z"
          style="fill:#27a5e8;fill-rule:nonzero;"
        />
      </symbol>
      {/* -- download icon -- -- -- */}
      <symbol
        id="downloadIconSymbol"
        viewBox="0 0 126 202"
        style="fill-rule:evenodd;clip-rule:evenodd;stroke-linejoin:round;stroke-miterlimit:2;"
      >
        <path
          d="M57,165.367c1.635,1.635 3.788,2.46 5.932,2.46c2.145,0 4.297,-0.825 5.932,-2.46l54.541,-54.54c3.277,-3.277 3.277,-8.588 0,-11.873c-3.27,-3.277 -8.588,-3.277 -11.865,0l-40.297,40.305c0.023,-0.27 0.082,-0.532 0.082,-0.803l0,-130.065c0,-4.635 -3.758,-8.393 -8.392,-8.393c-4.635,0 -8.392,3.758 -8.392,8.393l0,130.065c0,0.27 0.053,0.533 0.082,0.803l-40.297,-40.305c-3.277,-3.277 -8.595,-3.277 -11.865,0c-3.277,3.285 -3.277,8.595 0,11.873l54.54,54.54Z"
          style="fill:#27a5e8;fill-rule:nonzero;"
        />
        <path
          d="M117.472,184.605l-109.08,0c-4.635,0 -8.392,3.758 -8.392,8.393c0,4.635 3.757,8.393 8.392,8.393l109.08,0c4.635,0 8.392,-3.758 8.392,-8.393c0,-4.635 -3.757,-8.393 -8.392,-8.393Z"
          style="fill:#6e6e78;fill-rule:nonzero;"
        />
      </symbol>
      {/* -- indicator3 icon -- -- -- */}
      <symbol
        id="indicator3IconSymbol"
        viewBox="0 0 126 168"
        style="fill-rule:evenodd;clip-rule:evenodd;stroke-linejoin:round;stroke-miterlimit:2;"
      >
        <path
          d="M56.998,165.367c1.635,1.635 3.788,2.46 5.932,2.46c2.145,0 4.297,-0.825 5.932,-2.46l54.541,-54.54c3.277,-3.277 3.277,-8.588 0,-11.873c-3.27,-3.277 -8.588,-3.277 -11.865,0l-40.297,40.305c0.023,-0.27 0.082,-0.532 0.082,-0.803l0,-130.065c0,-4.635 -3.758,-8.393 -8.392,-8.393c-4.635,0 -8.392,3.758 -8.392,8.393l0,130.065c0,0.27 0.053,0.533 0.082,0.803l-40.297,-40.305c-3.277,-3.277 -8.595,-3.277 -11.865,0c-3.277,3.285 -3.277,8.595 0,11.873l54.54,54.54Z"
          style="fill:#6e6e78;fill-rule:nonzero;"
        />
      </symbol>
      {/* -- application icon -- -- -- */}
      <symbol
        id="applicationIconSymbol"
        viewBox="0 0 202 168"
        style="fill-rule:evenodd;clip-rule:evenodd;stroke-linejoin:round;stroke-miterlimit:2;"
      >
        <path
          d="M38.22,142.648l124.95,0c14.138,0 25.635,-11.496 25.635,-25.635l0,-91.379c0,-14.139 -11.497,-25.634 -25.635,-25.634l-124.95,0c-14.138,0 -25.628,11.495 -25.628,25.634l0,91.379c0,14.139 11.49,25.635 25.628,25.635Z"
          style="fill:#27a5e8;fill-rule:nonzero;"
        />
        <path
          d="M192.998,151.039l-184.605,0c-4.635,0 -8.393,3.757 -8.393,8.391c0,4.634 3.758,8.391 8.393,8.391l184.605,0c4.635,0 8.392,-3.757 8.392,-8.391c0,-4.634 -3.758,-8.391 -8.392,-8.391Z"
          style="fill:#6e6e78;fill-rule:nonzero;"
        />
      </symbol>
      {/* -- settings icon -- -- -- */}
      <symbol
        id="settingsIconSymbol"
        viewBox="0 0 202 202"
        style="fill-rule:evenodd;clip-rule:evenodd;stroke-linejoin:round;stroke-miterlimit:2;"
      >
        <path
          d="M100.695,142.65c-23.115,0 -41.955,-18.832 -41.955,-41.955c0,-23.115 18.84,-41.955 41.955,-41.955c23.115,0 41.955,18.84 41.955,41.955c0,23.123 -18.84,41.955 -41.955,41.955Zm98.977,-60.33c-0.758,-4.027 -4.282,-6.795 -8.227,-6.795l-15.105,0c-1.215,-3.607 -2.64,-7.095 -4.365,-10.492l10.703,-10.74c0.045,0 0.045,0 0.045,-0.037c2.768,-2.812 3.27,-7.26 0.923,-10.658c-7.013,-10.155 -15.698,-18.839 -25.845,-25.845c-3.397,-2.355 -7.845,-1.845 -10.657,0.922c-0.045,0 -0.045,0 -0.045,0.037l-10.74,10.703c-3.398,-1.718 -6.878,-3.151 -10.485,-4.366l0,-15.105c0,-4.11 -2.94,-7.508 -6.84,-8.22c-5.873,-1.132 -12.082,-1.725 -18.337,-1.725c-6.248,0 -12.458,0.593 -18.33,1.725c-3.907,0.713 -6.84,4.11 -6.84,8.22l0,15.105c-3.608,1.215 -7.095,2.647 -10.492,4.366l-10.74,-10.703c0,-0.037 0,-0.037 -0.045,-0.037c-2.805,-2.768 -7.253,-3.277 -10.65,-0.922c-10.155,7.006 -18.84,15.69 -25.845,25.845c-2.355,3.398 -1.845,7.845 0.922,10.658c0,0.037 0,0.037 0.038,0.037l10.703,10.74c-1.725,3.397 -3.15,6.885 -4.365,10.492l-15.105,0c-3.945,0 -7.47,2.768 -8.22,6.795c-1.133,5.873 -1.725,12.082 -1.725,18.375c0,6.293 0.593,12.502 1.725,18.375c0.75,3.99 4.275,6.803 8.22,6.803l15.105,0c1.215,3.607 2.64,7.088 4.365,10.485l-10.703,10.74c-1.59,1.598 -2.475,3.735 -2.475,5.963c0,1.635 0.503,3.27 1.515,4.74c7.005,10.147 15.69,18.832 25.845,25.845c1.463,1.005 3.143,1.508 4.778,1.508c2.182,0 4.282,-0.877 5.917,-2.52l0,0.045l10.74,-10.695c3.398,1.718 6.885,3.143 10.492,4.357l0,15.105c0,3.945 2.767,7.47 6.795,8.22c5.873,1.14 12.083,1.725 18.375,1.725c6.292,0 12.502,-0.585 18.375,-1.725c4.027,-0.75 6.803,-4.275 6.803,-8.22l0,-15.105c3.607,-1.215 7.087,-2.64 10.485,-4.357l10.74,10.695l0,-0.045c1.635,1.643 3.735,2.52 5.918,2.52c1.635,0 3.315,-0.502 4.785,-1.508c10.148,-7.012 18.833,-15.697 25.845,-25.845c1.005,-1.47 1.508,-3.105 1.508,-4.74c0,-2.228 -0.878,-4.365 -2.475,-5.963l-10.703,-10.74c1.725,-3.397 3.15,-6.877 4.365,-10.485l15.105,0c3.945,0 7.47,-2.812 8.227,-6.803c1.133,-5.873 1.718,-12.082 1.718,-18.375c0,-6.293 -0.585,-12.502 -1.718,-18.375Z"
          style="fill:#c5cae9;fill-rule:nonzero;"
        />
        <path
          d="M100.695,125.873c-13.883,0 -25.17,-11.287 -25.17,-25.178c0,-13.883 11.288,-25.17 25.17,-25.17c13.89,0 25.178,11.287 25.178,25.17c0,13.89 -11.288,25.178 -25.178,25.178Zm0,-67.133c-23.115,0 -41.955,18.84 -41.955,41.955c0,23.123 18.84,41.955 41.955,41.955c23.115,0 41.955,-18.832 41.955,-41.955c0,-23.115 -18.84,-41.955 -41.955,-41.955Z"
          style="fill:#6e6e78;fill-rule:nonzero;"
        />
        <path
          d="M125.873,100.695c0,13.89 -11.288,25.178 -25.178,25.178c-13.883,0 -25.17,-11.287 -25.17,-25.178c0,-13.883 11.288,-25.17 25.17,-25.17c13.89,0 25.178,11.287 25.178,25.17Z"
          style="fill:#27a5e8;fill-rule:nonzero;"
        />
      </symbol>
      {/* -- library icon -- -- -- */}
      <symbol
        id="libraryIconSymbol"

        viewBox="0 0 168 177"
        style="fill-rule:evenodd;clip-rule:evenodd;stroke-linejoin:round;stroke-miterlimit:2;"
      >
        <path
          d="M117.472,58.737l-67.125,0c-4.612,0 -8.392,-3.775 -8.392,-8.391c0,-4.615 3.78,-8.391 8.392,-8.391l67.125,0c4.62,0 8.392,3.776 8.392,8.391c0,4.616 -3.773,8.391 -8.392,8.391Zm0,37.76l-67.125,0c-4.612,0 -8.392,-3.776 -8.392,-8.391c0,-4.615 3.78,-8.391 8.392,-8.391l67.125,0c4.62,0 8.392,3.776 8.392,8.391c0,4.615 -3.773,8.391 -8.392,8.391Zm-33.562,37.76l-33.562,0c-4.612,0 -8.392,-3.776 -8.392,-8.391c0,-4.616 3.78,-8.391 8.392,-8.391l33.562,0c4.62,0 8.392,3.775 8.392,8.391c0,4.615 -3.773,8.391 -8.392,8.391Zm58.74,-134.257l-117.472,0c-13.89,0 -25.177,11.286 -25.177,25.173l0,125.867c0,13.887 11.287,25.173 25.177,25.173l117.472,0c13.89,0 25.17,-11.286 25.17,-25.173l0,-125.867c0,-13.887 -11.28,-25.173 -25.17,-25.173Z"
          style="fill:#c5cae9;fill-rule:nonzero;"
        />
        <path
          d="M92.302,125.866c0,4.615 -3.773,8.391 -8.392,8.391l-33.562,0c-4.612,0 -8.392,-3.776 -8.392,-8.391c0,-4.616 3.78,-8.391 8.392,-8.391l33.562,0c4.62,0 8.392,3.775 8.392,8.391Z"
          style="fill:#fff;fill-rule:nonzero;"
        />
        <path
          d="M125.865,88.106c0,4.615 -3.773,8.391 -8.392,8.391l-67.125,0c-4.612,0 -8.392,-3.776 -8.392,-8.391c0,-4.615 3.78,-8.391 8.392,-8.391l67.125,0c4.62,0 8.392,3.776 8.392,8.391Z"
          style="fill:#fff;fill-rule:nonzero;"
        />
        <path
          d="M125.865,50.346c0,4.616 -3.773,8.391 -8.392,8.391l-67.125,0c-4.612,0 -8.392,-3.775 -8.392,-8.391c0,-4.615 3.78,-8.391 8.392,-8.391l67.125,0c4.62,0 8.392,3.776 8.392,8.391Z"
          style="fill:#fff;fill-rule:nonzero;"
        />
      </symbol>
    </defs>
  </svg>
);

const getFullLink = (category, link) =>
  [
    category.path == "PAGES" ? GITHUB_PAGES : GITHUB_BASE,
    category.path && category.path != "PAGES"
      ? category.path.replace(TRIM_SLASH, "")
      : "",
    link.path.replace(TRIM_SLASH, ""),
  ]
    .filter(Boolean)
    .join("/");

const Details = ({ column, category }) => (
  <details open={category.opened}>
    <summary>
      <span className="details-categoty-title">
        <Icon kind="folder" /> {category.name}
      </span>
      <Icon kind="indicator3" />
    </summary>

    <div className="tree-content">
      {category.links.map((link) => (
        <div className="tree-item" key={link.path}>
          <Icon kind={link.icon || category.icon || column.icon} />
          <div className="tree-item-content">
            <a href={getFullLink(category, link)}>{link.name}</a>
            {link.description && (
              <div className="tree-description">{link.description}</div>
            )}
          </div>
        </div>
      ))}
    </div>
  </details>
);

const Dashboard = ({ left_column, right_column, css, avatar }) => (
  <html>
    <head>
      <meta charSet="UTF-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <title>Andrew Sokolov - tools, libs and snippets</title>
      <meta
        name="description"
        content="Personal development dashboard showcasing public projects and tools"
      />
      <link
        rel="stylesheet"
        href="https://cdn.jsdelivr.net/npm/water.css@2/out/light.css"
      />
      <style dangerouslySetInnerHTML={{ __html: css }} />
      <IconsSprite />
    </head>
    <body>
      <div className="container">
        <header>
          <div className="header-content">
            <img src={`data:image/jpeg;base64,${avatar}`} alt="avatar" />
            <p className="subtitle">
              Andrew Sokolov - tools, libs and snippets
            </p>
          </div>
        </header>
        <div className="content-wrapper">
          {/* -- left column -- -- -- */}
          <section>
            <section className="tree-section">
              {left_column.categories.map((category) => (
                <Details column={left_column} category={category} />
              ))}
            </section>
          </section>
          {/* -- right column -- -- -- */}
          <section>
            <section className="tree-section">
              {right_column.categories.map((category) => (
                <Details column={right_column} category={category} />
              ))}
            </section>
          </section>
        </div>
      </div>
    </body>
  </html>
);

// --- Main Execution ---

function main() {
  console.log("📝 Generating dashboard using make-index.jsx...");

  const yamlContent = Deno.readTextFileSync("content.yaml");
  const content = parse(yamlContent);
  const css = Deno.readTextFileSync("styles.css");
  const avatarBinary = Deno.readFileSync("avatar.jpg");
  const avatar = btoa(String.fromCharCode(...avatarBinary));

  const props = { ...content, css: css, avatar: avatar };
  const html = "<!DOCTYPE html>\n" + renderToString(Dashboard(props));
  Deno.writeTextFileSync("../index.html", html);

  console.log("✅ Generated index.html");

  // Format Output
  const command = new Deno.Command("deno", {
    args: ["fmt", new URL("../index.html", import.meta.url).pathname],
  });
  command.outputSync();
  console.log("🎨 Formatted index.html");
}

main();
