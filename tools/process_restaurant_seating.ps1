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

function Convert-Stool($sourcePath, $outputPath, $palette) {
    $source = [Drawing.Bitmap]::FromFile($sourcePath)
    $bounds = Find-AlphaBounds $source
    $crop = $source.Clone($bounds, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $source.Dispose()

    $maxWidth = 14
    $maxHeight = 14
    $scale = [Math]::Min($maxWidth / $crop.Width, $maxHeight / $crop.Height)
    $width = [Math]::Max(1, [Math]::Round($crop.Width * $scale))
    $height = [Math]::Max(1, [Math]::Round($crop.Height * $scale))
    $left = [Math]::Floor((16 - $width) / 2)
    $top = 16 - $height

    $output = [Drawing.Bitmap]::new(16, 16, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [Drawing.Graphics]::FromImage($output)
    $graphics.Clear([Drawing.Color]::Transparent)
    $graphics.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
    $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::Half
    $target = [Drawing.Rectangle]::new($left, $top, $width, $height)
    $graphics.DrawImage($crop, $target, 0, 0, $crop.Width, $crop.Height, [Drawing.GraphicsUnit]::Pixel)
    $graphics.Dispose()
    $crop.Dispose()

    Apply-Palette $output $palette
    $output.Save($outputPath, [Drawing.Imaging.ImageFormat]::Png)
    $output.Dispose()
}

function Convert-BenchTile($sourcePath, $outputPath, $palette) {
    $source = [Drawing.Bitmap]::FromFile($sourcePath)
    $bounds = Find-AlphaBounds $source
    # Use a central segment, not the generated end caps. The game repeats this
    # tile horizontally, so the subject must meet both side edges evenly.
    $segmentWidth = [Math]::Min($bounds.Width, $bounds.Height)
    $segmentLeft = $bounds.X + [Math]::Floor(($bounds.Width - $segmentWidth) / 2)
    $segment = [Drawing.Rectangle]::new($segmentLeft, $bounds.Y, $segmentWidth, $bounds.Height)
    $crop = $source.Clone($segment, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $source.Dispose()

    $output = [Drawing.Bitmap]::new(16, 16, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [Drawing.Graphics]::FromImage($output)
    $graphics.Clear([Drawing.Color]::Transparent)
    $graphics.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
    $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::Half
    $target = [Drawing.Rectangle]::new(0, 1, 16, 14)
    $graphics.DrawImage($crop, $target, 0, 0, $crop.Width, $crop.Height, [Drawing.GraphicsUnit]::Pixel)
    $graphics.Dispose()
    $crop.Dispose()

    Apply-Palette $output $palette
    $output.Save($outputPath, [Drawing.Imaging.ImageFormat]::Png)
    $output.Dispose()
}

$sourceRoot = 'tmp/imagegen/restaurant_seating'
$assetRoot = 'assets/sprites/restaurant'
$outline = New-OpaqueColor 23 32 56

$bluePalette = @(
    $outline,
    (New-OpaqueColor 37 58 94),
    (New-OpaqueColor 60 94 139),
    (New-OpaqueColor 79 143 186),
    (New-OpaqueColor 115 190 211)
)
$redPalette = @(
    $outline,
    (New-OpaqueColor 96 44 44),
    (New-OpaqueColor 165 48 48),
    (New-OpaqueColor 207 87 60)
)
$woodPalette = @(
    $outline,
    (New-OpaqueColor 77 43 50),
    (New-OpaqueColor 122 72 65),
    (New-OpaqueColor 173 119 87),
    (New-OpaqueColor 192 148 115)
)

Convert-Stool "$sourceRoot/stool_0_source.png" "$sourceRoot/stool_0.png" $bluePalette
Convert-Stool "$sourceRoot/stool_1_source.png" "$sourceRoot/stool_1.png" $redPalette
Convert-BenchTile "$sourceRoot/plate_bench_source.png" "$sourceRoot/plate_bench.png" $woodPalette

Copy-Item -LiteralPath "$sourceRoot/stool_0.png" -Destination "$assetRoot/stool_0.png"
Copy-Item -LiteralPath "$sourceRoot/stool_1.png" -Destination "$assetRoot/stool_1.png"
Copy-Item -LiteralPath "$sourceRoot/plate_bench.png" -Destination "$assetRoot/plate_bench.png"

Write-Output "$assetRoot/stool_0.png"
Write-Output "$assetRoot/stool_1.png"
Write-Output "$assetRoot/plate_bench.png"
