# Copy one character's LuAshitacast profiles plus common/ into a HorizonXI install.
# usage: .\scripts\deploy.ps1 -Character Name_Id [-GameDir "C:\...\HorizonXI\Game"] [-DestName Name_Id]
#   -DestName defaults to -Character; use it when the repo folder lacks the character id.
param(
    [Parameter(Mandatory = $true)] [string] $Character,
    [string] $GameDir = "C:\Program Files\HorizonXI\Game",
    [string] $DestName = ""
)
if ($DestName -eq "") { $DestName = $Character }
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$src = Join-Path $repo "luashitacast\$Character"
if (-not (Test-Path $src)) { throw "no such character folder: $src" }
$dst = Join-Path $GameDir "config\addons\luashitacast"
New-Item -ItemType Directory -Force -Path (Join-Path $dst $DestName), (Join-Path $dst 'common') | Out-Null
Copy-Item (Join-Path $src '*.lua') (Join-Path $dst $DestName) -Force
$common = Join-Path $repo 'luashitacast\common\*.lua'
if (Test-Path $common) { Copy-Item $common (Join-Path $dst 'common') -Force }
Write-Host "deployed $Character to $dst\$DestName"
Write-Host "in game: /lac reload"
