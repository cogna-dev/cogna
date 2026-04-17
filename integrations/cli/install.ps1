param(
  [string]$InstallDir = "",
  [string]$BinaryName = "cogna"
)

$resolvedInstallDir = $InstallDir
if ([string]::IsNullOrWhiteSpace($resolvedInstallDir)) {
  if ([string]::IsNullOrWhiteSpace($env:COGNA_INSTALL_DIR)) {
    $resolvedInstallDir = Join-Path $HOME ".moon/bin"
  } else {
    $resolvedInstallDir = $env:COGNA_INSTALL_DIR
  }
}

New-Item -ItemType Directory -Force -Path $resolvedInstallDir | Out-Null
moon install --bin "$resolvedInstallDir" --path src/cmd/main

$mainPath = Join-Path $resolvedInstallDir "main.exe"
if (-not (Test-Path $mainPath)) {
  $mainPath = Join-Path $resolvedInstallDir "main"
}
if (-not (Test-Path $mainPath)) {
  throw "Expected MoonBit install to create main(.exe) in $resolvedInstallDir"
}

if ($BinaryName -ne "main") {
  $extension = [System.IO.Path]::GetExtension($mainPath)
  $cognaPath = Join-Path $resolvedInstallDir ($BinaryName + $extension)
  Copy-Item $mainPath $cognaPath -Force
}
