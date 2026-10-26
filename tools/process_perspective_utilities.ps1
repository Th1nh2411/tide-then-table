Add-Type -AssemblyName System.Drawing

function New-Color($hex) {
    $h = $hex.TrimStart('#')
    return [Drawing.Color]::FromArgb(255,
        [Convert]::ToInt32($h.Substring(0, 2), 16),
        [Convert]::ToInt32($h.Substring(2, 2), 16),
        [Convert]::ToInt32($h.Substring(4, 2), 16))
}

function Get-SubjectBounds($bitmap) {
    $left = $bitmap.Width; $top = $bitmap.Height; $right = -1; $bottom = -1
    $corner = $bitmap.GetPixel(0, 0)
    for ($y = 0; $y -lt $bitmap.Height; $y++) {
        for ($x = 0; $x -lt $bitmap.Width; $x++) {
            $p = $bitmap.GetPixel($x, $y)
            $cornerDistance = [Math]::Abs($p.R - $corner.R) + [Math]::Abs($p.G - $corner.G) + [Math]::Abs($p.B - $corner.B)
            if ($p.A -ge 128 -and ($corner.A -lt 128 -or $cornerDistance -gt 42)) {
                $left = [Math]::Min($left, $x); $top = [Math]::Min($top, $y)
                $right = [Math]::Max($right, $x); $bottom = [Math]::Max($bottom, $y)
            }
        }
    }
    if ($right -lt $left) { throw 'No subject pixels found.' }
    return [Drawing.Rectangle]::new($left, $top, $right - $left + 1, $bottom - $top + 1)
}

function Get-NearestColor($pixel, $palette) {
    $best = $palette[0]; $distance = [double]::MaxValue
    foreach ($c in $palette) {
        $d = [Math]::Pow($pixel.R - $c.R, 2) + [Math]::Pow($pixel.G - $c.G, 2) + [Math]::Pow($pixel.B - $c.B, 2)
        if ($d -lt $distance) { $distance = $d; $best = $c }
    }
    return $best
}

function Convert-Asset($sourcePath, $outputPath, $width, $height, $targetRect, $palette, $shadowLeft, $shadowRight) {
    $source = [Drawing.Bitmap]::FromFile($sourcePath)
    $bounds = Get-SubjectBounds $source
    $crop = $source.Clone($bounds, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $source.Dispose()
    $output = [Drawing.Bitmap]::new($width, $height, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [Drawing.Graphics]::FromImage($output)
    $g.Clear([Drawing.Color]::Transparent)
    $g.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
    $g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $g.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::Half
    $g.DrawImage($crop, $targetRect, 0, 0, $crop.Width, $crop.Height, [Drawing.GraphicsUnit]::Pixel)
    $g.Dispose(); $crop.Dispose()

    for ($y = 0; $y -lt $height; $y++) {
        for ($x = 0; $x -lt $width; $x++) {
            $p = $output.GetPixel($x, $y)
            if ($p.A -lt 128) { $output.SetPixel($x, $y, [Drawing.Color]::Transparent) }
            else { $output.SetPixel($x, $y, (Get-NearestColor $p $palette)) }
        }
    }

    # Explicit one-pixel hard contact shadow, attached to the grounded baseline.
    $shadow = New-Color '202e37'
    for ($x = $shadowLeft; $x -le $shadowRight; $x++) { $output.SetPixel($x, $height - 2, $shadow) }
    $output.SetPixel(0, 0, [Drawing.Color]::Transparent)
    $output.SetPixel($width - 1, 0, [Drawing.Color]::Transparent)
    $output.SetPixel(0, $height - 1, [Drawing.Color]::Transparent)
    $output.SetPixel($width - 1, $height - 1, [Drawing.Color]::Transparent)
    $output.Save($outputPath, [Drawing.Imaging.ImageFormat]::Png)
    $output.Dispose()
}

$root = 'tmp/imagegen/perspective_utilities'
$assetRoot = 'assets/sprites/restaurant'
$foamPalette = @('151d28','202e37','577277','c7cfcc','ebede9') | ForEach-Object { New-Color $_ }
$bluePalette = @('151d28','202e37','253a5e','3c5e8b','4f8fba','73bed3') | ForEach-Object { New-Color $_ }
$metalPalette = @('151d28','202e37','394a50','577277','819796','c7cfcc','ebede9') | ForEach-Object { New-Color $_ }
$groceryPalette = @('151d28','202e37','4d2b32','7a4841','ad7757','be772b','de9e41','25562e','468232','a8ca58','a53030','cf573c') | ForEach-Object { New-Color $_ }

# Equal 14 px footprint and baseline for all fridge tiers.
Convert-Asset "$root/fridge_0_source.png" "$root/fridge_0.png" 16 32 ([Drawing.Rectangle]::new(1, 15, 14, 15)) $foamPalette 2 13
Convert-Asset "$root/fridge_1_source.png" "$root/fridge_1.png" 16 32 ([Drawing.Rectangle]::new(1, 7, 14, 23)) $bluePalette 2 13
Convert-Asset "$root/fridge_2_source.png" "$root/fridge_2.png" 16 32 ([Drawing.Rectangle]::new(1, 1, 14, 29)) $metalPalette 2 13
Convert-Asset "$root/bin_source.png" "$root/bin.png" 16 16 ([Drawing.Rectangle]::new(2, 0, 12, 14)) $bluePalette 3 12
Convert-Asset "$root/beer_tap_source.png" "$root/beer_tap.png" 16 32 ([Drawing.Rectangle]::new(2, 0, 12, 30)) $metalPalette 3 12
Convert-Asset "$root/grocery_counter_source.png" "$root/grocery_counter.png" 96 16 ([Drawing.Rectangle]::new(1, 0, 94, 14)) $groceryPalette 2 93
Convert-Asset "$root/grocery_crate_source.png" "$root/grocery_crate.png" 16 16 ([Drawing.Rectangle]::new(1, 0, 14, 14)) $groceryPalette 2 13

foreach ($name in @('fridge_0','fridge_1','fridge_2','bin','beer_tap','grocery_counter','grocery_crate')) {
    Copy-Item -LiteralPath "$root/$name.png" -Destination "$assetRoot/$name.png"
}

# Native contact sheets, no interpolation.
$sheet = [Drawing.Bitmap]::new(112, 40, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
$sg = [Drawing.Graphics]::FromImage($sheet); $sg.Clear((New-Color '090a14'))
$x = 4
foreach ($name in @('fridge_0','fridge_1','fridge_2','beer_tap','bin','grocery_crate')) {
    $sprite = [Drawing.Bitmap]::FromFile("$root/$name.png")
    $sg.DrawImageUnscaled($sprite, $x, 4)
    $x += $sprite.Width + 3
    $sprite.Dispose()
}
$sg.Dispose(); $sheet.Save("$root/contact_sheet.png", [Drawing.Imaging.ImageFormat]::Png); $sheet.Dispose()

$wide = [Drawing.Bitmap]::new(128, 24, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
$wg = [Drawing.Graphics]::FromImage($wide); $wg.Clear((New-Color '090a14'))
$counter = [Drawing.Bitmap]::FromFile("$root/grocery_counter.png")
$crate = [Drawing.Bitmap]::FromFile("$root/grocery_crate.png")
$wg.DrawImageUnscaled($counter, 4, 4); $wg.DrawImageUnscaled($crate, 104, 4)
$wg.Dispose(); $counter.Dispose(); $crate.Dispose()
$wide.Save("$root/grocery_contact_sheet.png", [Drawing.Imaging.ImageFormat]::Png); $wide.Dispose()

# Review-only composite; active cart is never modified here.
$cartPath = "$assetRoot/food_cart_0.png"
if (Test-Path $cartPath) {
    $cart = [Drawing.Bitmap]::FromFile($cartPath)
    $tap = [Drawing.Bitmap]::FromFile("$root/beer_tap.png")
    $preview = [Drawing.Bitmap]::new(64, 48, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $pg = [Drawing.Graphics]::FromImage($preview)
    $pg.Clear([Drawing.Color]::Transparent)
    $pg.DrawImageUnscaled($cart, 0, 16)
    $pg.DrawImageUnscaled($tap, 47, 0)
    $pg.Dispose(); $cart.Dispose(); $tap.Dispose()
    $preview.Save("$root/beer_tap_on_cart.png", [Drawing.Imaging.ImageFormat]::Png)
    $preview.Dispose()
}

Write-Output 'Processed perspective utilities.'
