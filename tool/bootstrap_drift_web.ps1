$ErrorActionPreference = 'Stop'

$DriftVersion = '2.35.1'
$WebDirectory = Join-Path $PSScriptRoot '..\web'
New-Item -ItemType Directory -Force -Path $WebDirectory | Out-Null

$BaseUrl = "https://github.com/simolus3/drift/releases/download/drift-$DriftVersion"
Invoke-WebRequest -Uri "$BaseUrl/sqlite3.wasm" -OutFile (Join-Path $WebDirectory 'sqlite3.wasm')
Invoke-WebRequest -Uri "$BaseUrl/drift_worker.js" -OutFile (Join-Path $WebDirectory 'drift_worker.js')

Write-Host "Drift Web assets installed in $WebDirectory"
