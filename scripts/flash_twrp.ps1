# flash_twrp.ps1 - Flashea recovery.img desde PowerShell (via ToolBox o dd)
# Uso: .\flash_twrp.ps1 [ruta\recovery.img]

param(
    [string]$ImagePath = ".\recovery.img"
)

if (-not (Test-Path $ImagePath)) {
    Write-Host "❌ No se encuentra: $ImagePath" -ForegroundColor Red
    exit 1
}

$FullPath = Resolve-Path $ImagePath
$Size = (Get-Item $FullPath).Length
Write-Host "📦 Imagen: $FullPath ($([math]::Round($Size/1MB, 1)) MB)" -ForegroundColor Cyan

Write-Host ""
Write-Host "Para flashear desde Windows:" -ForegroundColor Yellow
Write-Host "  1. Abre ZTE ToolBox (opción 12 -> recovery_b)" -ForegroundColor Yellow
Write-Host "  2. Selecciona: $FullPath" -ForegroundColor Yellow
Write-Host ""
Write-Host "O desde ADB (con root):" -ForegroundColor Yellow
Write-Host "  adb push `"$FullPath`" /sdcard/Download/" -ForegroundColor Yellow
Write-Host "  adb shell `"dd if=/sdcard/Download/recovery.img of=/dev/block/bootdevice/by-name/recovery_b`"" -ForegroundColor Yellow
