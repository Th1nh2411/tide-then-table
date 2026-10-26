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
        throw 'No opaque pixels found in grocery-stall source.'
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

function Convert-IsolatedAsset($sourcePath, $outputPath, $width, $height, $target, $palette) {
    $source = [Drawing.Bitmap]::FromFile($sourcePath)
    $bounds = Find-AlphaBounds $source
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

    Apply-Palette $output $palette
    $output.Save($outputPath, [Drawing.Imaging.ImageFormat]::Png)
    $output.Dispose()
}

function New-NearestPreview($sourcePath, $outputPath, $scale) {
    $source = [Drawing.Bitmap]::FromFile($sourcePath)
    $preview = [Drawing.Bitmap]::new($source.Width * $scale, $source.Height * $scale, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [Drawing.Graphics]::FromImage($preview)
    $graphics.Clear([Drawing.Color]::Transparent)
    $graphics.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
    $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::Half
    $graphics.DrawImage($source, [Drawing.Rectangle]::new(0, 0, $preview.Width, $preview.Height), 0, 0, $source.Width, $source.Height, [Drawing.GraphicsUnit]::Pixel)
    $graphics.Dispose()
    $source.Dispose()
    $preview.Save($outputPath, [Drawing.Imaging.ImageFormat]::Png)
    $preview.Dispose()
}

function New-RepeatedCratePreview($sourcePath, $outputPath) {
    $crate = [Drawing.Bitmap]::FromFile($sourcePath)
    $preview = [Drawing.Bitmap]::new(64, 16, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [Drawing.Graphics]::FromImage($preview)
    $graphics.Clear([Drawing.Color]::Transparent)
    $graphics.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
    $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    for ($x = 0; $x -lt 64; $x += 16) {
        $graphics.DrawImageUnscaled($crate, $x, 0)
    }
    $graphics.Dispose()
    $crate.Dispose()
    $preview.Save($outputPath, [Drawing.Imaging.ImageFormat]::Png)
    $preview.Dispose()
}

$sourceRoot = 'tmp/imagegen/grocery_stall'
$assetRoot = 'assets/sprites/restaurant'
$palette = @(
    (New-OpaqueColor 23 32 56),
    (New-OpaqueColor 77 43 50),
    (New-OpaqueColor 122 72 65),
    (New-OpaqueColor 173 119 87),
    (New-OpaqueColor 37 86 46),
    (New-OpaqueColor 70 130 50),
    (New-OpaqueColor 168 202 88),
    (New-OpaqueColor 165 48 48),
    (New-OpaqueColor 207 87 60),
    (New-OpaqueColor 87 114 119),
    (New-OpaqueColor 199 207 204),
    (New-OpaqueColor 235 237 233)
)

Convert-IsolatedAsset "$sourceRoot/grocery_counter_source.png" "$sourceRoot/grocery_counter.png" 96 16 ([Drawing.Rectangle]::new(1, 1, 94, 15)) $palette
Convert-IsolatedAsset "$sourceRoot/grocery_crate_source.png" "$sourceRoot/grocery_crate.png" 16 16 ([Drawing.Rectangle]::new(1, 1, 14, 14)) $palette

New-NearestPreview "$sourceRoot/grocery_counter.png" "$sourceRoot/grocery_counter_preview_8x.png" 8
New-NearestPreview "$sourceRoot/grocery_crate.png" "$sourceRoot/grocery_crate_preview_8x.png" 8
New-RepeatedCratePreview "$sourceRoot/grocery_crate.png" "$sourceRoot/grocery_crate_repeat_4x.png"
New-NearestPreview "$sourceRoot/grocery_crate_repeat_4x.png" "$sourceRoot/grocery_crate_repeat_4x_preview_8x.png" 8

Copy-Item -LiteralPath "$sourceRoot/grocery_counter.png" -Destination "$assetRoot/grocery_counter.png"
Copy-Item -LiteralPath "$sourceRoot/grocery_crate.png" -Destination "$assetRoot/grocery_crate.png"

Write-Output "$assetRoot/grocery_counter.png"
Write-Output "$assetRoot/grocery_crate.png"
