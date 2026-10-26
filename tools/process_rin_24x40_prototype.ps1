Add-Type -AssemblyName System.Drawing

$out = [Drawing.Bitmap]::new(96, 120, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
$out.SetResolution(96, 96)

function C([string]$hex) { [Drawing.ColorTranslator]::FromHtml("#$hex") }
function Fill([int]$frame, [int]$row, [int]$x, [int]$y, [int]$w, [int]$h, [string]$hex) {
    for ($py=$y; $py-lt $y+$h; $py++) { for ($px=$x; $px-lt $x+$w; $px++) {
        if ($px-ge 0 -and $px-lt 24 -and $py-ge 0 -and $py-lt 40) {
            $out.SetPixel($frame*24+$px, $row*40+$py, (C $hex))
        }
    }}
}

$outline='151d28'; $hair='090a14'; $hairHi='202e37'; $skin='c09473'; $skinHi='d7b594'
$blue='253a5e'; $blueHi='3c5e8b'; $pants='202e37'; $pantsHi='394a50'; $shoe='884b2b'; $glass='a4dddb'

function Front([int]$f) {
    # Hair/head: intentionally broad, readable clusters rather than fine strands.
    Fill $f 0 6 2 12 2 $outline; Fill $f 0 4 4 16 8 $hair; Fill $f 0 6 2 4 3 $hair
    Fill $f 0 3 7 3 6 $hair; Fill $f 0 18 7 3 6 $hair; Fill $f 0 7 4 4 2 $hairHi; Fill $f 0 15 5 3 2 $hairHi
    Fill $f 0 6 10 12 7 $skin; Fill $f 0 8 11 8 5 $skinHi; Fill $f 0 5 12 2 3 $skin; Fill $f 0 17 12 2 3 $skin
    Fill $f 0 6 11 5 3 $outline; Fill $f 0 13 11 5 3 $outline; Fill $f 0 8 12 2 1 $glass; Fill $f 0 14 12 2 1 $glass; Fill $f 0 11 12 2 1 $outline
    Fill $f 0 9 17 6 2 $skin
    Fill $f 0 6 18 12 11 $blue; Fill $f 0 8 18 8 3 $blueHi; Fill $f 0 4 20 3 8 $blue; Fill $f 0 17 20 3 8 $blue
    Fill $f 0 4 27 4 2 $skin; Fill $f 0 16 27 4 2 $skin
    Fill $f 0 7 28 10 3 $outline
    $left = 7; $right = 13
    if ($f -eq 1) { $left=6; $right=14 } elseif ($f -eq 3) { $left=8; $right=12 }
    Fill $f 0 $left 30 4 8 $pants; Fill $f 0 $right 30 4 8 $pants; Fill $f 0 ($left+1) 30 2 5 $pantsHi; Fill $f 0 ($right+1) 30 2 5 $pantsHi
    Fill $f 0 ($left-1) 37 6 3 $shoe; Fill $f 0 ($right-1) 37 6 3 $shoe
}

function Back([int]$f) {
    Fill $f 1 5 2 14 2 $outline; Fill $f 1 4 4 16 11 $hair; Fill $f 1 3 8 3 6 $hair; Fill $f 1 18 8 3 6 $hair
    Fill $f 1 7 5 4 2 $hairHi; Fill $f 1 14 5 4 2 $hairHi; Fill $f 1 9 15 6 3 $skin
    Fill $f 1 6 18 12 11 $blue; Fill $f 1 8 19 8 3 $blueHi; Fill $f 1 4 20 3 9 $blue; Fill $f 1 17 20 3 9 $blue
    Fill $f 1 7 28 10 3 $outline
    $left=7; $right=13; if($f-eq 1){$left=6;$right=14}elseif($f-eq 3){$left=8;$right=12}
    Fill $f 1 $left 30 4 8 $pants; Fill $f 1 $right 30 4 8 $pants; Fill $f 1 ($left+1) 30 2 5 $pantsHi; Fill $f 1 ($right+1) 30 2 5 $pantsHi
    Fill $f 1 ($left-1) 37 6 3 $shoe; Fill $f 1 ($right-1) 37 6 3 $shoe
}

function Side([int]$f) {
    Fill $f 2 6 3 11 2 $outline; Fill $f 2 5 5 14 9 $hair; Fill $f 2 4 8 3 5 $hair; Fill $f 2 8 4 4 2 $hairHi
    Fill $f 2 4 12 10 6 $skin; Fill $f 2 3 14 3 2 $skinHi; Fill $f 2 5 12 5 3 $outline; Fill $f 2 6 13 2 1 $glass
    Fill $f 2 10 17 4 2 $skin; Fill $f 2 9 18 9 11 $blue; Fill $f 2 14 20 4 8 $blueHi; Fill $f 2 16 27 4 2 $skin
    Fill $f 2 8 28 10 3 $outline
    if($f -in 1,3){ Fill $f 2 5 30 5 8 $pants; Fill $f 2 13 30 5 8 $pants; Fill $f 2 3 37 7 3 $shoe; Fill $f 2 13 37 8 3 $shoe }
    else { Fill $f 2 8 30 4 8 $pants; Fill $f 2 13 30 4 8 $pantsHi; Fill $f 2 7 37 6 3 $shoe; Fill $f 2 12 37 7 3 $shoe }
}

foreach($f in 0..3){ Front $f; Back $f; Side $f }
$path='assets/sprites/characters/rin_24x40.png'
$out.Save($path,[Drawing.Imaging.ImageFormat]::Png); $out.Dispose()
Write-Output $path
