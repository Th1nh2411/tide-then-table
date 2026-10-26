Add-Type -AssemblyName System.Drawing

function New-OpaqueColor($red, $green, $blue) {
    return [Drawing.Color]::FromArgb(255, $red, $green, $blue)
}

function Find-AlphaBounds($bitmap, $region) {
    $left = $region.Right
    $top = $region.Bottom
    $right = $region.Left - 1
    $bottom = $region.Top - 1
    for ($y = $region.Top; $y -lt $region.Bottom; $y++) {
        for ($x = $region.Left; $x -lt $region.Right; $x++) {
            if ($bitmap.GetPixel($x, $y).A -gt 96) {
                $left = [Math]::Min($left, $x)
                $top = [Math]::Min($top, $y)
                $right = [Math]::Max($right, $x)
                $bottom = [Math]::Max($bottom, $y)
            }
        }
    }
    if ($right -lt $left -or $bottom -lt $top) {
        throw "No opaque sprite pixels found in region $region"
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
            $nearestDistance = [int]::MaxValue
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

$sourcePath = 'tmp/imagegen/guest_clean/guest_source.png'
$outputPath = 'tmp/imagegen/guest_clean/guest_clean.png'
$source = [Drawing.Bitmap]::FromFile($sourcePath)
$output = [Drawing.Bitmap]::new(64, 128, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [Drawing.Graphics]::FromImage($output)
$graphics.Clear([Drawing.Color]::Transparent)
$graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::Half
$graphics.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy

for ($row = 0; $row -lt 4; $row++) {
    $cellTop = [int][Math]::Floor($row * $source.Height / 4.0)
    $cellBottom = [int][Math]::Floor(($row + 1) * $source.Height / 4.0)
    for ($column = 0; $column -lt 4; $column++) {
        $cellLeft = [int][Math]::Floor($column * $source.Width / 4.0)
        $cellRight = [int][Math]::Floor(($column + 1) * $source.Width / 4.0)
        $cell = [Drawing.Rectangle]::new($cellLeft, $cellTop, $cellRight - $cellLeft, $cellBottom - $cellTop)
        $bounds = Find-AlphaBounds $source $cell
        $crop = $source.Clone($bounds, [Drawing.Imaging.PixelFormat]::Format32bppArgb)

        $scale = [Math]::Min(14.0 / $crop.Width, 30.0 / $crop.Height)
        $targetWidth = [Math]::Max(1, [int][Math]::Round($crop.Width * $scale))
        $targetHeight = [Math]::Max(1, [int][Math]::Round($crop.Height * $scale))
        $targetX = $column * 16 + [int][Math]::Floor((16 - $targetWidth) / 2.0)
        $targetY = $row * 32 + 31 - $targetHeight
        $target = [Drawing.Rectangle]::new($targetX, $targetY, $targetWidth, $targetHeight)
        $graphics.DrawImage($crop, $target, 0, 0, $crop.Width, $crop.Height, [Drawing.GraphicsUnit]::Pixel)
        $crop.Dispose()
    }
}

$graphics.Dispose()
$source.Dispose()

$palette = @(
    (New-OpaqueColor 5 25 48),
    (New-OpaqueColor 22 27 40),
    (New-OpaqueColor 48 54 70),
    (New-OpaqueColor 239 170 119),
    (New-OpaqueColor 255 211 157),
    (New-OpaqueColor 42 82 126),
    (New-OpaqueColor 71 119 166),
    (New-OpaqueColor 27 39 60),
    (New-OpaqueColor 55 64 82),
    (New-OpaqueColor 126 76 48)
)
Apply-Palette $output $palette
$output.Save($outputPath, [Drawing.Imaging.ImageFormat]::Png)
$output.Dispose()

Write-Output $outputPath
