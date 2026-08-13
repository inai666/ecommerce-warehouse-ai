$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$inputZip = 'C:\Users\jujin\Downloads\UserBehavior.csv.zip'
$python = 'C:\Users\jujin\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'

Set-Location -LiteralPath $projectRoot

if (-not (Test-Path -LiteralPath $inputZip -PathType Leaf)) {
    throw "Dataset ZIP not found: $inputZip"
}

if (-not (Test-Path -LiteralPath $python -PathType Leaf)) {
    $pythonCommand = Get-Command python -ErrorAction SilentlyContinue
    if ($null -eq $pythonCommand) {
        throw 'Python was not found.'
    }
    $python = $pythonCommand.Source
}

& $python '.\scripts\sample_and_profile.py' `
    --input $inputZip `
    --rows 1000000 `
    --smoke-rows 10000 `
    --seed 42 `
    --output-dir '.\data\sample' `
    --profile '.\docs\profile.md'

if ($LASTEXITCODE -ne 0) {
    throw "Sampling failed with exit code $LASTEXITCODE"
}

Write-Host ''
Write-Host 'Tutorial 00 completed.' -ForegroundColor Green
Write-Host "Open: $projectRoot\docs\profile.md"

