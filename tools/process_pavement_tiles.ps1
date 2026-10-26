Add-Type -AssemblyName System.Drawing

$sourceDir = 'tmp/imagegen/pavement_tiles'
$outputDir = 'tmp/imagegen/pavement_tiles/processed'
$previewPath = 'tmp/imagegen/pavement_tiles/pavement_tiled_preview.png'

New-Item -ItemType Directory -Force $outputDir | Out-Null

$sources = @(
    "$sourceDir/pavement_source.png",
    "$sourceDir/pavement_2_source.png",
    "$sourceDir/pavement_3_source.png"
)

foreach ($sourcePath in $sources) {
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "Missing generated source: $sourcePath"
    }
    $source = [Drawing.Bitmap]::FromFile((Resolve-Path $sourcePath))
    if ($source.Width -lt 16 -or $source.Height -lt 16) {
        $source.Dispose()
        throw "Generated source is too small: $sourcePath"
    }
    $source.Dispose()
}

$transparent = [Drawing.Color]::FromArgb(0, 0, 0, 0)
$outline = [Drawing.Color]::FromArgb(255, 23, 32, 56)       # 172038
$grout = [Drawing.Color]::FromArgb(255, 87, 114, 119)       # 577277
$wear = [Drawing.Color]::FromArgb(255, 57, 74, 80)          # 394a50

function New-PavementTile([int]$variant) {
    $bitmap = [Drawing.Bitmap]::new(16, 16, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    for ($y = 0; $y -lt 16; $y++) {
        for ($x = 0; $x -lt 16; $x++) {
            $bitmap.SetPixel($x, $y, $transparent)
        }
    }

    # A normalized reconstruction of the generated 4x4 paving grid.  The
    # border pixels are intentionally identical across all three variants.
    foreach ($lineX in @(0, 8)) {
        for ($y = 1; $y -lt 15; $y++) {
            $bitmap.SetPixel($lineX, $y, $grout)
        }
    }
    foreach ($lineY in @(0, 8)) {
        for ($x = 1; $x -lt 15; $x++) {
            $bitmap.SetPixel($x, $lineY, $grout)
        }
    }
    $bitmap.SetPixel(8, 8, $outline)

    # Only interior wear differs, keeping every outer-edge pixel compatible.
    switch ($variant) {
        1 {
            $bitmap.SetPixel(4, 5, $wear)
        }
        2 {
            $bitmap.SetPixel(12, 4, $wear)
            $bitmap.SetPixel(13, 4, $wear)
        }
        3 {
            $bitmap.SetPixel(5, 12, $wear)
            $bitmap.SetPixel(11, 11, $wear)
        }
    }

    return $bitmap
}

$names = @('pavement.png', 'pavement_2.png', 'pavement_3.png')
$tiles = @()
for ($index = 0; $index -lt $names.Count; $index++) {
    $tile = New-PavementTile ($index + 1)
    $tile.Save("$outputDir/$($names[$index])", [Drawing.Imaging.ImageFormat]::Png)
    $tiles += $tile
}

# Preview an intentionally mixed 6x6 field at 4x nearest-neighbour scale.
$previewSmall = [Drawing.Bitmap]::new(96, 96, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
$previewGraphics = [Drawing.Graphics]::FromImage($previewSmall)
$previewGraphics.Clear([Drawing.Color]::FromArgb(255, 192, 148, 115))
$previewGraphics.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceOver
for ($row = 0; $row -lt 6; $row++) {
    for ($column = 0; $column -lt 6; $column++) {
        $tile = $tiles[($row * 2 + $column) % $tiles.Count]
        $previewGraphics.DrawImageUnscaled($tile, $column * 16, $row * 16)
    }
}
$previewGraphics.Dispose()

$preview = [Drawing.Bitmap]::new(384, 384, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [Drawing.Graphics]::FromImage($preview)
$graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::Half
$graphics.DrawImage($previewSmall, [Drawing.Rectangle]::new(0, 0, 384, 384), 0, 0, 96, 96, [Drawing.GraphicsUnit]::Pixel)
$graphics.Dispose()
$previewSmall.Dispose()
$preview.Save($previewPath, [Drawing.Imaging.ImageFormat]::Png)
$preview.Dispose()

foreach ($tile in $tiles) {
    $tile.Dispose()
}

Write-Output $outputDir
Write-Output $previewPath
