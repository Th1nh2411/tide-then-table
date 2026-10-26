param(
    [string]$OutputRoot = (Join-Path $PSScriptRoot "..\assets\sprites\restaurant")
)

Add-Type -AssemblyName System.Drawing
$OutputRoot = [IO.Path]::GetFullPath($OutputRoot)
[IO.Directory]::CreateDirectory($OutputRoot) | Out-Null

function New-Sprite([int]$Width, [int]$Height) {
    $bitmap = [Drawing.Bitmap]::new($Width, $Height, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $bitmap.SetResolution(96, 96)
    return $bitmap
}

function Color([string]$hex) {
    return [Drawing.ColorTranslator]::FromHtml("#$hex")
}

function Pixel([Drawing.Bitmap]$bitmap, [int]$x, [int]$y, [string]$hex) {
    if ($x -ge 0 -and $x -lt $bitmap.Width -and $y -ge 0 -and $y -lt $bitmap.Height) {
        $bitmap.SetPixel($x, $y, (Color $hex))
    }
}

function Fill([Drawing.Bitmap]$bitmap, [int]$x, [int]$y, [int]$w, [int]$h, [string]$hex) {
    for ($py = $y; $py -lt $y + $h; $py++) {
        for ($px = $x; $px -lt $x + $w; $px++) { Pixel $bitmap $px $py $hex }
    }
}

# Hand-finished at native resolution from the generated plant source: five
# broad leaf clusters, a small terracotta pot, and a one-pixel contact shadow.
$plant = New-Sprite 16 16
Fill $plant 5 14 7 1 "151d28"
Fill $plant 6 10 6 4 "7a4841"
Fill $plant 7 11 4 3 "ad7757"
Fill $plant 6 10 6 1 "d7b594"
Fill $plant 7 5 2 6 "25562e"
Fill $plant 4 6 3 2 "25562e"
Fill $plant 9 6 3 2 "25562e"
Fill $plant 3 4 3 3 "468232"
Fill $plant 10 3 3 4 "468232"
Fill $plant 7 2 3 4 "468232"
Pixel $plant 4 4 "a8ca58"
Pixel $plant 8 2 "a8ca58"
Pixel $plant 11 3 "a8ca58"
$plant.Save((Join-Path $OutputRoot "plant.png"), [Drawing.Imaging.ImageFormat]::Png)
$plant.Dispose()

# Seamless 16x8 light-string tile. Cable connects exactly at x=0/x=15; the
# tile remains deliberately sparse so repeating it does not become visual noise.
$lights = New-Sprite 16 8
for ($x = 0; $x -lt 16; $x++) {
    $y = if ($x -in 0,1,14,15) { 1 } elseif ($x -in 2,3,12,13) { 2 } else { 3 }
    Pixel $lights $x $y "151d28"
}
Fill $lights 7 3 2 2 "602c2c"
Fill $lights 6 5 4 2 "de9e41"
Fill $lights 7 5 2 2 "f2d98a"
$lights.Save((Join-Path $OutputRoot "string_lights.png"), [Drawing.Imaging.ImageFormat]::Png)
$lights.Dispose()

Write-Output "Wrote plant.png (16x16) and string_lights.png (16x8)"
