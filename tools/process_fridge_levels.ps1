Add-Type -AssemblyName System.Drawing

function New-OpaqueColor($red, $green, $blue) {
    return [Drawing.Color]::FromArgb(255, $red, $green, $blue)
}

function Find-SubjectBounds($bitmap) {
    $left = $bitmap.Width
    $top = $bitmap.Height
    $right = -1
    $bottom = -1
    for ($y = 0; $y -lt $bitmap.Height; $y++) {
        for ($x = 0; $x -lt $bitmap.Width; $x++) {
            $pixel = $bitmap.GetPixel($x, $y)
            $isMagentaKey = $pixel.R -gt 230 -and $pixel.B -gt 230 -and $pixel.G -lt 40
            if ($pixel.A -ge 128 -and -not $isMagentaKey) {
                $left = [Math]::Min($left, $x)
                $top = [Math]::Min($top, $y)
                $right = [Math]::Max($right, $x)
                $bottom = [Math]::Max($bottom, $y)
            }
        }
    }
    if ($right -lt $left -or $bottom -lt $top) {
        throw 'No opaque subject pixels found.'
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

function Convert-Fridge($sourcePath, $outputPath, $targetHeight, $palette) {
    $source = [Drawing.Bitmap]::FromFile($sourcePath)
    $bounds = Find-SubjectBounds $source
    $crop = $source.Clone($bounds, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $source.Dispose()

    # Every upgrade uses the same 14 px ground footprint and bottom alignment.
    # Height differs only to communicate the physical upgrade tier.
    $output = [Drawing.Bitmap]::new(16, 32, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [Drawing.Graphics]::FromImage($output)
    $graphics.Clear([Drawing.Color]::Transparent)
    $graphics.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
    $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::Half
    $target = [Drawing.Rectangle]::new(1, 31 - $targetHeight, 14, $targetHeight)
    $graphics.DrawImage($crop, $target, 0, 0, $crop.Width, $crop.Height, [Drawing.GraphicsUnit]::Pixel)
    $graphics.Dispose()
    $crop.Dispose()

    Apply-Palette $output $palette
    $output.Save($outputPath, [Drawing.Imaging.ImageFormat]::Png)
    $output.Dispose()
}

$sourceRoot = 'tmp/imagegen/fridge_levels'
$assetRoot = 'assets/sprites/restaurant'
$outline = New-OpaqueColor 23 32 56

$foamPalette = @(
    $outline,
    (New-OpaqueColor 87 114 119),
    (New-OpaqueColor 199 207 204),
    (New-OpaqueColor 235 237 233)
)
$coolerPalette = @(
    $outline,
    (New-OpaqueColor 37 58 94),
    (New-OpaqueColor 60 94 139),
    (New-OpaqueColor 79 143 186),
    (New-OpaqueColor 115 190 211)
)
$freezerPalette = @(
    $outline,
    (New-OpaqueColor 57 74 80),
    (New-OpaqueColor 87 114 119),
    (New-OpaqueColor 129 151 150),
    (New-OpaqueColor 199 207 204),
    (New-OpaqueColor 235 237 233)
)

Convert-Fridge "$sourceRoot/fridge_0_source.png" "$sourceRoot/fridge_0.png" 15 $foamPalette
Convert-Fridge "$sourceRoot/fridge_1_source.png" "$sourceRoot/fridge_1.png" 23 $coolerPalette
Convert-Fridge "$sourceRoot/fridge_2_source.png" "$sourceRoot/fridge_2.png" 29 $freezerPalette

Copy-Item -LiteralPath "$sourceRoot/fridge_0.png" -Destination "$assetRoot/fridge_0.png"
Copy-Item -LiteralPath "$sourceRoot/fridge_1.png" -Destination "$assetRoot/fridge_1.png"
Copy-Item -LiteralPath "$sourceRoot/fridge_2.png" -Destination "$assetRoot/fridge_2.png"

# Native-scale comparison sheet: 4 px padding and 4 px gaps, no scaling.
$contact = [Drawing.Bitmap]::new(64, 40, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
$contactGraphics = [Drawing.Graphics]::FromImage($contact)
$contactGraphics.Clear((New-OpaqueColor 9 10 20))
for ($level = 0; $level -le 2; $level++) {
    $sprite = [Drawing.Bitmap]::FromFile("$sourceRoot/fridge_$level.png")
    $contactGraphics.DrawImageUnscaled($sprite, 4 + ($level * 20), 4)
    $sprite.Dispose()
}
$contactGraphics.Dispose()
$contact.Save("$sourceRoot/contact_sheet.png", [Drawing.Imaging.ImageFormat]::Png)
$contact.Dispose()

Write-Output "$assetRoot/fridge_0.png"
Write-Output "$assetRoot/fridge_1.png"
Write-Output "$assetRoot/fridge_2.png"
Write-Output "$sourceRoot/contact_sheet.png"
