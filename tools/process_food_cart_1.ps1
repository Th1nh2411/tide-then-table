Add-Type -AssemblyName System.Drawing

function C([string]$hex) {
    $h = $hex.TrimStart('#')
    [Drawing.Color]::FromArgb(255,
        [Convert]::ToInt32($h.Substring(0, 2), 16),
        [Convert]::ToInt32($h.Substring(2, 2), 16),
        [Convert]::ToInt32($h.Substring(4, 2), 16))
}

$source = 'assets/sprites/restaurant/food_cart_0.png'
$work = 'tmp/imagegen/food_cart_1/food_cart_1.png'
$final = 'assets/sprites/restaurant/food_cart_1.png'
$bitmap = [Drawing.Bitmap]::FromFile($source)
$out = [Drawing.Bitmap]::new(64, 32, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [Drawing.Graphics]::FromImage($out)
$g.Clear([Drawing.Color]::Transparent)
$g.DrawImageUnscaled($bitmap, 0, 0)
$g.Dispose()
$bitmap.Dispose()

# Level 1 keeps the approved cart body and swaps only its left cooking module
# for a compact single-burner gas hob. Every mark stays on the native grid.
$navy = C '172038'
$deep = C '202e37'
$steelDark = C '394a50'
$steel = C '819796'
$steelLight = C 'c7cfcc'
$white = C 'ebede9'
$orange = C 'de9e41'
$red = C 'cf573c'

# Clear the old charcoal/fire cues on the left top tray while preserving frame.
for ($y = 4; $y -le 11; $y++) {
    for ($x = 6; $x -le 25; $x++) {
        $out.SetPixel($x, $y, [Drawing.Color]::Transparent)
    }
}

# Orthographic counter lip and single gas hob.
for ($x = 6; $x -le 25; $x++) { $out.SetPixel($x, 4, $navy); $out.SetPixel($x, 11, $navy) }
for ($y = 5; $y -le 10; $y++) { $out.SetPixel(6, $y, $navy); $out.SetPixel(25, $y, $navy) }
for ($y = 5; $y -le 10; $y++) {
    for ($x = 7; $x -le 24; $x++) { $out.SetPixel($x, $y, $steel) }
}
for ($x = 7; $x -le 24; $x++) { $out.SetPixel($x, 5, $steelLight) }

# One burner: dark square cradle, metal ring, warm central flame cue.
for ($y = 6; $y -le 9; $y++) {
    for ($x = 11; $x -le 18; $x++) { $out.SetPixel($x, $y, $deep) }
}
for ($x = 12; $x -le 17; $x++) { $out.SetPixel($x, 6, $navy); $out.SetPixel($x, 9, $navy) }
$out.SetPixel(11, 7, $navy); $out.SetPixel(11, 8, $navy)
$out.SetPixel(18, 7, $navy); $out.SetPixel(18, 8, $navy)
for ($x = 13; $x -le 16; $x++) { $out.SetPixel($x, 7, $orange); $out.SetPixel($x, 8, $red) }

# Simple control panel; the cart's far-right top remains untouched and clear
# for the separately rendered beer_tap.png.
for ($x = 20; $x -le 23; $x++) { $out.SetPixel($x, 7, $steelDark) }
$out.SetPixel(21, 8, $navy)
$out.SetPixel(22, 8, $white)

$out.SetPixel(0, 0, [Drawing.Color]::Transparent)
$out.SetPixel(63, 0, [Drawing.Color]::Transparent)
$out.SetPixel(0, 31, [Drawing.Color]::Transparent)
$out.SetPixel(63, 31, [Drawing.Color]::Transparent)
$out.Save($work, [Drawing.Imaging.ImageFormat]::Png)
$out.Dispose()
Copy-Item -LiteralPath $work -Destination $final -Force
Write-Output "Built $final from approved level-0 cart plus a native-grid level-1 gas module."
