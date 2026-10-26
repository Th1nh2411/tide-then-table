Add-Type -AssemblyName System.Drawing

function New-OpaqueColor($red, $green, $blue) {
    return [Drawing.Color]::FromArgb(255, $red, $green, $blue)
}

function Find-SubjectBounds($bitmap) {
    $left = $bitmap.Width
    $top = $bitmap.Height
    $right = -1
    $bottom = -1
    $corner = $bitmap.GetPixel(0, 0)

    for ($y = 0; $y -lt $bitmap.Height; $y++) {
        for ($x = 0; $x -lt $bitmap.Width; $x++) {
            $pixel = $bitmap.GetPixel($x, $y)
            $isTransparent = $pixel.A -lt 128
            $keyDistance = [Math]::Abs($pixel.R - $corner.R) +
                [Math]::Abs($pixel.G - $corner.G) +
                [Math]::Abs($pixel.B - $corner.B)
            if (-not $isTransparent -and $keyDistance -gt 36) {
                $left = [Math]::Min($left, $x)
                $top = [Math]::Min($top, $y)
                $right = [Math]::Max($right, $x)
                $bottom = [Math]::Max($bottom, $y)
            }
        }
    }

    if ($right -lt $left -or $bottom -lt $top) {
        throw 'No beer tap subject pixels found.'
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

$sourcePath = 'tmp/imagegen/beer_tap_prop/source.png'
$outputPath = 'tmp/imagegen/beer_tap_prop/beer_tap.png'
$source = [Drawing.Bitmap]::FromFile($sourcePath)
$bounds = Find-SubjectBounds $source
$crop = $source.Clone($bounds, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
$source.Dispose()

$output = [Drawing.Bitmap]::new(16, 32, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [Drawing.Graphics]::FromImage($output)
$graphics.Clear([Drawing.Color]::Transparent)
$graphics.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
$graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::Half
$targetWidth = 14
$targetHeight = [Math]::Max(1, [Math]::Min(30, [int][Math]::Round($targetWidth * $crop.Height / $crop.Width)))
$target = [Drawing.Rectangle]::new(1, 31 - $targetHeight, $targetWidth, $targetHeight)
$graphics.DrawImage($crop, $target, 0, 0, $crop.Width, $crop.Height, [Drawing.GraphicsUnit]::Pixel)
$graphics.Dispose()
$crop.Dispose()

$palette = @(
    (New-OpaqueColor 23 32 56),
    (New-OpaqueColor 32 46 55),
    (New-OpaqueColor 57 74 80),
    (New-OpaqueColor 87 114 119),
    (New-OpaqueColor 129 151 150),
    (New-OpaqueColor 199 207 204),
    (New-OpaqueColor 235 237 233)
)

for ($y = 0; $y -lt $output.Height; $y++) {
    for ($x = 0; $x -lt $output.Width; $x++) {
        $pixel = $output.GetPixel($x, $y)
        if ($pixel.A -lt 128) {
            $output.SetPixel($x, $y, [Drawing.Color]::Transparent)
        } else {
            $output.SetPixel($x, $y, (Nearest-PaletteColor $pixel $palette))
        }
    }
}

$output.Save($outputPath, [Drawing.Imaging.ImageFormat]::Png)

# Disposable review image: place the tap on the cart's right worktop without
# changing either active asset. The taller canvas preserves the tap silhouette.
$cartPath = 'assets/sprites/restaurant/food_cart_0.png'
$previewPath = 'tmp/imagegen/beer_tap_prop/preview_on_cart.png'
if (Test-Path $cartPath) {
    $cart = [Drawing.Bitmap]::FromFile($cartPath)
    $preview = [Drawing.Bitmap]::new(64, 48, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $previewGraphics = [Drawing.Graphics]::FromImage($preview)
    $previewGraphics.Clear([Drawing.Color]::Transparent)
    $previewGraphics.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
    $previewGraphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $previewGraphics.DrawImageUnscaled($cart, 0, 16)
    $previewGraphics.DrawImageUnscaled($output, 47, 0)
    $previewGraphics.Dispose()
    $cart.Dispose()
    $preview.Save($previewPath, [Drawing.Imaging.ImageFormat]::Png)
    $preview.Dispose()
}

$output.Dispose()

Write-Output $outputPath
