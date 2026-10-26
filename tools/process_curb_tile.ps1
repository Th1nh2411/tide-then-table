param(
    [string]$SourcePath = "tmp/imagegen/curb_tile/source.png",
    [string]$OutputPath = "assets/sprites/restaurant/curb.png",
    [string]$PreviewPath = "tmp/imagegen/curb_tile/curb_tiled_preview.png"
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

if (-not (Test-Path -LiteralPath $SourcePath)) {
    throw "Missing imagegen source: $SourcePath"
}

# The generated image is the composition reference. The final 16 px master is
# hand-cleaned so the horizontal profile is mathematically seamless and every
# color belongs to the Xom Den palette.
$source = [System.Drawing.Image]::FromFile((Resolve-Path -LiteralPath $SourcePath))
$source.Dispose()

$transparent = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)
$outline = [System.Drawing.ColorTranslator]::FromHtml("#151d28")
$edge = [System.Drawing.ColorTranslator]::FromHtml("#394a50")
$front = [System.Drawing.ColorTranslator]::FromHtml("#577277")
$frontLight = [System.Drawing.ColorTranslator]::FromHtml("#819796")
$top = [System.Drawing.ColorTranslator]::FromHtml("#c7cfcc")
$highlight = [System.Drawing.ColorTranslator]::FromHtml("#e7d5b3")

$tile = [System.Drawing.Bitmap]::new(16, 16, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
for ($y = 0; $y -lt 16; $y++) {
    for ($x = 0; $x -lt 16; $x++) {
        $tile.SetPixel($x, $y, $transparent)
    }
}

# Straight continuous silhouette. Edge pixels deliberately match at x=0/15.
for ($x = 0; $x -lt 16; $x++) {
    $tile.SetPixel($x, 4, $outline)
    $tile.SetPixel($x, 5, $highlight)
    $tile.SetPixel($x, 6, $top)
    $tile.SetPixel($x, 7, $top)
    $tile.SetPixel($x, 8, $edge)
    $tile.SetPixel($x, 9, $frontLight)
    $tile.SetPixel($x, 10, $front)
    $tile.SetPixel($x, 11, $front)
    $tile.SetPixel($x, 12, $front)
    $tile.SetPixel($x, 13, $outline)
}

# Two restrained wear clusters, kept away from the repeat boundary.
$tile.SetPixel(5, 7, $frontLight)
$tile.SetPixel(6, 7, $frontLight)
$tile.SetPixel(10, 10, $edge)
$tile.SetPixel(10, 11, $edge)
$tile.SetPixel(11, 11, $edge)

$outputDirectory = Split-Path -Parent $OutputPath
if ($outputDirectory) {
    New-Item -ItemType Directory -Force $outputDirectory | Out-Null
}
$tile.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)

# Eight repeats at 8x nearest-neighbour scale make edge defects obvious.
$preview = [System.Drawing.Bitmap]::new(1024, 128, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [System.Drawing.Graphics]::FromImage($preview)
$graphics.Clear([System.Drawing.ColorTranslator]::FromHtml("#202e37"))
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
for ($i = 0; $i -lt 8; $i++) {
    $destination = [System.Drawing.Rectangle]::new($i * 128, 0, 128, 128)
    $graphics.DrawImage($tile, $destination, 0, 0, 16, 16, [System.Drawing.GraphicsUnit]::Pixel)
}
$graphics.Dispose()
$preview.Save($PreviewPath, [System.Drawing.Imaging.ImageFormat]::Png)
$preview.Dispose()
$tile.Dispose()

Write-Output "Wrote $OutputPath"
Write-Output "Wrote $PreviewPath"
