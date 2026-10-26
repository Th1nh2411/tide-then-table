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
        throw 'No opaque pixels found in source image.'
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

function Convert-PixelAsset($sourcePath, $outputPath, $target, $palette) {
    $source = [Drawing.Bitmap]::FromFile($sourcePath)
    $bounds = Find-AlphaBounds $source
    $crop = $source.Clone($bounds, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $source.Dispose()

    $output = [Drawing.Bitmap]::new(32, 32, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [Drawing.Graphics]::FromImage($output)
    $graphics.Clear([Drawing.Color]::Transparent)
    $graphics.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
    $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::Half
    $graphics.DrawImage($crop, $target, 0, 0, $crop.Width, $crop.Height, [Drawing.GraphicsUnit]::Pixel)
    $graphics.Dispose()
    $crop.Dispose()

    Apply-Palette $output $palette
    $output.Save($outputPath, [Drawing.Imaging.ImageFormat]::Png)
    $output.Dispose()
}

$navy = New-OpaqueColor 21 29 40
$steelDark = New-OpaqueColor 57 74 80
$steelMid = New-OpaqueColor 129 151 150
$steelLight = New-OpaqueColor 199 207 204
$white = New-OpaqueColor 235 237 233
$cream = New-OpaqueColor 231 213 179
$red = New-OpaqueColor 165 48 48
$brown = New-OpaqueColor 122 72 65
$orange = New-OpaqueColor 190 119 43

$tablePalette = @($navy, $steelDark, $steelMid, $steelLight, $white, $cream, $red, $brown)
$dirtyPalette = @($navy, $steelMid, $white, $cream, $brown, $orange)

Convert-PixelAsset `
    'tmp/imagegen/restaurant_tables/table_source.png' `
    'tmp/imagegen/restaurant_tables/table.png' `
    ([Drawing.Rectangle]::new(1, 1, 30, 30)) `
    $tablePalette

# Align the dirty plate with StreetRoomPainter's plate center near (10, 7).
Convert-PixelAsset `
    'tmp/imagegen/restaurant_tables/table_dirty_source.png' `
    'tmp/imagegen/restaurant_tables/table_dirty.png' `
    ([Drawing.Rectangle]::new(1, 1, 18, 12)) `
    $dirtyPalette

Write-Output 'tmp/imagegen/restaurant_tables/table.png'
Write-Output 'tmp/imagegen/restaurant_tables/table_dirty.png'
