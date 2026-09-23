# scripts/setup.ps1
# FreeLLMAPI Portable — one-time setup. Run from the portable folder root.
$ErrorActionPreference = "Stop"

$Root    = Split-Path -Parent $PSScriptRoot
$NodeDir = Join-Path $Root "runtime\node"
$AppDir  = Join-Path $Root "app"
$DataDir = Join-Path $Root "data"
$TempDir = Join-Path $Root "temp"

$NodeVersion = "22.14.0"
$NodeZipUrl  = "https://nodejs.org/dist/v$NodeVersion/node-v$NodeVersion-win-x64.zip"
$RepoZipUrl  = "https://github.com/tashfeenahmed/freellmapi/archive/refs/heads/main.zip"

New-Item -ItemType Directory -Force -Path $NodeDir, $AppDir, $DataDir, $TempDir | Out-Null

# 1. Bundled Node runtime
if (-not (Test-Path (Join-Path $NodeDir "node.exe"))) {
    Write-Host "Downloading portable Node.js v$NodeVersion..."
    $nodeZip = Join-Path $TempDir "node.zip"
    Invoke-WebRequest -Uri $NodeZipUrl -OutFile $nodeZip
    Expand-Archive -Path $nodeZip -DestinationPath $TempDir -Force
    $extracted = Join-Path $TempDir "node-v$NodeVersion-win-x64"
    Get-ChildItem $extracted | Move-Item -Destination $NodeDir -Force
    Remove-Item $extracted, $nodeZip -Recurse -Force
}
$env:PATH = "$NodeDir;$env:PATH"

# 2. App source
if (-not (Test-Path (Join-Path $AppDir "package.json"))) {
    Write-Host "Downloading FreeLLMAPI source..."
    $repoZip = Join-Path $TempDir "repo.zip"
    Invoke-WebRequest -Uri $RepoZipUrl -OutFile $repoZip
    Expand-Archive -Path $repoZip -DestinationPath $TempDir -Force
    $extracted = Join-Path $TempDir "freellmapi-main"
    Get-ChildItem $extracted | Move-Item -Destination $AppDir -Force
    Remove-Item $extracted, $repoZip -Recurse -Force
}

# 3. Install + build (all installs stay inside app/node_modules — no global npm cache pollution)
Push-Location $AppDir
$env:npm_config_cache = Join-Path $Root "cache\npm"
& "$NodeDir\npm.cmd" install
& "$NodeDir\npm.cmd" run build
Pop-Location

# 4. First-run .env — generates ENCRYPTION_KEY once, never overwrites an existing .env
$envFile = Join-Path $AppDir ".env"
if (-not (Test-Path $envFile)) {
    Write-Host "Generating encryption key and .env..."
    $key = & "$NodeDir\node.exe" -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
    @"
ENCRYPTION_KEY=$key
PORT=3001
NODE_ENV=production
"@ | Set-Content -Path $envFile -Encoding ascii
}

Write-Host "Setup complete. Run launch.bat to start FreeLLMAPI."