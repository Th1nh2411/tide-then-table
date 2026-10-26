Add-Type -AssemblyName System.Drawing

function New-Color($hex) {
    $value = $hex.TrimStart('#')
    return [Drawing.Color]::FromArgb(
        255,
        [Convert]::ToInt32($value.Substring(0, 2), 16),
        [Convert]::ToInt32($value.Substring(2, 2), 16),
        [Convert]::ToInt32($value.Substring(4, 2), 16)
    )
}

function Get-AlphaBounds($bitmap, $region) {
    $left = $region.Right
    $top = $region.Bottom
    $right = -1
    $bottom = -1
    for ($y = $region.Top; $y -lt $region.Bottom; $y++) {
        for ($x = $region.Left; $x -lt $region.Right; $x++) {
            if ($bitmap.GetPixel($x, $y).A -ge 128) {
                $left = [Math]::Min($left, $x)
                $top = [Math]::Min($top, $y)
                $right = [Math]::Max($right, $x)
                $bottom = [Math]::Max($bottom, $y)
            }
        }
    }
    if ($right -lt $left) { throw "No opaque pixels found in $region" }
    return [Drawing.Rectangle]::new($left, $top, $right - $left + 1, $bottom - $top + 1)
}

function Get-NearestColor($pixel, $palette) {
    $nearest = $palette[0]
    $nearestDistance = [double]::MaxValue
    foreach ($candidate in $palette) {
        $distance = [Math]::Pow($pixel.R - $candidate.R, 2) +
            [Math]::Pow($pixel.G - $candidate.G, 2) +
            [Math]::Pow($pixel.B - $candidate.B, 2)
        if ($distance -lt $nearestDistance) {
            $nearestDistance = $distance
            $nearest = $candidate
        }
    }
    return $nearest
}

function Reduce-Palette($bitmap, $palette) {
    for ($y = 0; $y -lt $bitmap.Height; $y++) {
        for ($x = 0; $x -lt $bitmap.Width; $x++) {
            $pixel = $bitmap.GetPixel($x, $y)
            if ($pixel.A -lt 128) {
                $bitmap.SetPixel($x, $y, [Drawing.Color]::Transparent)
            } else {
                $bitmap.SetPixel($x, $y, (Get-NearestColor $pixel $palette))
            }
        }
    }
}

function Draw-ReducedAsset($sourcePath, $width, $height, $target, $palette) {
    $source = [Drawing.Bitmap]::FromFile($sourcePath)
    $bounds = Get-AlphaBounds $source ([Drawing.Rectangle]::new(0, 0, $source.Width, $source.Height))
    $crop = $source.Clone($bounds, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $source.Dispose()

    $output = [Drawing.Bitmap]::new($width, $height, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [Drawing.Graphics]::FromImage($output)
    $graphics.Clear([Drawing.Color]::Transparent)
    $graphics.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
    $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::Half
    $graphics.DrawImage($crop, $target, 0, 0, $crop.Width, $crop.Height, [Drawing.GraphicsUnit]::Pixel)
    $graphics.Dispose()
    $crop.Dispose()
    Reduce-Palette $output $palette
    return $output
}

function Set-Corners-Transparent($bitmap) {
    $bitmap.SetPixel(0, 0, [Drawing.Color]::Transparent)
    $bitmap.SetPixel($bitmap.Width - 1, 0, [Drawing.Color]::Transparent)
    $bitmap.SetPixel(0, $bitmap.Height - 1, [Drawing.Color]::Transparent)
    $bitmap.SetPixel($bitmap.Width - 1, $bitmap.Height - 1, [Drawing.Color]::Transparent)
}

function Add-ContactShadow($bitmap, $y, $left, $right) {
    $shadow = New-Color '202e37'
    for ($x = $left; $x -le $right; $x++) {
        $bitmap.SetPixel($x, $y, $shadow)
    }
}

function Save-Asset($bitmap, $path) {
    Set-Corners-Transparent $bitmap
    $bitmap.Save($path, [Drawing.Imaging.ImageFormat]::Png)
    $bitmap.Dispose()
}

$root = 'tmp/imagegen/perspective_dining'
$assetRoot = 'assets/sprites/restaurant'
$navy = New-Color '172038'
$shadow = New-Color '202e37'

$steelPalette = @(
    $navy, $shadow, (New-Color '394a50'), (New-Color '577277'),
    (New-Color '819796'), (New-Color 'c7cfcc'), (New-Color 'ebede9'),
    (New-Color 'a53030'), (New-Color 'cf573c'), (New-Color 'de9e41'),
    (New-Color '468232'), (New-Color 'a8ca58')
)
$grillPalette = @(
    $navy, (New-Color '090a14'), (New-Color '602c2c'), (New-Color '884b2b'),
    (New-Color 'a53030'), (New-Color 'cf573c'), (New-Color 'e0302b'), (New-Color 'de9e41')
)
$dirtyPalette = @(
    $navy, (New-Color '7a4841'), (New-Color 'ad7757'), (New-Color 'be772b'),
    (New-Color 'de9e41'), (New-Color 'd7b594'), (New-Color 'ebede9'), (New-Color '468232')
)
$bluePalette = @($navy, $shadow, (New-Color '253a5e'), (New-Color '3c5e8b'), (New-Color '4f8fba'), (New-Color '73bed3'))
$redPalette = @($navy, $shadow, (New-Color '602c2c'), (New-Color 'a53030'), (New-Color 'cf573c'))
$woodPalette = @($navy, $shadow, (New-Color '4d2b32'), (New-Color '7a4841'), (New-Color 'ad7757'), (New-Color 'c09473'))

$cart = Draw-ReducedAsset "$root/food_cart_0_source.png" 64 32 ([Drawing.Rectangle]::new(1, 1, 62, 29)) $steelPalette
Add-ContactShadow $cart 30 5 15
Add-ContactShadow $cart 30 48 58
Save-Asset $cart "$root/food_cart_0.png"

# The generated source contains exactly three vertically stacked grill poses.
$grillSource = [Drawing.Bitmap]::FromFile("$root/grill_source.png")
$grillSheet = [Drawing.Bitmap]::new(32, 48, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
for ($frameIndex = 0; $frameIndex -lt 3; $frameIndex++) {
    $regionTop = [int][Math]::Floor($grillSource.Height * $frameIndex / 3)
    $regionBottom = [int][Math]::Floor($grillSource.Height * ($frameIndex + 1) / 3)
    $region = [Drawing.Rectangle]::new(0, $regionTop, $grillSource.Width, $regionBottom - $regionTop)
    $bounds = Get-AlphaBounds $grillSource $region
    $crop = $grillSource.Clone($bounds, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $frame = [Drawing.Bitmap]::new(32, 16, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [Drawing.Graphics]::FromImage($frame)
    $graphics.Clear([Drawing.Color]::Transparent)
    $graphics.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
    $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::Half
    $graphics.DrawImage($crop, [Drawing.Rectangle]::new(1, 1, 30, 13), 0, 0, $crop.Width, $crop.Height, [Drawing.GraphicsUnit]::Pixel)
    $graphics.Dispose(); $crop.Dispose()
    Reduce-Palette $frame $grillPalette
    Add-ContactShadow $frame 14 4 27
    Set-Corners-Transparent $frame
    for ($y = 0; $y -lt 16; $y++) {
        for ($x = 0; $x -lt 32; $x++) { $grillSheet.SetPixel($x, $y + 16 * $frameIndex, $frame.GetPixel($x, $y)) }
    }
    $frame.Dispose()
}
$grillSource.Dispose()
Save-Asset $grillSheet "$root/grill.png"

$table = Draw-ReducedAsset "$root/table_source.png" 32 32 ([Drawing.Rectangle]::new(1, 1, 30, 28)) $steelPalette
Add-ContactShadow $table 29 3 28
Save-Asset $table "$root/table.png"

$dirty = Draw-ReducedAsset "$root/table_dirty_source.png" 32 32 ([Drawing.Rectangle]::new(7, 5, 18, 14)) $dirtyPalette
Save-Asset $dirty "$root/table_dirty.png"

$stool0 = Draw-ReducedAsset "$root/stool_0_source.png" 16 16 ([Drawing.Rectangle]::new(2, 1, 12, 13)) $bluePalette
Add-ContactShadow $stool0 14 3 12
Save-Asset $stool0 "$root/stool_0.png"

$stool1 = Draw-ReducedAsset "$root/stool_1_source.png" 16 16 ([Drawing.Rectangle]::new(2, 1, 12, 13)) $redPalette
Add-ContactShadow $stool1 14 3 12
Save-Asset $stool1 "$root/stool_1.png"

# A central square segment avoids the generated end caps and tiles cleanly.
$benchSource = [Drawing.Bitmap]::FromFile("$root/plate_bench_source.png")
$benchBounds = Get-AlphaBounds $benchSource ([Drawing.Rectangle]::new(0, 0, $benchSource.Width, $benchSource.Height))
$segmentWidth = [Math]::Min($benchBounds.Height, [int][Math]::Floor($benchBounds.Width / 4))
$segmentX = $benchBounds.X + [int][Math]::Floor(($benchBounds.Width - $segmentWidth) / 2)
$benchCrop = $benchSource.Clone([Drawing.Rectangle]::new($segmentX, $benchBounds.Y, $segmentWidth, $benchBounds.Height), [Drawing.Imaging.PixelFormat]::Format32bppArgb)
$benchSource.Dispose()
$bench = [Drawing.Bitmap]::new(16, 16, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
$benchGraphics = [Drawing.Graphics]::FromImage($bench)
$benchGraphics.Clear([Drawing.Color]::Transparent)
$benchGraphics.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
$benchGraphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$benchGraphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::Half
$benchGraphics.DrawImage($benchCrop, [Drawing.Rectangle]::new(0, 1, 16, 13), 0, 0, $benchCrop.Width, $benchCrop.Height, [Drawing.GraphicsUnit]::Pixel)
$benchGraphics.Dispose(); $benchCrop.Dispose()
Reduce-Palette $bench $woodPalette
Add-ContactShadow $bench 14 1 14
Save-Asset $bench "$root/plate_bench.png"

foreach ($name in @('food_cart_0', 'grill', 'table', 'table_dirty', 'stool_0', 'stool_1', 'plate_bench')) {
    Copy-Item -LiteralPath "$root/$name.png" -Destination "$assetRoot/$name.png"
}

# Native-scale contact sheet for checking relative footprint and grounding.
$sheet = [Drawing.Bitmap]::new(144, 72, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
$sheetGraphics = [Drawing.Graphics]::FromImage($sheet)
$sheetGraphics.Clear((New-Color '090a14'))
$placements = @(
    @('food_cart_0', 4, 4), @('grill', 72, 4), @('table', 108, 4),
    @('stool_0', 4, 52), @('stool_1', 24, 52), @('plate_bench', 44, 52), @('table_dirty', 64, 36)
)
foreach ($placement in $placements) {
    $sprite = [Drawing.Bitmap]::FromFile("$root/$($placement[0]).png")
    $sheetGraphics.DrawImageUnscaled($sprite, $placement[1], $placement[2])
    $sprite.Dispose()
}
$sheetGraphics.Dispose()
$sheet.Save("$root/contact_sheet.png", [Drawing.Imaging.ImageFormat]::Png)
$sheet.Dispose()

Write-Output 'Processed orthographic dining props.'
