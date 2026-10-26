Add-Type -AssemblyName System.Drawing

$sourcePath = 'assets/sprites/characters/guest.png'
$outputDirectory = 'assets/sprites/characters'
$source = [Drawing.Bitmap]::FromFile($sourcePath)

function New-SeatedSheet([int[]] $frames) {
    $sheet = [Drawing.Bitmap]::new(64, 32, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [Drawing.Graphics]::FromImage($sheet)
    $graphics.Clear([Drawing.Color]::Transparent)
    $graphics.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
    for ($column = 0; $column -lt 4; $column++) {
        $sourceRect = [Drawing.Rectangle]::new($frames[$column] * 16, 96, 16, 32)
        $targetRect = [Drawing.Rectangle]::new($column * 16, 0, 16, 32)
        $graphics.DrawImage($source, $targetRect, $sourceRect, [Drawing.GraphicsUnit]::Pixel)
    }
    $graphics.Dispose()
    return $sheet
}

function Set-Pixel($bitmap, [int] $frame, [int] $x, [int] $y, $color) {
    $bitmap.SetPixel($frame * 16 + $x, $y, $color)
}

$outline = [Drawing.Color]::FromArgb(255, 5, 25, 48)
$ceramic = [Drawing.Color]::FromArgb(255, 255, 211, 157)
$ceramicShade = [Drawing.Color]::FromArgb(255, 239, 170, 119)
$chopstick = [Drawing.Color]::FromArgb(255, 126, 76, 48)

# Waiting uses the approved seated silhouette, but separates both hands onto
# the knees. Keeping the lap centre dark prevents the pose reading as a bowl.
$wait = New-SeatedSheet @(0, 0, 3, 0)
$shirtDark = [Drawing.Color]::FromArgb(255, 27, 39, 60)
$skin = [Drawing.Color]::FromArgb(255, 239, 170, 119)
foreach ($frame in 0..3) {
    foreach ($y in 20..22) {
        foreach ($x in 6..10) { Set-Pixel $wait $frame $x $y $shirtDark }
    }
    Set-Pixel $wait $frame 4 20 $skin
    Set-Pixel $wait $frame 5 20 $skin
    Set-Pixel $wait $frame 4 21 $skin
    Set-Pixel $wait $frame 11 20 $skin
    Set-Pixel $wait $frame 12 20 $skin
    Set-Pixel $wait $frame 12 21 $skin
}
$wait.Save((Join-Path $outputDirectory 'guest_wait.png'), [Drawing.Imaging.ImageFormat]::Png)
$wait.Dispose()

# Eating keeps the approved seated silhouette, then adds one tiny bowl and a
# two-pixel-wide chopstick gesture using colors already present in guest.png.
$eat = New-SeatedSheet @(0, 1, 2, 3)

# Frames 0 and 3: bowl resting in the lap.
foreach ($frame in @(0, 3)) {
    foreach ($x in 5..10) { Set-Pixel $eat $frame $x 20 $outline }
    foreach ($x in 6..9) { Set-Pixel $eat $frame $x 21 $ceramic }
    foreach ($x in 7..8) { Set-Pixel $eat $frame $x 22 $ceramicShade }
    Set-Pixel $eat $frame 10 18 $chopstick
    Set-Pixel $eat $frame 11 17 $chopstick
    Set-Pixel $eat $frame 11 18 $chopstick
}

# Frame 1: chopsticks lift from the low bowl toward the mouth.
foreach ($x in 5..10) { Set-Pixel $eat 1 $x 20 $outline }
foreach ($x in 6..9) { Set-Pixel $eat 1 $x 21 $ceramic }
foreach ($x in 7..8) { Set-Pixel $eat 1 $x 22 $ceramicShade }
Set-Pixel $eat 1 9 18 $chopstick
Set-Pixel $eat 1 10 17 $chopstick
Set-Pixel $eat 1 10 16 $chopstick
Set-Pixel $eat 1 11 15 $chopstick

# Frame 2: bowl reaches the mouth; the dark rim keeps it separate from skin.
foreach ($x in 6..10) { Set-Pixel $eat 2 $x 17 $outline }
foreach ($x in 7..9) { Set-Pixel $eat 2 $x 18 $ceramic }
foreach ($x in 7..9) { Set-Pixel $eat 2 $x 19 $ceramicShade }
Set-Pixel $eat 2 10 15 $chopstick
Set-Pixel $eat 2 11 14 $chopstick
Set-Pixel $eat 2 11 15 $chopstick

$eat.Save((Join-Path $outputDirectory 'guest_eat.png'), [Drawing.Imaging.ImageFormat]::Png)
$eat.Dispose()
$source.Dispose()

Write-Output 'assets/sprites/characters/guest_wait.png'
Write-Output 'assets/sprites/characters/guest_eat.png'
