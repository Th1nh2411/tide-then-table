Add-Type -AssemblyName System.Drawing

function Color($r, $g, $b) { [Drawing.Color]::FromArgb(255, $r, $g, $b) }

function Convert-Dish($source, $destination, $palette) {
    $image = [Drawing.Bitmap]::FromFile($source)
    $left = $image.Width
    $top = $image.Height
    $right = -1
    $bottom = -1
    for ($y = 0; $y -lt $image.Height; $y += 2) {
        for ($x = 0; $x -lt $image.Width; $x += 2) {
            if ($image.GetPixel($x, $y).A -gt 32) {
                if ($x -lt $left) { $left = $x }
                if ($x -gt $right) { $right = $x }
                if ($y -lt $top) { $top = $y }
                if ($y -gt $bottom) { $bottom = $y }
            }
        }
    }
    $bounds = [Drawing.Rectangle]::new($left, $top, $right - $left + 1, $bottom - $top + 1)
    $crop = $image.Clone($bounds, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $output = [Drawing.Bitmap]::new(64, 64)
    $graphics = [Drawing.Graphics]::FromImage($output)
    $graphics.Clear([Drawing.Color]::Transparent)
    $graphics.InterpolationMode = 'NearestNeighbor'
    $graphics.PixelOffsetMode = 'Half'
    $scale = [Math]::Min(56 / $crop.Width, 56 / $crop.Height)
    $width = [Math]::Max(1, [int]($crop.Width * $scale))
    $height = [Math]::Max(1, [int]($crop.Height * $scale))
    $graphics.DrawImage($crop, [int]((64 - $width) / 2), [int]((64 - $height) / 2), $width, $height)
    $graphics.Dispose()

    for ($y = 0; $y -lt 64; $y++) {
        for ($x = 0; $x -lt 64; $x++) {
            $pixel = $output.GetPixel($x, $y)
            if ($pixel.A -lt 100) {
                $output.SetPixel($x, $y, [Drawing.Color]::Transparent)
                continue
            }
            $best = $palette[0]
            $distanceBest = [int]::MaxValue
            foreach ($candidate in $palette) {
                $distance = ($pixel.R - $candidate.R) * ($pixel.R - $candidate.R) +
                    ($pixel.G - $candidate.G) * ($pixel.G - $candidate.G) +
                    ($pixel.B - $candidate.B) * ($pixel.B - $candidate.B)
                if ($distance -lt $distanceBest) {
                    $distanceBest = $distance
                    $best = $candidate
                }
            }
            $output.SetPixel($x, $y, $best)
        }
    }
    $output.Save($destination, [Drawing.Imaging.ImageFormat]::Png)
    $output.Dispose()
    $crop.Dispose()
    $image.Dispose()
}

$navy = Color 5 25 48
$cream = Color 255 241 190
$orange = Color 235 91 39
$coral = Color 180 49 35
$green = Color 54 119 72
$brown = Color 105 58 36
$amber = Color 210 137 52
$teal = Color 54 120 116
$blue = Color 61 99 126
$lavender = Color 162 146 175
$pale = Color 224 207 166

Get-ChildItem 'tmp/imagegen/dishes_redraw/*_source.png' | ForEach-Object {
    $name = $_.BaseName -replace '_source$', ''
    if ($name -like 'tom_*') { $palette = @($navy, $cream, $orange, $coral, $green, $amber) }
    elseif ($name -like 'muc_*') { $palette = @($navy, $cream, $lavender, $pale, $green, $brown) }
    elseif ($name -like 'oc_huong_*') { $palette = @($navy, $cream, $brown, $amber, $green, $pale) }
    elseif ($name -like 'cua_*') { $palette = @($navy, $cream, $orange, $coral, $brown, $green) }
    elseif ($name -like '*ca_thu*') { $palette = @($navy, $cream, $blue, $teal, $orange, $green) }
    elseif ($name -like '*ca_mu*') { $palette = @($navy, $cream, $teal, $brown, $amber, $green) }
    elseif ($name -eq 'rau_muong_xao_toi') { $palette = @($navy, $cream, $green, (Color 28 78 52), $amber, $pale) }
    else { $palette = @($navy, $cream, $amber, $brown, $blue, $coral) }
    Convert-Dish $_.FullName "tmp/imagegen/dishes_redraw/${name}_final.png" $palette
}
