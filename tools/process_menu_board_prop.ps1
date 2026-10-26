Add-Type -AssemblyName System.Drawing

function New-OpaqueColor($red, $green, $blue) {
    return [Drawing.Color]::FromArgb(255, $red, $green, $blue)
}

function Find-AlphaBounds($bitmap) {
    $left = $bitmap.Width
    $top = $bitmap.Height
    $right = -1
    $bottom = -1
    for ($y = 0; $y -lt $bitmap.Height; $y++) {
        for ($x = 0; $x -lt $bitmap.Width; $x++) {
            if ($bitmap.GetPixel($x, $y).A -ge 128) {
                $left = [Math]::Min($left, $x)
                $top = [Math]::Min($top, $y)
                $right = [Math]::Max($right, $x)
                $bottom = [Math]::Max($bottom, $y)
            }
        }
    }
    if ($right -lt $left -or $bottom -lt $top) {
        throw 'No opaque pixels found in menu board source.'
    }
    return [Drawing.Rectangle]::new($left, $top, $right - $left + 1, $bottom - $top + 1)
}

function Find-NearestColor($pixel, $palette) {
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

$sourcePath = 'tmp/imagegen/menu_board_prop/source.png'
$workingPath = 'tmp/imagegen/menu_board_prop/menu_board.png'
$assetPath = 'assets/sprites/restaurant/menu_board.png'

$source = [Drawing.Bitmap]::FromFile($sourcePath)
$bounds = Find-AlphaBounds $source
$crop = $source.Clone($bounds, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
$source.Dispose()

# Preserve the generated wide silhouette, but normalize it to the documented
# 64x40 master. The non-uniform fit is intentional: the source is an oversized
# concept, while the runtime panel needs a taller empty drawing area.
$output = [Drawing.Bitmap]::new(64, 40, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [Drawing.Graphics]::FromImage($output)
$graphics.Clear([Drawing.Color]::Transparent)
$graphics.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
$graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::Half
$target = [Drawing.Rectangle]::new(1, 1, 62, 38)
$graphics.DrawImage($crop, $target, 0, 0, $crop.Width, $crop.Height, [Drawing.GraphicsUnit]::Pixel)
$graphics.Dispose()
$crop.Dispose()

$palette = @(
    (New-OpaqueColor 9 10 20),
    (New-OpaqueColor 21 29 40),
    (New-OpaqueColor 23 32 56),
    (New-OpaqueColor 44 64 88),
    (New-OpaqueColor 87 114 119),
    (New-OpaqueColor 129 151 150),
    (New-OpaqueColor 199 207 204)
)

for ($y = 0; $y -lt $output.Height; $y++) {
    for ($x = 0; $x -lt $output.Width; $x++) {
        $pixel = $output.GetPixel($x, $y)
        if ($pixel.A -lt 128) {
            $output.SetPixel($x, $y, [Drawing.Color]::Transparent)
        } else {
            $output.SetPixel($x, $y, (Find-NearestColor $pixel $palette))
        }
    }
}

# Code draws all scrolling text and dish icons over this rectangle. Replace
# the generated dotted decoration with one quiet, uninterrupted screen color.
$screen = New-OpaqueColor 9 10 20
for ($y = 6; $y -le 28; $y++) {
    for ($x = 5; $x -le 58; $x++) {
        $output.SetPixel($x, $y, $screen)
    }
}

# Retain a crisp navy inner edge around the blank screen.
$outline = New-OpaqueColor 23 32 56
for ($x = 4; $x -le 59; $x++) {
    $output.SetPixel($x, 5, $outline)
    $output.SetPixel($x, 29, $outline)
}
for ($y = 5; $y -le 29; $y++) {
    $output.SetPixel(4, $y, $outline)
    $output.SetPixel(59, $y, $outline)
}

$output.SetPixel(0, 0, [Drawing.Color]::Transparent)
$output.SetPixel(63, 0, [Drawing.Color]::Transparent)
$output.SetPixel(0, 39, [Drawing.Color]::Transparent)
$output.SetPixel(63, 39, [Drawing.Color]::Transparent)
$output.Save($workingPath, [Drawing.Imaging.ImageFormat]::Png)
$output.Dispose()

Copy-Item -LiteralPath $workingPath -Destination $assetPath
Write-Output $assetPath
