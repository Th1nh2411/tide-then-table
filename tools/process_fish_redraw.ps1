Add-Type -AssemblyName System.Drawing

function Convert-Sprite {
    param($Source, $Destination, $Width, $Height, $Palette)

    $image = [Drawing.Bitmap]::FromFile($Source)
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
    $output = [Drawing.Bitmap]::new($Width, $Height)
    $graphics = [Drawing.Graphics]::FromImage($output)
    $graphics.Clear([Drawing.Color]::Transparent)
    $graphics.InterpolationMode = 'NearestNeighbor'
    $graphics.PixelOffsetMode = 'Half'
    $scale = [Math]::Min(($Width - 8) / $crop.Width, ($Height - 8) / $crop.Height)
    $drawWidth = [Math]::Max(1, [int]($crop.Width * $scale))
    $drawHeight = [Math]::Max(1, [int]($crop.Height * $scale))
    $graphics.DrawImage($crop, [int](($Width - $drawWidth) / 2), [int](($Height - $drawHeight) / 2), $drawWidth, $drawHeight)
    $graphics.Dispose()

    for ($y = 0; $y -lt $Height; $y++) {
        for ($x = 0; $x -lt $Width; $x++) {
            $pixel = $output.GetPixel($x, $y)
            if ($pixel.A -lt 100) {
                $output.SetPixel($x, $y, [Drawing.Color]::Transparent)
                continue
            }
            $best = $Palette[0]
            $bestDistance = [int]::MaxValue
            foreach ($color in $Palette) {
                $distance = ($pixel.R - $color.R) * ($pixel.R - $color.R) +
                    ($pixel.G - $color.G) * ($pixel.G - $color.G) +
                    ($pixel.B - $color.B) * ($pixel.B - $color.B)
                if ($distance -lt $bestDistance) {
                    $bestDistance = $distance
                    $best = $color
                }
            }
            $output.SetPixel($x, $y, $best)
        }
    }

    $output.Save($Destination, [Drawing.Imaging.ImageFormat]::Png)
    $output.Dispose()
    $crop.Dispose()
    $image.Dispose()
}

$navy = [Drawing.Color]::FromArgb(255, 5, 25, 48)
$cream = [Drawing.Color]::FromArgb(255, 255, 241, 190)

Convert-Sprite 'tmp/imagegen/fish_redraw/ca_thu_source.png' 'tmp/imagegen/fish_redraw/ca_thu_final.png' 240 80 @(
    $navy,
    [Drawing.Color]::FromArgb(255, 42, 76, 102),
    [Drawing.Color]::FromArgb(255, 83, 135, 146),
    $cream,
    [Drawing.Color]::FromArgb(255, 225, 152, 62)
)
Convert-Sprite 'tmp/imagegen/fish_redraw/cua_source.png' 'tmp/imagegen/fish_redraw/cua_final.png' 160 160 @(
    $navy,
    [Drawing.Color]::FromArgb(255, 151, 46, 35),
    [Drawing.Color]::FromArgb(255, 223, 83, 43),
    [Drawing.Color]::FromArgb(255, 244, 139, 61),
    $cream
)
Convert-Sprite 'tmp/imagegen/fish_redraw/ca_mu_source.png' 'tmp/imagegen/fish_redraw/ca_mu_final.png' 240 160 @(
    $navy,
    [Drawing.Color]::FromArgb(255, 25, 67, 67),
    [Drawing.Color]::FromArgb(255, 53, 119, 111),
    [Drawing.Color]::FromArgb(255, 111, 158, 134),
    $cream
)
