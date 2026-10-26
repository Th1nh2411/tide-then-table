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
            if ($bitmap.GetPixel($x, $y).A -gt 96) {
                $left = [Math]::Min($left, $x)
                $top = [Math]::Min($top, $y)
                $right = [Math]::Max($right, $x)
                $bottom = [Math]::Max($bottom, $y)
            }
        }
    }
    if ($right -lt $left -or $bottom -lt $top) {
        throw 'No opaque pixels found in food cart source.'
    }
    return [Drawing.Rectangle]::new($left, $top, $right - $left + 1, $bottom - $top + 1)
}

function Apply-Palette($bitmap, $palette) {
    for ($y = 0; $y -lt $bitmap.Height; $y++) {
        for ($x = 0; $x -lt $bitmap.Width; $x++) {
            $pixel = $bitmap.GetPixel($x, $y)
            if ($pixel.A -lt 128) {
                $bitmap.SetPixel($x, $y, [Drawing.Color]::Transparent)
                continue
            }
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
            $bitmap.SetPixel($x, $y, $nearest)
        }
    }
}

$sourcePath = 'tmp/imagegen/food_cart_0/source.png'
$outputPath = 'tmp/imagegen/food_cart_0/food_cart_0.png'
$source = [Drawing.Bitmap]::FromFile($sourcePath)
$bounds = Find-AlphaBounds $source
$crop = $source.Clone($bounds, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
$source.Dispose()

$output = [Drawing.Bitmap]::new(64, 32, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [Drawing.Graphics]::FromImage($output)
$graphics.Clear([Drawing.Color]::Transparent)
$graphics.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
$graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::Half
$target = [Drawing.Rectangle]::new(1, 2, 62, 30)
$graphics.DrawImage($crop, $target, 0, 0, $crop.Width, $crop.Height, [Drawing.GraphicsUnit]::Pixel)
$graphics.Dispose()
$crop.Dispose()

$palette = @(
    (New-OpaqueColor 23 32 56),
    (New-OpaqueColor 57 74 80),
    (New-OpaqueColor 129 151 150),
    (New-OpaqueColor 199 207 204),
    (New-OpaqueColor 235 237 233),
    (New-OpaqueColor 165 48 48),
    (New-OpaqueColor 192 148 115),
    (New-OpaqueColor 222 158 65)
)
Apply-Palette $output $palette
$output.Save($outputPath, [Drawing.Imaging.ImageFormat]::Png)
$output.Dispose()

Write-Output $outputPath
