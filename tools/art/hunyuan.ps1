# Windows wrapper for hunyuan_job.py (image -> GLB via Tencent's public Space).
# Fallback only (Space quota); the main tool is tools/art/hunyuan_local.ps1.
# Usage: powershell -File tools/art/hunyuan.ps1 -Image <png> -OutDir <dir> -Name <id> [-Faces 2000] [-ReuseRaw]
# Needs uv (https://docs.astral.sh/uv/); uv fetches Python 3.12 + gradio-client on first run.
param(
    [Parameter(Mandatory = $true)][string]$Image,
    [Parameter(Mandatory = $true)][string]$OutDir,
    [Parameter(Mandatory = $true)][string]$Name,
    [int]$Faces = 2000,
    [int]$Steps = 20,
    [int]$Octree = 192,
    [int]$Seed = 1234,
    [int]$Timeout = 300,
    [switch]$ReuseRaw
)
$job = Join-Path $PSScriptRoot 'hunyuan_job.py'
$jobArgs = @('--image', $Image, '--out-dir', $OutDir, '--name', $Name, '--faces', $Faces,
    '--steps', $Steps, '--octree', $Octree, '--seed', $Seed, '--timeout', $Timeout)
if ($ReuseRaw) { $jobArgs += '--reuse-raw' }
uvx --python 3.12 --from gradio-client==1.3.0 --with numpy --with pillow python $job @jobArgs
exit $LASTEXITCODE
