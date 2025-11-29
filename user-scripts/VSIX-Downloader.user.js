// ==UserScript==
// @name         VSIX Downloader
// @match        https://marketplace.visualstudio.com/items*
// @version      2025.11.30
// @description  Download VSIX files from marketplace.visualstudio.com
// @downloadURL  https://skyfalconua.github.io/user-scripts/VSIX-Downloader.user.js
// @license      MIT
// ==/UserScript==

// Based on
// (at)author       mjmirza, zeroxoneafour
// (at)version      1.0
// (at)downloadURL  https://gist.github.com/zeroxoneafour/ccdf699ca84e2815a5910af1b91e3a6e

(function () {
  "use strict";

  const ELEMENTS = {
    downloadButton: "#vsix-download-button",
    downloadButtonId: "vsix-download-button",
    container: ".resources-async-div ul",
    metadataRows: ".ux-table-metadata tr",
  };

  const $ = (selector, target = document) => target.querySelector(selector);
  const $$ = (selector, target = document) => target.querySelectorAll(selector);

  const createDomElement = (html) => {
    const element = document.createElement("div");
    element.innerHTML = html.trim();
    return element.firstChild;
  };

  const getMetadata = () => {
    const metadataMap = {
      Version: "",
      Publisher: "",
      "Unique Identifier": "",
    };

    const metadataRows = $$(ELEMENTS.metadataRows);
    if (!metadataRows.length) {
      console.error("Failed to find metadata");
      return null;
    }

    metadataRows.forEach((row) => {
      const cells = $$("td", row);
      if (!cells.length) return;

      const key = cells[0].innerText.trim();
      if (!metadataMap.hasOwnProperty(key)) return;

      const value = cells[1].innerText.trim();
      metadataMap[key] = value;
    });

    return metadataMap;
  };

  const downLoanWithName = (url, name) =>
    fetch(url)
      .then((res) => res.blob())
      .then((blob) => {
        const link = document.createElement("a");
        link.href = URL.createObjectURL(blob);
        link.download = name;
        link.click();
      });

  const downloadExtension = () => {
    const metadataMap = getMetadata();
    if (!metadataMap) return;

    const uniqueId = metadataMap["Unique Identifier"];
    const version = metadataMap["Version"];

    if (!uniqueId || !version) {
      console.error("Failed to extract necessary metadata");
      return;
    }

    const [publisher, extension] = uniqueId.split(".");
    const downloadUrl = [
      `https://${publisher}.gallery.vsassets.io/_apis/public/gallery/publisher/${publisher}`,
      `/extension/${extension}/${version}/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage`,
    ].join("");

    downLoanWithName(downloadUrl, `${uniqueId}-${version}.vsix`);
  };

  const addDownloadButton = () => {
    const existing = $(ELEMENTS.downloadButton);
    if (existing) return;

    const container = $(ELEMENTS.container);
    if (!container) return;

    const button = createDomElement(`
    <li>
      <a id="${ELEMENTS.downloadButtonId}">
        Download VSIX
      </a>
    </li>
  `);

    button.onclick = downloadExtension;
    container.appendChild(button);
  };

  const loop = () => {
    addDownloadButton();
    setTimeout(loop, 500);
  };

  setTimeout(loop, 500);
})();
