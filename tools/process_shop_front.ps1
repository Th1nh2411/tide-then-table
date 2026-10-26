param(
    [string]$Source = "tmp/imagegen/shop_front/source.png",
    [string]$Output = "assets/sprites/restaurant/shop_front.png",
    [string]$PreviewDir = "tmp/imagegen/shop_front"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

function New-Color([string]$hex) {
    return [System.Drawing.ColorTranslator]::FromHtml("#$hex")
}

$palette = @(
    (New-Color "151d28"), (New-Color "202e37"), (New-Color "394a50"),
    (New-Color "3c5e8b"), (New-Color "4f8fba"), (New-Color "c7cfcc"),
    (New-Color "7a4841"),
    (New-Color "ad7757"), (New-Color "d7b594"), (New-Color "de9e41"),
    (New-Color "e8c170"), (New-Color "468232")
)

function Nearest-PaletteColor([System.Drawing.Color]$color) {
    $best = $palette[0]
    $bestDistance = [double]::PositiveInfinity
    foreach ($candidate in $palette) {
        $dr = [int]$color.R - [int]$candidate.R
        $dg = [int]$color.G - [int]$candidate.G
        $db = [int]$color.B - [int]$candidate.B
        $distance = 2 * $dr * $dr + 4 * $dg * $dg + 3 * $db * $db
        if ($distance -lt $bestDistance) {
            $bestDistance = $distance
            $best = $candidate
        }
    }
    return $best
}

function Set-Block(
    [System.Drawing.Bitmap]$bitmap,
    [int]$x,
    [int]$y,
    [int]$width,
    [int]$height,
    [System.Drawing.Color]$color
) {
    for ($py = $y; $py -lt [Math]::Min($y + $height, $bitmap.Height); $py++) {
        for ($px = $x; $px -lt [Math]::Min($x + $width, $bitmap.Width); $px++) {
            if ($px -ge 0 -and $py -ge 0) { $bitmap.SetPixel($px, $py, $color) }
        }
    }
}

function Sample-Region(
    [System.Drawing.Bitmap]$sourceBitmap,
    [System.Drawing.Bitmap]$targetBitmap,
    [System.Drawing.Rectangle]$sourceRect,
    [System.Drawing.Rectangle]$targetRect
) {
    # Sample the large image directly into 2x2 clusters on the 640x80 master.
    # There is deliberately no intermediate low-resolution master and no upscale.
    for ($y = $targetRect.Top; $y -lt $targetRect.Bottom; $y += 2) {
        for ($x = $targetRect.Left; $x -lt $targetRect.Right; $x += 2) {
            $u = ($x - $targetRect.Left + 1.0) / $targetRect.Width
            $v = ($y - $targetRect.Top + 1.0) / $targetRect.Height
            $sx = [Math]::Min($sourceRect.Right - 1, $sourceRect.Left + [int]($u * $sourceRect.Width))
            $sy = [Math]::Min($sourceRect.Bottom - 1, $sourceRect.Top + [int]($v * $sourceRect.Height))
            $sample = $sourceBitmap.GetPixel($sx, $sy)
            $mapped = Nearest-PaletteColor $sample
            Set-Block $targetBitmap $x $y 2 2 $mapped
        }
    }
}

$sourcePath = (Resolve-Path $Source).Path
$outputPath = Join-Path (Resolve-Path (Split-Path $Output -Parent)).Path (Split-Path $Output -Leaf)
New-Item -ItemType Directory -Force -Path $PreviewDir | Out-Null

$src = [System.Drawing.Bitmap]::FromFile($sourcePath)
$master = New-Object System.Drawing.Bitmap 640, 80, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
try {
    # Old wall/lintel sampled from the generated source across the whole facade.
    Sample-Region $src $master ([System.Drawing.Rectangle]::new(48, 188, 1884, 392)) ([System.Drawing.Rectangle]::new(4, 2, 632, 76))

    # Collapse generated speckle into large, hand-placed wall and pillar clusters.
    # The source still determines the approved composition, while the game master
    # uses the restrained visual density of the other Xóm Đèn sprites.
    $navy = New-Color "151d28"
    $wallDark = New-Color "7a4841"
    $wallMid = New-Color "ad7757"
    $wallLight = New-Color "d7b594"
    Set-Block $master 4 2 632 76 $wallMid
    Set-Block $master 4 2 632 3 $navy
    Set-Block $master 4 5 632 11 $wallLight
    Set-Block $master 4 14 632 3 $wallDark
    Set-Block $master 4 17 632 2 $navy

    foreach ($pillar in @(@(4,8), @(168,48), @(376,80), @(616,20))) {
        $left = $pillar[0]; $width = $pillar[1]
        Set-Block $master $left 18 $width 60 $wallMid
    }
    foreach ($columnX in @(4, 186, 410, 624)) {
        Set-Block $master $columnX 18 10 60 $navy
        Set-Block $master ($columnX+3) 20 4 56 $wallLight
    }

    # Recompose the three authored bays at the exact gameplay coordinates.
    Sample-Region $src $master ([System.Drawing.Rectangle]::new(72, 248, 506, 332)) ([System.Drawing.Rectangle]::new(8, 18, 160, 60))
    Sample-Region $src $master ([System.Drawing.Rectangle]::new(704, 248, 532, 332)) ([System.Drawing.Rectangle]::new(216, 18, 160, 60))
    Sample-Region $src $master ([System.Drawing.Rectangle]::new(1340, 248, 558, 332)) ([System.Drawing.Rectangle]::new(456, 18, 160, 60))

    $blue = New-Color "3c5e8b"
    $blueLight = New-Color "4f8fba"
    $cream = New-Color "c7cfcc"
    $green = New-Color "468232"
    $greenLight = New-Color "468232"
    $shutterDark = New-Color "202e37"
    $shutterMid = New-Color "394a50"
    $warmDark = New-Color "7a4841"
    $warm = New-Color "de9e41"
    $warmLight = New-Color "e8c170"

    # Strong simple silhouettes replace noisy generated details.
    foreach ($bay in @(@(8,168), @(216,376))) {
        $left = $bay[0]; $right = $bay[1]
        Set-Block $master $left 32 ($right-$left) 46 $navy
        Set-Block $master ($left+4) 35 ($right-$left-8) 41 $shutterDark
        for ($yy = 38; $yy -le 72; $yy += 6) {
            Set-Block $master ($left+6) $yy ($right-$left-12) 2 $shutterMid
        }
    }

    # Open, warm Cô Năm grocery interior with only a few readable shelf clusters.
    Set-Block $master 456 31 160 47 $navy
    Set-Block $master 460 34 152 42 $warmDark
    Set-Block $master 464 36 144 38 $warm
    foreach ($shelfY in @(48, 60, 70)) {
        Set-Block $master 470 $shelfY 132 2 $navy
    }
    foreach ($x in @(474, 492, 516, 544, 568, 590)) {
        Set-Block $master $x 42 8 6 $warmLight
        Set-Block $master ($x+2) 54 8 6 $greenLight
        Set-Block $master $x 64 10 6 $blueLight
    }

    # Exact striped awning bands: blue/off-white over left and middle, green/off-white at right.
    function Paint-Awning([int]$left, [int]$right, [System.Drawing.Color]$stripeA, [System.Drawing.Color]$stripeB) {
        Set-Block $master $left 17 ($right-$left) 3 $navy
        for ($x = $left+2; $x -lt $right-2; $x += 12) {
            $index = [int][Math]::Floor(($x-$left-2)/12)
            $color = if (($index % 2) -eq 0) { $stripeA } else { $stripeB }
            Set-Block $master $x 20 ([Math]::Min(12,$right-2-$x)) 10 $color
        }
        Set-Block $master $left 30 ($right-$left) 2 $navy
        for ($x = $left+2; $x -lt $right-2; $x += 12) {
            $index = [int][Math]::Floor(($x-$left-2)/12)
            $color = if (($index % 2) -eq 0) { $stripeA } else { $stripeB }
            Set-Block $master $x 32 ([Math]::Min(10,$right-2-$x)) 2 $color
        }
    }
    Paint-Awning 8 168 $blue $cream
    Paint-Awning 216 376 $blue $cream
    Paint-Awning 448 624 $green $cream

    # Three broad wear marks; never use isolated one-pixel noise.
    Set-Block $master 184 9 12 3 $wallMid
    Set-Block $master 398 7 18 3 $wallDark
    Set-Block $master 432 47 10 4 $wallDark

    # Transparent margin guarantees all four corners are alpha 0.
    for ($x = 0; $x -lt 640; $x++) {
        $master.SetPixel($x, 0, [System.Drawing.Color]::Transparent)
        $master.SetPixel($x, 79, [System.Drawing.Color]::Transparent)
    }
    for ($y = 0; $y -lt 80; $y++) {
        for ($x = 0; $x -lt 4; $x++) { $master.SetPixel($x, $y, [System.Drawing.Color]::Transparent) }
        for ($x = 636; $x -lt 640; $x++) { $master.SetPixel($x, $y, [System.Drawing.Color]::Transparent) }
    }

    $master.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $master.Save((Join-Path $PreviewDir "preview_100pct.png"), [System.Drawing.Imaging.ImageFormat]::Png)

    $overview = New-Object System.Drawing.Bitmap 320, 40, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    try {
        $graphics = [System.Drawing.Graphics]::FromImage($overview)
        try {
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
            $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
            $graphics.DrawImage($master, 0, 0, 320, 40)
        } finally { $graphics.Dispose() }
        $overview.Save((Join-Path $PreviewDir "preview_overview_320x40.png"), [System.Drawing.Imaging.ImageFormat]::Png)
    } finally { $overview.Dispose() }
} finally {
    $master.Dispose()
    $src.Dispose()
}

Write-Output "Wrote $outputPath"
