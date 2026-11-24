# Vega Android Standalone APK Build Script
$ErrorActionPreference = "Stop"

$sdkDir = "C:\Users\meetp\AppData\Local\Android\Sdk"
$buildToolsDir = "$sdkDir\build-tools\35.0.0"
$platformJar = "$sdkDir\platforms\android-36\android.jar"
$jdkBin = "C:\Program Files\Eclipse Adoptium\jdk-25.0.4.101-hotspot\bin"

$aapt2 = "$buildToolsDir\aapt2.exe"
$aapt = "$buildToolsDir\aapt.exe"
$d8 = "$buildToolsDir\d8.bat"
$zipalign = "$buildToolsDir\zipalign.exe"
$apksigner = "$buildToolsDir\apksigner.bat"
$javac = "$jdkBin\javac.exe"
$keytool = "$jdkBin\keytool.exe"

$projDir = "c:\Personal Application\android_native"
$webDir = "c:\Personal Application\web_preview"
$outDir = "$projDir\build\apk"

Write-Host "==> 1. Syncing latest web assets..." -ForegroundColor Cyan
Copy-Item -Path "$webDir\*" -Destination "$projDir\assets\" -Recurse -Force
Copy-Item -Path "$webDir\icon-192.png" -Destination "$projDir\res\drawable\icon.png" -Force

Write-Host "==> 2. Compiling resources with aapt2..." -ForegroundColor Cyan
& $aapt2 compile --dir "$projDir\res" -o "$projDir\build\compiled_res.zip"
& $aapt2 link "$projDir\build\compiled_res.zip" -I $platformJar --manifest "$projDir\AndroidManifest.xml" --java "$projDir\build\gen" -o "$outDir\base.apk" -A "$projDir\assets" --auto-add-overlay

Write-Host "==> 3. Compiling Java sources..." -ForegroundColor Cyan
& $javac -cp "$platformJar" -d "$projDir\build\obj" "$projDir\build\gen\com\vega\trader\R.java" "$projDir\src\com\vega\trader\MainActivity.java" -source 8 -target 8 -Xlint:-options

Write-Host "==> 4. Converting bytecode to Dalvik dex..." -ForegroundColor Cyan
Push-Location "$projDir\build\obj"
cmd.exe /c "`"$d8`" --lib `"$platformJar`" --min-api 24 --output ..\apk com\vega\trader\*.class"
Pop-Location

Write-Host "==> 5. Packaging classes.dex into base.apk..." -ForegroundColor Cyan
Push-Location "$outDir"
& $aapt add base.apk classes.dex

Write-Host "==> 6. Aligning APK with zipalign..." -ForegroundColor Cyan
& $zipalign -p -f 4 base.apk vega-aligned.apk

Write-Host "==> 7. Signing APK with apksigner..." -ForegroundColor Cyan
if (-not (Test-Path vega-release.keystore)) {
    & $keytool -genkeypair -keystore vega-release.keystore -alias vega -keyalg RSA -keysize 2048 -validity 10000 -storepass vegakeystore -keypass vegakeystore -dname "CN=Meet Pandya, OU=Trading, O=Vega, L=Mumbai, ST=Maharashtra, C=IN"
}
cmd.exe /c "`"$apksigner`" sign --ks vega-release.keystore --ks-pass pass:vegakeystore --key-pass pass:vegakeystore --out Vega.apk vega-aligned.apk"
cmd.exe /c "`"$apksigner`" verify Vega.apk"

Copy-Item "Vega.apk" -Destination "c:\Personal Application\Vega.apk" -Force
Pop-Location

Write-Host " SUCCESS: Vega.apk built and ready at c:\Personal Application\Vega.apk" -ForegroundColor Green
Get-Item "c:\Personal Application\Vega.apk"
