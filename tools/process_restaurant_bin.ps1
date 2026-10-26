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
        throw 'No opaque pixels found in bin source.'
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

$sourcePath = 'tmp/imagegen/restaurant_bin/source.png'
$workingPath = 'tmp/imagegen/restaurant_bin/bin.png'
$assetPath = 'assets/sprites/restaurant/bin.png'

$source = [Drawing.Bitmap]::FromFile($sourcePath)
$bounds = Find-AlphaBounds $source
$crop = $source.Clone($bounds, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
$source.Dispose()

$output = [Drawing.Bitmap]::new(16, 16, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [Drawing.Graphics]::FromImage($output)
$graphics.Clear([Drawing.Color]::Transparent)
$graphics.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
$graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::Half
$scale = [Math]::Min(14.0 / $crop.Width, 14.0 / $crop.Height)
$width = [Math]::Max(1, [int][Math]::Round($crop.Width * $scale))
$height = [Math]::Max(1, [int][Math]::Round($crop.Height * $scale))
$left = [int][Math]::Floor((16 - $width) / 2)
$top = 15 - $height
$target = [Drawing.Rectangle]::new($left, $top, $width, $height)
$graphics.DrawImage($crop, $target, 0, 0, $crop.Width, $crop.Height, [Drawing.GraphicsUnit]::Pixel)
$graphics.Dispose()
$crop.Dispose()

$palette = @(
    (New-OpaqueColor 23 32 56),
    (New-OpaqueColor 37 58 94),
    (New-OpaqueColor 60 94 139),
    (New-OpaqueColor 79 143 186),
    (New-OpaqueColor 115 190 211),
    (New-OpaqueColor 164 221 219)
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

# The master must keep all four corners transparent at native size.
$output.SetPixel(0, 0, [Drawing.Color]::Transparent)
$output.SetPixel(15, 0, [Drawing.Color]::Transparent)
$output.SetPixel(0, 15, [Drawing.Color]::Transparent)
$output.SetPixel(15, 15, [Drawing.Color]::Transparent)
$output.Save($workingPath, [Drawing.Imaging.ImageFormat]::Png)
$output.Dispose()

Copy-Item -LiteralPath $workingPath -Destination $assetPath
Write-Output $assetPath
