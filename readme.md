# Flutter Installer for Windows

Beta PowerShell installer for Flutter on Windows.

## Install

Run in PowerShell:

```powershell
irm ps.env.tn/flutter.ps1 | iex
```

The script downloads the latest Flutter release, installs it, and adds `flutter\bin` to your user `PATH`.

Verify:

```powershell
flutter --version
```

## Status

Beta — expect changes and report any issues.
