package bmp


const html =`
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title> BMP | Pixelizer (Gno Output)</title>
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

<h2> BMP | Pixelizer (Defs + Gno Export)</h2>
<p>
    This is a simple pixelizer that takes an image and converts it into a pixelated version using SVG. The pixelated image is then exported as a Gno file.
</p>
</body>
</html>
`