function Import-NxModule {
    param(
        [string]$RepoUrl,
        [string]$TargetName,
        [string]$CliDir,
        [string]$Branch = "main"
    )

    if ([string]::IsNullOrWhiteSpace($RepoUrl)) {
        if (Test-Path ".\nx.config.json") {
            Write-Host "[INFO] Syncing all modules defined in nx.config.json..." -ForegroundColor Cyan
            try {
                $nxConfig = Get-Content ".\nx.config.json" -Raw | ConvertFrom-Json
                foreach ($mod in $nxConfig.modules) {
                    $b = if ($mod.branch) { $mod.branch } else { "main" }
                    Import-NxModule -RepoUrl $mod.repository -TargetName $mod.name -CliDir $CliDir -Branch $b
                }
                return
            } catch {
                Write-Host "[ERROR] Could not parse nx.config.json." -ForegroundColor Red
                return
            }
        } else {
            Write-Host "[ERROR] No URL specified and no nx.config.json found." -ForegroundColor Red
            return
        }
    }

    # Normalize shorthand github repo format
    if ($RepoUrl -notmatch '^https?://' -and $RepoUrl -notmatch '^git@' -and $RepoUrl -notmatch '^ssh://') {
        if ($RepoUrl -match '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') {
            $RepoUrl = "https://github.com/$RepoUrl.git"
        }
    }

    Write-Host "[INFO] Checking existence of remote repository '$RepoUrl'..." -ForegroundColor Cyan
    if (-not (Test-RepoExists $RepoUrl)) {
        Write-Host "[ERROR] Remote repository '$RepoUrl' does not exist or is inaccessible. Aborting import." -ForegroundColor Red
        return
    }

    if ([string]::IsNullOrWhiteSpace($TargetName)) {
        $TargetName = [System.IO.Path]::GetFileNameWithoutExtension($RepoUrl)
    }

    $targetDir = ".\modules\$TargetName"

    if (Test-Path $targetDir) {
        Write-Host "[WARN] Module '$TargetName' already exists at $targetDir. Updating..." -ForegroundColor Yellow
        Push-Location $targetDir
        try {
            git pull origin $Branch
        } finally {
            Pop-Location
        }
    } else {
        Write-Host "[INFO] Cloning remote module '$TargetName' from $RepoUrl..." -ForegroundColor Cyan
        if (-not (Test-Path ".\modules")) {
            New-Item -ItemType Directory -Path ".\modules" -Force | Out-Null
        }

        git clone --depth 1 --single-branch --branch $Branch $RepoUrl $targetDir 2>$null
        if ($LASTEXITCODE -ne 0) {
            git clone --depth 1 $RepoUrl $targetDir 2>$null
            if ($LASTEXITCODE -ne 0) {
                Write-Host "[ERROR] Failed to clone remote module '$TargetName' from $RepoUrl. Aborting." -ForegroundColor Red
                if (Test-Path $targetDir) {
                    Remove-Item -Path $targetDir -Recurse -Force
                }
                return
            }
        }
    }

    if (Test-Path (Join-Path $targetDir "tsconfig.json")) {
        Set-Content -Path (Join-Path $targetDir "tsconfig.json") -Value '{"extends": "../../.nuxt/tsconfig.json"}' -Encoding utf8
    }

    Register-InNuxtConfig "./modules/$TargetName"

    # Update nx.config.json
    if (Test-Path ".\nx.config.json") {
        try {
            $nxConfig = Get-Content ".\nx.config.json" -Raw | ConvertFrom-Json
            $alreadyExists = $false
            foreach ($m in $nxConfig.modules) {
                if ($m.name -eq $TargetName) { $alreadyExists = $true; break }
            }
            if (-not $alreadyExists) {
                $newModule = [PSCustomObject]@{
                    name = $TargetName
                    repository = $RepoUrl
                    branch = $Branch
                }
                $modulesList = [System.Collections.ArrayList]@($nxConfig.modules)
                $modulesList.Add($newModule) | Out-Null
                $nxConfig.modules = $modulesList
                $nxConfig | ConvertTo-Json -Depth 5 | Set-Content ".\nx.config.json" -Encoding utf8
            }
        } catch {}
    }

    Write-Host "[INFO] Installing dependencies & preparing Nuxt types..." -ForegroundColor Cyan
    cmd.exe /c "npm install"
    cmd.exe /c "npx nuxt prepare"

    Write-Host "[SUCCESS] Module '$TargetName' imported successfully." -ForegroundColor Green
}
