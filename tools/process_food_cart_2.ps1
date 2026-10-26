param(
    [string]$OutputPath = "assets/sprites/restaurant/food_cart_2.png"
)

Add-Type -AssemblyName System.Drawing

$width = 64
$height = 32
$bmp = [System.Drawing.Bitmap]::new($width, $height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)

$colors = @{
    Outline = [System.Drawing.ColorTranslator]::FromHtml('#151d28')
    Deep = [System.Drawing.ColorTranslator]::FromHtml('#202e37')
    SteelDark = [System.Drawing.ColorTranslator]::FromHtml('#394a50')
    Steel = [System.Drawing.ColorTranslator]::FromHtml('#577277')
    SteelLight = [System.Drawing.ColorTranslator]::FromHtml('#819796')
    Highlight = [System.Drawing.ColorTranslator]::FromHtml('#c7cfcc')
    Glass = [System.Drawing.ColorTranslator]::FromHtml('#73bed3')
    GlassLight = [System.Drawing.ColorTranslator]::FromHtml('#a4dddb')
    Red = [System.Drawing.ColorTranslator]::FromHtml('#a53030')
    Flame = [System.Drawing.ColorTranslator]::FromHtml('#de9e41')
}

function Rect([int]$x, [int]$y, [int]$w, [int]$h, [System.Drawing.Color]$color) {
    for ($yy = $y; $yy -lt $y + $h; $yy++) {
        for ($xx = $x; $xx -lt $x + $w; $xx++) {
            if ($xx -ge 0 -and $xx -lt $width -and $yy -ge 0 -and $yy -lt $height) {
                $bmp.SetPixel($xx, $yy, $color)
            }
        }
    }
}

# Compact contact shadow directly below the wheels/base.
Rect 4 29 56 2 $colors.Outline

# Lower cabinet and frame.
Rect 3 15 58 13 $colors.Outline
Rect 5 17 54 9 $colors.SteelDark
Rect 6 18 52 7 $colors.Steel
Rect 6 18 52 2 $colors.SteelLight
Rect 7 20 50 4 $colors.Deep
Rect 8 20 23 4 $colors.SteelDark
Rect 33 20 23 4 $colors.SteelDark
Rect 9 21 21 2 $colors.Steel
Rect 34 21 21 2 $colors.Steel
Rect 31 19 2 6 $colors.Outline
Rect 4 25 56 3 $colors.Outline
Rect 6 25 52 1 $colors.Highlight

# Legs and wheels.
Rect 5 27 4 3 $colors.Outline
Rect 55 27 4 3 $colors.Outline
Rect 4 28 7 3 $colors.Outline
Rect 53 28 7 3 $colors.Outline
Rect 6 28 3 2 $colors.SteelLight
Rect 55 28 3 2 $colors.SteelLight

# Orthographic worktop: horizontal/vertical edges only.
Rect 1 12 62 5 $colors.Outline
Rect 3 12 58 2 $colors.Highlight
Rect 3 14 58 2 $colors.SteelLight
Rect 5 15 54 1 $colors.Steel

# Modest glass display case on the left half.
Rect 3 3 29 10 $colors.Outline
Rect 5 5 25 6 $colors.Glass
Rect 6 5 23 2 $colors.GlassLight
Rect 6 8 23 2 $colors.Steel
Rect 3 2 29 2 $colors.Outline
Rect 5 2 25 1 $colors.Highlight
Rect 3 3 2 10 $colors.SteelLight
Rect 30 3 2 10 $colors.SteelLight
Rect 5 10 25 2 $colors.Outline

# Two simple gas burners integrated into the right worktop.
foreach ($x in @(36, 50)) {
    Rect ($x - 3) 5 12 7 $colors.Outline
    Rect ($x - 1) 6 8 4 $colors.SteelDark
    Rect $x 7 6 2 $colors.Deep
    Rect ($x + 1) 7 4 1 $colors.Flame
    Rect ($x - 2) 10 10 1 $colors.SteelLight
}

# Two controls: enough to identify the top upgrade without visual noise.
Rect 38 14 3 2 $colors.Outline
Rect 39 14 1 1 $colors.Red
Rect 52 14 3 2 $colors.Outline
Rect 53 14 1 1 $colors.Red

$dir = Split-Path -Parent $OutputPath
if ($dir) { New-Item -ItemType Directory -Force $dir | Out-Null }
$bmp.Save((Join-Path (Get-Location) $OutputPath), [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
