function Initialize-NxCli {
    param(
        [string]$CliDir
    )

    Write-Host "[INFO] Initializing global 'nx' CLI command on Windows..." -ForegroundColor Cyan

    $userBin = Join-Path $HOME ".local\bin"
    if (-not (Test-Path $userBin)) {
        New-Item -ItemType Directory -Path $userBin -Force | Out-Null
    }

    Copy-Item (Join-Path $CliDir "nx") (Join-Path $userBin "nx") -Force -ErrorAction SilentlyContinue
    Copy-Item (Join-Path $CliDir "nx.cmd") (Join-Path $userBin "nx.cmd") -Force -ErrorAction SilentlyContinue
    Copy-Item (Join-Path $CliDir "nx.ps1") (Join-Path $userBin "nx.ps1") -Force -ErrorAction SilentlyContinue

    # Ensure lib and templates are also accessible globally if running from userBin
    $userLib = Join-Path $userBin "lib"
    $userTemplates = Join-Path $userBin "templates"
    $userMan = Join-Path $userBin "man"
    Copy-Item (Join-Path $CliDir "lib") $userLib -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item (Join-Path $CliDir "templates") $userTemplates -Recurse -Force -ErrorAction SilentlyContinue
    Copy-Item (Join-Path $CliDir "man") $userMan -Recurse -Force -ErrorAction SilentlyContinue

    $userPath = [Environment]::GetEnvironmentVariable('PATH', 'User')
    $pathParts = $userPath -split ';'
    if ($pathParts -notcontains $userBin) {
        $newPath = ($pathParts + $userBin) -join ';'
        [Environment]::SetEnvironmentVariable('PATH', $newPath, 'User')
        $env:PATH = "$env:PATH;$userBin"
        Write-Host "[SUCCESS] Added $userBin to User PATH." -ForegroundColor Green
    }

    Write-Host "[SUCCESS] Configured global 'nx' command for Windows in $userBin" -ForegroundColor Green
    Write-Host "[TIP] You can now open a new terminal and type: nx --help" -ForegroundColor Yellow
}
