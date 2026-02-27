# Build and Release Script for DNS Changer
$ErrorActionPreference = "Stop"

$flutter = "h:\Hossein javan\project\flutter\bin\flutter.bat"

Write-Host "--- 1. Cleaning Build Folders ---" -ForegroundColor Cyan
& $flutter clean

Write-Host "--- 2. Fetching Dependencies ---" -ForegroundColor Cyan
& $flutter pub get

Write-Host "--- 3. Building Windows Release (v1.2.0) ---" -ForegroundColor Cyan
& $flutter build windows --release

$releasePath = "build\windows\x64\runner\Release"
if (-not (Test-Path $releasePath)) {
    Write-Error "Release build folder not found at $releasePath"
}

Write-Host "--- 4. Creating Portable ZIP ---" -ForegroundColor Cyan
$zipFile = "DNSChanger_v1.2.0_Portable.zip"
if (Test-Path $zipFile) { Remove-Item $zipFile }
Compress-Archive -Path "$releasePath\*" -DestinationPath $zipFile

Write-Host "--- 5. Compiling Windows Installer (Inno Setup) ---" -ForegroundColor Cyan
$innoPath = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
if (Test-Path $innoPath) {
    & $innoPath "installer_script.iss"
} else {
    Write-Warning "Inno Setup Compiler not found at $innoPath. Skipping installer build."
}

Write-Host "--- 6. Git Operations ---" -ForegroundColor Cyan
& git add .
& git commit -m "feat: v1.2.0 release (Single Instance behavior, Build Automation)"
& git push origin master

Write-Host "Development and Deployment Cycle Complete!" -ForegroundColor Green
