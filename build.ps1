# Cubo Magico 3D - build
# Criado por Joaquim Pedro de Morais Filho - j360074@hotmail.com
#
# Compila o CuboMagico3D.exe (baixa as DLLs do WebView2 do NuGet, se preciso)
# e, se o Windows SDK estiver presente, empacota o MSIX.
#   powershell -ExecutionPolicy Bypass -File build.ps1

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$refs = Join-Path $here 'refs'
New-Item -ItemType Directory -Force $refs | Out-Null

# 1) WebView2 SDK (DLLs gerenciadas + loader nativo x64)
$coreDll = Join-Path $refs 'Microsoft.Web.WebView2.Core.dll'
if (-not (Test-Path $coreDll)) {
  Write-Host 'Baixando o SDK do WebView2 (NuGet)...' -ForegroundColor Cyan
  $ver = '1.0.2792.45'
  $nupkg = Join-Path $refs 'webview2.zip'
  $ProgressPreference = 'SilentlyContinue'
  Invoke-WebRequest "https://www.nuget.org/api/v2/package/Microsoft.Web.WebView2/$ver" -OutFile $nupkg
  $ex = Join-Path $refs '_wv2'
  if (Test-Path $ex) { Remove-Item $ex -Recurse -Force }
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [System.IO.Compression.ZipFile]::ExtractToDirectory($nupkg, $ex)
  Copy-Item "$ex\lib\net462\Microsoft.Web.WebView2.Core.dll" $refs -Force
  Copy-Item "$ex\lib\net462\Microsoft.Web.WebView2.WinForms.dll" $refs -Force
  Copy-Item "$ex\runtimes\win-x64\native\WebView2Loader.dll" $refs -Force
  Remove-Item $ex -Recurse -Force; Remove-Item $nupkg -Force
}

# 2) Compila
$csc = "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
Write-Host 'Compilando CuboMagico3D.exe...' -ForegroundColor Cyan
& $csc /nologo /target:winexe /codepage:65001 /out:"$here\CuboMagico3D.exe" `
  /r:"$refs\Microsoft.Web.WebView2.Core.dll" `
  /r:"$refs\Microsoft.Web.WebView2.WinForms.dll" `
  /r:System.Windows.Forms.dll /r:System.Drawing.dll /r:System.dll /r:System.Core.dll `
  "$here\CubeHost.cs"
if (-not (Test-Path "$here\CuboMagico3D.exe")) { throw 'Falha ao compilar.' }
Write-Host "OK: $here\CuboMagico3D.exe" -ForegroundColor Green

# 3) MSIX (opcional) - precisa do makeappx (Windows 10/11 SDK)
$ma = Get-ChildItem 'C:\Program Files (x86)\Windows Kits\10\bin\*\x64\makeappx.exe' -ErrorAction SilentlyContinue |
      Sort-Object FullName -Descending | Select-Object -First 1
if (-not $ma) { Write-Host 'makeappx nao encontrado - pulei o MSIX (instale o Windows SDK).' -ForegroundColor Yellow; return }

$stage = Join-Path $here '_pkg'
if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
New-Item -ItemType Directory -Path "$stage\Assets","$stage\web\lib" -Force | Out-Null
Copy-Item "$here\CuboMagico3D.exe" "$stage\CubeHost.exe" -Force
Copy-Item "$refs\Microsoft.Web.WebView2.Core.dll" $stage -Force
Copy-Item "$refs\Microsoft.Web.WebView2.WinForms.dll" $stage -Force
Copy-Item "$refs\WebView2Loader.dll" $stage -Force
Copy-Item "$here\msix\AppxManifest.xml" "$stage\AppxManifest.xml" -Force
Get-ChildItem "$here\Assets" -File | ForEach-Object { Copy-Item $_.FullName "$stage\Assets\" -Force }
Copy-Item "$here\web\index.html" "$stage\web\" -Force
Copy-Item "$here\web\lib\three.min.js" "$stage\web\lib\" -Force
Copy-Item "$here\web\lib\OrbitControls.js" "$stage\web\lib\" -Force
$msix = Join-Path $here 'CuboMagico3D-1.0.0.0.msix'
& $ma.FullName pack /d $stage /p $msix /o
Write-Host "MSIX: $msix" -ForegroundColor Green
Write-Host 'Para a Store: troque Identity Name/Publisher no msix/AppxManifest.xml pelos valores do Partner Center e gere de novo.' -ForegroundColor Cyan
