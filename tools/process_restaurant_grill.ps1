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
        throw 'No opaque pixels found in grill source.'
    }
    return [Drawing.Rectangle]::new($left, $top, $right - $left + 1, $bottom - $top + 1)
}

function Nearest-PaletteColor($pixel, $palette) {
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

function Apply-Palette($bitmap, $palette) {
    for ($y = 0; $y -lt $bitmap.Height; $y++) {
        for ($x = 0; $x -lt $bitmap.Width; $x++) {
            $pixel = $bitmap.GetPixel($x, $y)
            if ($pixel.A -lt 128) {
                $bitmap.SetPixel($x, $y, [Drawing.Color]::Transparent)
            } else {
                $bitmap.SetPixel($x, $y, (Nearest-PaletteColor $pixel $palette))
            }
        }
    }
}

$sourcePath = 'tmp/imagegen/restaurant_grill/source.png'
$outputPath = 'tmp/imagegen/restaurant_grill/grill.png'
$source = [Drawing.Bitmap]::FromFile($sourcePath)
$bounds = Find-AlphaBounds $source
$crop = $source.Clone($bounds, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
$source.Dispose()

# One generated grill is reduced to the documented 32x16 master frame. The
# animation below duplicates only this one asset and changes coal pixels.
$frame = [Drawing.Bitmap]::new(32, 16, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [Drawing.Graphics]::FromImage($frame)
$graphics.Clear([Drawing.Color]::Transparent)
$graphics.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
$graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::Half
$targetWidth = 30
$targetHeight = [Math]::Max(1, [Math]::Min(14, [int][Math]::Round($targetWidth * $crop.Height / $crop.Width)))
$target = [Drawing.Rectangle]::new(1, 15 - $targetHeight, $targetWidth, $targetHeight)
$graphics.DrawImage($crop, $target, 0, 0, $crop.Width, $crop.Height, [Drawing.GraphicsUnit]::Pixel)
$graphics.Dispose()
$crop.Dispose()

$outline = New-OpaqueColor 23 32 56       # 172038
$charcoal = New-OpaqueColor 9 10 20       # 090a14
$clayDark = New-OpaqueColor 96 44 44      # 602c2c
$clay = New-OpaqueColor 165 48 48         # a53030
$clayLight = New-OpaqueColor 207 87 60    # cf573c
$coalRed = New-OpaqueColor 224 48 43      # e0302b
$coalGold = New-OpaqueColor 222 158 65    # de9e41
$steel = New-OpaqueColor 199 207 204      # c7cfcc
$palette = @($outline, $charcoal, $clayDark, $clay, $clayLight, $coalRed, $coalGold, $steel)
Apply-Palette $frame $palette

$sheet = [Drawing.Bitmap]::new(32, 48, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
for ($index = 0; $index -lt 3; $index++) {
    for ($y = 0; $y -lt 16; $y++) {
        for ($x = 0; $x -lt 32; $x++) {
            $pixel = $frame.GetPixel($x, $y)
            if ($pixel.ToArgb() -eq $coalRed.ToArgb() -and (($x + $y + $index) % 3 -eq 0)) {
                $pixel = $coalGold
            } elseif ($pixel.ToArgb() -eq $coalGold.ToArgb() -and (($x * 2 + $y + $index) % 3 -eq 0)) {
                $pixel = $coalRed
            }
            $sheet.SetPixel($x, $y + $index * 16, $pixel)
        }
    }
}
$frame.Dispose()
$sheet.Save($outputPath, [Drawing.Imaging.ImageFormat]::Png)
$sheet.Dispose()

Write-Output $outputPath
