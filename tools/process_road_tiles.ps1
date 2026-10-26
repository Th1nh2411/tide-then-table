param(
    [string]$SourceDir = "tmp/imagegen/road_tiles",
    [string]$OutputDir = "assets/sprites/restaurant"
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$roadSource = Join-Path $SourceDir "road_source.png"
$lineSource = Join-Path $SourceDir "road_line_source.png"
if (-not (Test-Path -LiteralPath $roadSource) -or -not (Test-Path -LiteralPath $lineSource)) {
    throw "Missing imagegen road source files in $SourceDir"
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$transparent = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)
$asphaltDark = [System.Drawing.ColorTranslator]::FromHtml("#202e37")
$asphaltLight = [System.Drawing.ColorTranslator]::FromHtml("#394a50")
$lineDark = [System.Drawing.ColorTranslator]::FromHtml("#de9e41")
$lineLight = [System.Drawing.ColorTranslator]::FromHtml("#e8c170")

function New-OverlayBitmap {
    $bitmap = [System.Drawing.Bitmap]::new(16, 16, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    for ($y = 0; $y -lt 16; $y++) {
        for ($x = 0; $x -lt 16; $x++) {
            $bitmap.SetPixel($x, $y, $transparent)
        }
    }
    return $bitmap
}

function Add-RoadDetails([System.Drawing.Bitmap]$bitmap) {
    # Sparse clusters selected from the generated road source and hand-cleaned
    # for native 16x16 readability. No edge pixels keeps repetition seamless.
    $darkPixels = @(
        @(2, 3), @(11, 4),
        @(6, 9), @(7, 9), @(7, 10), @(8, 10),
        @(13, 12)
    )
    $lightPixels = @(
        @(3, 3), @(11, 5), @(6, 10), @(12, 12)
    )
    foreach ($p in $darkPixels) { $bitmap.SetPixel($p[0], $p[1], $asphaltDark) }
    foreach ($p in $lightPixels) { $bitmap.SetPixel($p[0], $p[1], $asphaltLight) }
}

$road = New-OverlayBitmap
Add-RoadDetails $road
$road.Save((Join-Path $OutputDir "road.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$road.Dispose()

$roadLine = New-OverlayBitmap
Add-RoadDetails $roadLine
for ($x = 0; $x -lt 16; $x++) {
    $roadLine.SetPixel($x, 7, $lineLight)
    $roadLine.SetPixel($x, 8, $lineDark)
}
# A few hard-edged worn paint pixels, while both horizontal joins stay intact.
$roadLine.SetPixel(4, 7, $lineDark)
$roadLine.SetPixel(10, 8, $lineLight)
$roadLine.Save((Join-Path $OutputDir "road_line.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$roadLine.Dispose()

# Tiled preview over the asphalt fill used by the renderer. Nearest-neighbor
# scaling makes the native pixels easy to inspect without adding new colors.
$preview = [System.Drawing.Bitmap]::new(512, 256, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [System.Drawing.Graphics]::FromImage($preview)
$graphics.Clear([System.Drawing.ColorTranslator]::FromHtml("#151d28"))
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$roadTile = [System.Drawing.Bitmap]::new((Resolve-Path (Join-Path $OutputDir "road.png")).Path)
$lineTile = [System.Drawing.Bitmap]::new((Resolve-Path (Join-Path $OutputDir "road_line.png")).Path)
for ($y = 0; $y -lt 8; $y++) {
    for ($x = 0; $x -lt 16; $x++) {
        $tile = if ($y -eq 3 -or $y -eq 6) { $lineTile } else { $roadTile }
        $graphics.DrawImage($tile, $x * 32, $y * 32, 32, 32)
    }
}
$previewPath = Join-Path $SourceDir "road_tiles_preview.png"
$preview.Save($previewPath, [System.Drawing.Imaging.ImageFormat]::Png)
$roadTile.Dispose()
$lineTile.Dispose()
$graphics.Dispose()
$preview.Dispose()

Write-Output "Wrote road.png, road_line.png, and $previewPath"
