# Windows wrapper for hunyuan_local.py (Hunyuan3D-2mini on CPU, no quota, offline).
# Usage: powershell -File tools/art/hunyuan_local.ps1 -Image <png> -OutDir <dir> -Name <id> [-Faces 2000]
#        powershell -File tools/art/hunyuan_local.ps1 -InputDir <folder of png> -OutDir <root>
# Setup (once) is in docs/ART_PIPELINE.md. Override paths with $env:HY3D_HOME / $env:HY3DGEN_MODELS.
param(
    [string[]]$Image = @(),
    [string]$InputDir,
    [Parameter(Mandatory = $true)][string]$OutDir,
    [string]$Name,
    [int]$Faces = 2000,
    [int]$Steps = 5,
    [int]$Octree = 128,
    [int]$Seed = 1234,
    [switch]$NoFlashVDM
)
if (-not $env:HY3D_HOME) { $env:HY3D_HOME = 'E:\workSpace\Hunyuan3D-2' }
if (-not $env:HY3DGEN_MODELS) { $env:HY3DGEN_MODELS = 'E:\workSpace\hy3d_models' }
$env:HF_HUB_OFFLINE = '1'
$env:PYTHONUTF8 = '1'
$env:PYTHONUNBUFFERED = '1'
$python = Join-Path $env:HY3D_HOME '.venv\Scripts\python.exe'
if (-not (Test-Path $python)) { Write-Error "Missing $python (see docs/ART_PIPELINE.md)"; exit 1 }
$jobArgs = @('--out-dir', $OutDir, '--faces', $Faces, '--steps', $Steps, '--octree', $Octree, '--seed', $Seed)
if ($Image.Count) { $jobArgs += @('--image') + $Image }
if ($InputDir) { $jobArgs += @('--input-dir', $InputDir) }
if ($Name) { $jobArgs += @('--name', $Name) }
if ($NoFlashVDM) { $jobArgs += '--no-flashvdm' }
& $python (Join-Path $PSScriptRoot 'hunyuan_local.py') @jobArgs
exit $LASTEXITCODE
