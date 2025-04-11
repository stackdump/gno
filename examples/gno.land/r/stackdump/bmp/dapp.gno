package bmp
import (
    "net/url"
)

func dataURL() string {
    return "data:text/html;utf8," + url.PathEscape(htmlContent)
}

func Dapp() string {
    return "## PIXELFIED DAPP\n\n[INSECURE DAPP](" + dataURL() + ")\n\n" + dappInfo
}

const dappInfo = `
### How to Use the JavaScript Widget for Pixelized Images

The JavaScript widget provided in the htmlContent section of the [dapp.gno](./bmp$source&file=dapp.gno) file allows you to generate pixelized images and export them as Gno-compatible data.

Open the Widget: Right click on "INSECURE DAPP" link above.

Use "Copy Link Address" and paste it into a new tab to run the JS widget.

---

#### **Steps to Use the Widget**

1. **Load an Image**:
   Use the "Choose File" button to upload an image from your local system. The widget will process this image to create a pixelized version.

2. **Set Grid Dimensions**:
   Adjust the "Grid Width" and "Grid Height" inputs to control the resolution of the pixelized image. Higher values will result in more detail but may take longer to process.

3. **Generate SVG**:
   Click the "Generate SVG" button to create an SVG representation of the pixelized image. The preview will display the SVG output.

4. **Export Gno Data**:
   Click the "Generate Gno Data" button to export the pixelized image as Gno function calls. These calls are displayed in the text area and can be copied into your Gno codebase.

---

#### **Important Notes**

- **HTML Restrictions on Gno.land**:
  Gno.land forbids the use of raw HTML in realms. To work around this, the widget is embedded as a data: URL, which allows the HTML content to be safely included without violating platform restrictions.

- **How Pixelized Images Are Stored**:
  In Gno, pixelized images are stored as function callbacks. Each pixel is represented by a function call like p(x, y, r, g, b), where:
  - x and y are the pixel's coordinates,
  - r, g, and b are the red, green, and blue color values of the pixel.
  These function calls are executed to render the image dynamically. This approach avoids storing raw image data and instead relies on procedural generation.
`
const htmlContent = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>CRT SVG Pixelizer (Gno Output)</title>
  <style>
    body {
      font-family: sans-serif;
      padding: 1rem;
    }
    canvas {
      display: none;
    }
    #preview svg {
      border: 1px solid black;
    }
    textarea {
      width: 100%;
      height: 300px;
      margin-top: 1rem;
      font-family: monospace;
    }
  </style>
</head>
<body>

<h2>SVG Pixelizer (Defs + Gno Export)</h2>
<input type="file" id="imageLoader" accept="image/*"><br>
<label>
  Grid Width:
  <input type="number" id="gridWidth" value="50" min="1">
</label>
<label>
  Grid Height:
  <input type="number" id="gridHeight" value="50" min="1">
</label>
<button id="generateBtn">Generate SVG</button>
<button id="gnoExportBtn">Generate Gno Data</button>

<div id="preview"></div>
<textarea id="gnoOutput" placeholder="Gno struct output will appear here..."></textarea>

<script>
const imageLoader = document.getElementById("imageLoader");
const gridWidthInput = document.getElementById("gridWidth");
const gridHeightInput = document.getElementById("gridHeight");
const generateBtn = document.getElementById("generateBtn");
const gnoExportBtn = document.getElementById("gnoExportBtn");
const preview = document.getElementById("preview");
const gnoOutput = document.getElementById("gnoOutput");

let img = new Image();
let lastImageData = null;

// Load the image from the file input
imageLoader.addEventListener("change", (e) => {
  const reader = new FileReader();
  reader.onload = (event) => {
    img.onload = () => console.log("Image loaded successfully.");
    img.src = event.target.result;
  };
  reader.readAsDataURL(e.target.files[0]);
});

// Get image data from the canvas
function getImageData(gridWidth, gridHeight) {
  if (!img.src) {
    alert("Please load an image first.");
    return null;
  }

  const canvas = document.createElement("canvas");
  canvas.width = gridWidth;
  canvas.height = gridHeight;
  const ctx = canvas.getContext("2d");
  ctx.drawImage(img, 0, 0, gridWidth, gridHeight);
  return ctx.getImageData(0, 0, gridWidth, gridHeight).data;
}

// Generate the SVG output
generateBtn.addEventListener("click", () => {
  const gridWidth = parseInt(gridWidthInput.value);
  const gridHeight = parseInt(gridHeightInput.value);
  const tileSize = 25;

  const imageData = getImageData(gridWidth, gridHeight);
  if (!imageData) return;

  lastImageData = imageData;

  const colorMap = new Map();
  const uses = [];

  for (let y = 0; y < gridHeight; y++) {
    for (let x = 0; x < gridWidth; x++) {
      const i = (y * gridWidth + x) * 4;
      const r = imageData[i];
      const g = imageData[i + 1];
      const b = imageData[i + 2];
      const rgb = "rgb(" + r + "," + g + "," + b + ")";

      if (!colorMap.has(rgb)) {
        const className = "c" + colorMap.size;
        colorMap.set(rgb, className);
      }

      const className = colorMap.get(rgb);
      uses.push("<use href=\"#p\" x=\"" + (x * tileSize) + "\" y=\"" + (y * tileSize) + "\" class=\"" + className + "\"/>");
    }
  }

  let style = "<style>\n";
  for (const [rgb, className] of colorMap.entries()) {
    style += "  ." + className + " { fill: " + rgb + "; }\n";
    style += "  ." + className + ":hover { opacity: 0.8; }\n";
  }
  style += "</style>\n";

const svg = "\
<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"" + (gridWidth * tileSize) + "\" height=\"" + (gridHeight * tileSize) + "\">\
  <defs>\
    <rect id=\"p\" width=\"" + tileSize + "\" height=\"" + tileSize + "\" rx=\"3\" ry=\"3\" />\
  </defs>\
  " + style + "\
  " + uses.join("\n  ") + "\
";
 preview.innerHTML = svg;
});

// Generate the Gno data output
gnoExportBtn.addEventListener("click", () => {
  const gridWidth = parseInt(gridWidthInput.value);
  const gridHeight = parseInt(gridHeightInput.value);
  const imageData = lastImageData || getImageData(gridWidth, gridHeight);

  if (!imageData) return;

  let gnoCalls = "";

  for (let y = 0; y < gridHeight; y++) {
    for (let x = 0; x < gridWidth; x++) {
      const i = (y * gridWidth + x) * 4;
      const r = imageData[i];
      const g = imageData[i + 1];
      const b = imageData[i + 2];

      gnoCalls += "p(" + x + ", " + y + ", " + r + ", " + g + ", " + b + ")\n";
    }
  }

  gnoOutput.value = gnoCalls;
});</script>

</body>
</html>
`
