param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("linux-x64", "linux-arm64")]
  [string]$RuntimeId,

  [ValidateSet("Debug", "Release")]
  [string]$Configuration = "Release"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$parts = $RuntimeId.Split("-", 2)
$targetOs = $parts[0]
$targetArch = $parts[1]

$actualOs = if ($IsLinux) { "linux" } else { "unsupported" }
$actualArch = [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture.ToString().ToLowerInvariant()

if ($actualOs -ne $targetOs -or $actualArch -ne $targetArch) {
  throw "Runtime '$RuntimeId' must be built on a native $targetOs/$targetArch runner; current process is $actualOs/$actualArch."
}

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$sourceDir = Join-Path $repoRoot "native"
$buildDir = Join-Path $repoRoot "artifacts/build/$RuntimeId"
$outputDir = Join-Path $repoRoot "artifacts/native/$RuntimeId"

New-Item -ItemType Directory -Force -Path $buildDir, $outputDir | Out-Null

$cmakeArgs = @(
  "-S", $sourceDir,
  "-B", $buildDir,
  "-G", "Ninja",
  "-DCMAKE_BUILD_TYPE=$Configuration"
)

Write-Host "Configuring $RuntimeId"
& cmake @cmakeArgs
if ($LASTEXITCODE -ne 0) { throw "CMake configure failed with exit code $LASTEXITCODE." }

Write-Host "Building nserial for $RuntimeId"
& cmake --build $buildDir --config $Configuration --target nserial --parallel
if ($LASTEXITCODE -ne 0) { throw "CMake build failed with exit code $LASTEXITCODE." }

$libraryDirectory = Join-Path $buildDir "serialportstream/libnserial"
$libraryPattern = "libnserial.so.*"
$library = Get-ChildItem -LiteralPath $libraryDirectory -Filter $libraryPattern -File |
  Sort-Object Length -Descending |
  Select-Object -First 1

if ($null -eq $library) {
  throw "Native library matching '$libraryPattern' was not found below '$libraryDirectory'."
}

$destination = Join-Path $outputDir "libnserial.so.1"
Copy-Item -LiteralPath $library.FullName -Destination $destination -Force

Write-Host "Native runtime: $destination"
& cmake -E sha256sum $destination
if ($LASTEXITCODE -ne 0) { throw "Could not hash the native runtime." }
