Add-Type -AssemblyName System.Drawing

function C($r, $g, $b) { [Drawing.Color]::FromArgb(255, $r, $g, $b) }

function Set-NearestPalette($bitmap, $palette) {
    for ($y = 0; $y -lt $bitmap.Height; $y++) {
        for ($x = 0; $x -lt $bitmap.Width; $x++) {
            $pixel = $bitmap.GetPixel($x, $y)
            if ($pixel.A -lt 100) {
                $bitmap.SetPixel($x, $y, [Drawing.Color]::Transparent)
                continue
            }
            $best = $palette[0]
            $bestDistance = [int]::MaxValue
            foreach ($candidate in $palette) {
                $distance = ($pixel.R - $candidate.R) * ($pixel.R - $candidate.R) +
                    ($pixel.G - $candidate.G) * ($pixel.G - $candidate.G) +
                    ($pixel.B - $candidate.B) * ($pixel.B - $candidate.B)
                if ($distance -lt $bestDistance) {
                    $bestDistance = $distance
                    $best = $candidate
                }
            }
            $bitmap.SetPixel($x, $y, $best)
        }
    }
}

function Alpha-Bounds($bitmap, $region) {
    $startX = [Math]::Max(0, [int]$region.Left)
    $startY = [Math]::Max(0, [int]$region.Top)
    $endX = [Math]::Min($bitmap.Width, [int]$region.Right)
    $endY = [Math]::Min($bitmap.Height, [int]$region.Bottom)
    $left = $endX
    $top = $endY
    $right = $startX - 1
    $bottom = $startY - 1
    for ($y = $startY; $y -lt $endY; $y += 2) {
        for ($x = $startX; $x -lt $endX; $x += 2) {
            if ($bitmap.GetPixel($x, $y).A -gt 32) {
                if ($x -lt $left) { $left = $x }
                if ($x -gt $right) { $right = $x }
                if ($y -lt $top) { $top = $y }
                if ($y -gt $bottom) { $bottom = $y }
            }
        }
    }
    if ($right -lt $left -or $bottom -lt $top) {
        return [Drawing.Rectangle]::new($startX, $startY, $endX - $startX, $endY - $startY)
    }
    return [Drawing.Rectangle]::new($left, $top, $right - $left + 1, $bottom - $top + 1)
}

$guestSource = [Drawing.Bitmap]::FromFile('tmp/imagegen/guest_beer/guest_source.png')
$guest = [Drawing.Bitmap]::new(64, 128)
$guestGraphics = [Drawing.Graphics]::FromImage($guest)
$guestGraphics.Clear([Drawing.Color]::Transparent)
$guestGraphics.InterpolationMode = 'NearestNeighbor'
$guestGraphics.PixelOffsetMode = 'Half'
$gridLeft = 180
$cellWidth = 270
$cellHeight = [int]($guestSource.Height / 4)

for ($row = 0; $row -lt 4; $row++) {
    for ($column = 0; $column -lt 4; $column++) {
        $cell = [Drawing.Rectangle]::new($gridLeft + $column * $cellWidth, $row * $cellHeight, $cellWidth, $cellHeight)
        $bounds = Alpha-Bounds $guestSource $cell
        $crop = $guestSource.Clone($bounds, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $targetWidth = 14
        $targetHeight = 30
        $scale = [Math]::Min($targetWidth / $crop.Width, $targetHeight / $crop.Height)
        $width = [Math]::Max(1, [int]($crop.Width * $scale))
        $height = [Math]::Max(1, [int]($crop.Height * $scale))
        $x = $column * 16 + [int]((16 - $width) / 2)
        $y = $row * 32 + 31 - $height
        $guestGraphics.DrawImage($crop, $x, $y, $width, $height)
        $crop.Dispose()
    }
}
$guestGraphics.Dispose()
$guestSource.Dispose()
$guestPalette = @(
    (C 5 25 48), (C 22 27 40), (C 48 54 70),
    (C 239 170 119), (C 255 211 157),
    (C 42 82 126), (C 71 119 166),
    (C 27 39 60), (C 55 64 82), (C 126 76 48)
)
Set-NearestPalette $guest $guestPalette
$guest.Save('tmp/imagegen/guest_beer/guest_final.png', [Drawing.Imaging.ImageFormat]::Png)
$guest.Dispose()

$beerSource = [Drawing.Bitmap]::FromFile('tmp/imagegen/guest_beer/beer_source.png')
$beerBounds = Alpha-Bounds $beerSource ([Drawing.Rectangle]::new(0, 0, $beerSource.Width, $beerSource.Height))
$beerCrop = $beerSource.Clone($beerBounds, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
$beer = [Drawing.Bitmap]::new(64, 64)
$beerGraphics = [Drawing.Graphics]::FromImage($beer)
$beerGraphics.Clear([Drawing.Color]::Transparent)
$beerGraphics.InterpolationMode = 'NearestNeighbor'
$beerGraphics.PixelOffsetMode = 'Half'
$beerScale = [Math]::Min(56 / $beerCrop.Width, 56 / $beerCrop.Height)
$beerWidth = [Math]::Max(1, [int]($beerCrop.Width * $beerScale))
$beerHeight = [Math]::Max(1, [int]($beerCrop.Height * $beerScale))
$beerGraphics.DrawImage($beerCrop, [int]((64 - $beerWidth) / 2), [int]((64 - $beerHeight) / 2), $beerWidth, $beerHeight)
$beerGraphics.Dispose()
$beerCrop.Dispose()
$beerSource.Dispose()
$beerPalette = @(
    (C 5 25 48), (C 255 241 190), (C 246 185 62),
    (C 235 126 17), (C 255 214 102), (C 185 207 216)
)
Set-NearestPalette $beer $beerPalette
$beer.Save('tmp/imagegen/guest_beer/beer_final.png', [Drawing.Imaging.ImageFormat]::Png)
$beer.Dispose()
