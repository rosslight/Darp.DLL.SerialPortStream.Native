# Darp.DLL.SerialPortStream.Native

Builds and packages the native `libnserial` library used by
[`RJCP.SerialPortStream`](https://github.com/jcurl/RJCP.DLL.SerialPortStream).
The upstream repository is pinned as a Git submodule, so native builds are
reproducible without copying its sources into this repository.

The NuGet package contains native assets for these runtime identifiers:

- `linux-x64`
- `linux-arm64`

## Consume the package

Reference the managed and native packages together:

```xml
<ItemGroup>
  <PackageReference Include="RJCP.SerialPortStream" Version="3.0.5" />
  <PackageReference Include="Darp.DLL.SerialPortStream.Native" Version="0.1.0" />
</ItemGroup>
```

The package places a native binary named `libnserial.so.1` in every runtime
asset directory. That exact name is intentional: it matches the library name
used by the managed P/Invoke declarations.

## Build locally

Initialize the submodule and build for the current machine:

```powershell
git submodule update --init --recursive
./scripts/build-native.ps1 -RuntimeId linux-x64
```

Then pack after all desired runtime directories exist below
`artifacts/native`:

```powershell
dotnet pack src/Darp.DLL.SerialPortStream.Native/Darp.DLL.SerialPortStream.Native.csproj `
  -c Release `
  -o artifacts/packages
```

The GitHub Actions workflow builds on native Linux x64 and arm64 runners,
aggregates both binaries into one package, and tests that package on both
architectures. The linked test fixture comes directly from the pinned upstream
submodule; the small local support classes only replace upstream test-project
dependencies that live in separate repositories.

## Updating upstream

Update the submodule deliberately and run the complete workflow:

```powershell
git -C native/SerialPortStream fetch --tags
git -C native/SerialPortStream checkout <commit-or-tag>
git add native/SerialPortStream
```

If upstream changes its native ABI, update `NativeLibraryVersion` and the build
script's expected output names together.
