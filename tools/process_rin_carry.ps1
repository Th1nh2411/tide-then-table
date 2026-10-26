Add-Type -AssemblyName System.Drawing

$sourcePath = 'assets/sprites/characters/rin.png'
$outputPath = 'assets/sprites/characters/rin_carry.png'
$source = [Drawing.Bitmap]::FromFile((Resolve-Path $sourcePath))
$output = $source.Clone([Drawing.Rectangle]::new(0, 0, $source.Width, $source.Height),
    [Drawing.Imaging.PixelFormat]::Format32bppArgb)
$source.Dispose()

function Ink([int]$frame, [int]$row, [int]$x, [int]$y, [string]$hex) {
    $color = [Drawing.ColorTranslator]::FromHtml("#$hex")
    $output.SetPixel($frame * 16 + $x, $row * 32 + $y, $color)
}

# Front row: forearms turn inward and stop either side of the centered plate.
foreach ($frame in 0..3) {
    Ink $frame 0 4 17 '151D28'; Ink $frame 0 11 17 '151D28'
    Ink $frame 0 4 18 'AD7757'; Ink $frame 0 5 18 'C09473'; Ink $frame 0 6 18 'D7B594'
    Ink $frame 0 9 18 'D7B594'; Ink $frame 0 10 18 'C09473'; Ink $frame 0 11 18 'AD7757'
    Ink $frame 0 5 19 'AD7757'; Ink $frame 0 6 19 'C09473'
    Ink $frame 0 9 19 'C09473'; Ink $frame 0 10 19 'AD7757'
}

# Back row: only shoulder/forearm hints remain visible; the plate is drawn
# first by code and is therefore naturally hidden by Rin's torso.
foreach ($frame in 0..3) {
    Ink $frame 1 4 17 '394A50'; Ink $frame 1 5 18 '577277'
    Ink $frame 1 11 17 '394A50'; Ink $frame 1 10 18 '577277'
}

# Left row (right is mirrored in game): one compact forearm reaches toward
# the plate in front of the body without changing the walk-cycle baseline.
foreach ($frame in 0..3) {
    Ink $frame 2 3 17 '151D28'; Ink $frame 2 4 17 'AD7757'
    Ink $frame 2 2 18 '151D28'; Ink $frame 2 3 18 'C09473'; Ink $frame 2 4 18 'D7B594'
    Ink $frame 2 2 19 'AD7757'; Ink $frame 2 3 19 'C09473'
}

$output.Save($outputPath, [Drawing.Imaging.ImageFormat]::Png)
$output.Dispose()
Write-Output $outputPath
