function Remove-NxModule {
    param(
        [string]$ModuleName,
        [string]$CliDir
    )

    if ([string]::IsNullOrWhiteSpace($ModuleName)) {
        Write-Host "[ERROR] Module or model name is required for deletion (-d)." -ForegroundColor Red
        Write-Host "Usage: nx -m <module_name> -d  OR  nx -d <module_name>"
        return
    }

    $cleanName = $ModuleName -replace '^[A-Za-z0-9_.-]+-module-', '' -replace '^easy-trade-', ''

    # Determine project root and modules dir
    $projRoot = (Get-Location).Path
    $modulesDir = ""
    if (Test-Path ".\modules") {
        $modulesDir = (Resolve-Path ".\modules").Path
        $projRoot = (Get-Location).Path
    } elseif ((Split-Path -Leaf (Get-Location).Path) -eq "modules") {
        $modulesDir = (Get-Location).Path
        $projRoot = Split-Path -Parent (Get-Location).Path
    } elseif (Test-Path "..\modules") {
        $modulesDir = (Resolve-Path "..\modules").Path
        $projRoot = Split-Path -Parent (Get-Location).Path
    }

    $targetDir = ""
    $actualDirName = ""

    # Candidates to match
    $candidates = @($ModuleName, $cleanName, "easy-trade-module-$cleanName", "easy-trade-$cleanName")
    
    if ($modulesDir -and (Test-Path $modulesDir)) {
        foreach ($cand in $candidates) {
            $candPath = Join-Path $modulesDir $cand
            if (Test-Path $candPath) {
                $targetDir = $candPath
                $actualDirName = Split-Path -Leaf $candPath
                break
            }
        }
        if (-not $targetDir) {
            # Search child dirs for fuzzy match
            $found = Get-ChildItem -Directory $modulesDir | Where-Object {
                $_.Name -eq $ModuleName -or
                $_.Name -eq $cleanName -or
                $_.Name -like "*$cleanName*" -or
                ($_.Name -replace '^[A-Za-z0-9_.-]+-module-', '' -replace '^easy-trade-', '') -eq $cleanName
            } | Select-Object -First 1
            if ($found) {
                $targetDir = $found.FullName
                $actualDirName = $found.Name
            }
        }
    }

    if (-not $targetDir) {
        Write-Host "[ERROR] Module or model '$ModuleName' not found in $modulesDir." -ForegroundColor Red
        return
    }

    Write-Host "[INFO] Removing module '$actualDirName' from project..." -ForegroundColor Yellow

    # Unregister from nuxt.config.ts
    $nuxtConfig = Join-Path $projRoot "nuxt.config.ts"
    if (Test-Path $nuxtConfig) {
        $c = Get-Content $nuxtConfig -Raw -Encoding utf8
        $c = $c -replace "['`"]./modules/$actualDirName['`"],*", ""
        $c = $c -replace "['`"]./modules/$ModuleName['`"],*", ""
        $c = $c -replace "['`"]./modules/$cleanName['`"],*", ""
        $c = $c -replace "['`"]~/modules/$actualDirName['`"],*", ""
        $c = $c -replace "['`"]~/modules/$ModuleName['`"],*", ""
        $c = $c -replace "['`"]~/modules/$cleanName['`"],*", ""
        [System.IO.File]::WriteAllText($nuxtConfig, $c, [System.Text.Encoding]::UTF8)
    }

    # Unregister from nx.config.json
    $nxConfigPath = Join-Path $projRoot "nx.config.json"
    if (Test-Path $nxConfigPath) {
        try {
            $json = Get-Content $nxConfigPath -Raw | ConvertFrom-Json
            if ($null -ne $json.modules) {
                $filtered = @($json.modules | Where-Object { $_.name -ne $actualDirName -and $_.name -ne $ModuleName -and $_.name -ne $cleanName })
                $json.modules = $filtered
                $jsonStr = $json | ConvertTo-Json -Depth 5
                [System.IO.File]::WriteAllText($nxConfigPath, $jsonStr, [System.Text.Encoding]::UTF8)
            }
        } catch {}
    }

    # Delete physical directory
    Remove-Item -Path $targetDir -Recurse -Force
    Write-Host "[SUCCESS] Deleted directory $targetDir" -ForegroundColor Green

    # Refresh Nuxt types if inside a Nuxt project
    if (Test-Path (Join-Path $projRoot "nuxt.config.ts")) {
        Write-Host "[INFO] Refreshing Nuxt declarations..." -ForegroundColor Cyan
        Push-Location $projRoot
        try {
            cmd.exe /c "npx nuxt prepare"
        } finally {
            Pop-Location
        }
    }

    Write-Host ""
    Write-Host "[SUCCESS] Module '$actualDirName' removed successfully from project." -ForegroundColor Green
    Write-Host ""
}
