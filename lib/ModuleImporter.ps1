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
        } elseif ($RepoUrl -match '^[A-Za-z0-9_.-]+$') {
            # Check if defined in nx.config.json first
            $matchedRepo = $null
            if (Test-Path ".\nx.config.json") {
                try {
                    $cfg = Get-Content ".\nx.config.json" -Raw | ConvertFrom-Json
                    $clean = $RepoUrl -replace '^easy-trade-module-', ''
                    $found = $cfg.modules | Where-Object { $_.name -eq $RepoUrl -or $_.name -eq $clean }
                    if ($found -and $found.repository) {
                        $matchedRepo = $found.repository
                    }
                } catch {}
            }
            if ($matchedRepo) {
                $RepoUrl = $matchedRepo
            } else {
                # Derive default GitHub owner from current project remote
                $defaultOwner = "empereur98"
                try {
                    $originUrl = git config --get remote.origin.url 2>$null
                    if ($originUrl -match 'github\.com[:/]([^/]+)/') {
                        $defaultOwner = $matches[1]
                    }
                } catch {}
                $repoName = if ($RepoUrl.StartsWith("easy-trade-module-")) { $RepoUrl } else { "easy-trade-module-$RepoUrl" }
                $RepoUrl = "https://github.com/$defaultOwner/$repoName.git"
            }
        }
    }

    Write-Host "[INFO] Checking existence of remote repository '$RepoUrl'..." -ForegroundColor Cyan
    if (-not (Test-RepoExists $RepoUrl)) {
        Write-Host "[ERROR] Remote repository '$RepoUrl' does not exist or is inaccessible. Aborting import." -ForegroundColor Red
        return
    }

    function Get-CleanModuleName {
        param([string]$Raw)
        if ([string]::IsNullOrWhiteSpace($Raw)) { return "" }
        $n = [System.IO.Path]::GetFileNameWithoutExtension($Raw)
        # 1. Matches <anything>-module-<name> (e.g. easy-trade-module-audit-logs, crm-module-billing)
        if ($n -match '^[A-Za-z0-9_.-]+-module-(.+)$') {
            return $matches[1]
        }
        # 2. Matches easy-trade-<name>
        if ($n -match '^easy-trade-(.+)$') {
            return $matches[1]
        }
        # 3. Matches <project_name>-<name>
        $proj = $null
        if (Test-Path ".\nx.config.json") {
            try {
                $cfg = Get-Content ".\nx.config.json" -Raw | ConvertFrom-Json
                if ($cfg.name) { $proj = $cfg.name }
            } catch {}
        }
        if (-not $proj) { $proj = (Get-Item (Get-Location).Path).Name }
        if ($proj) {
            $basePrefix = $proj -replace '-dashboard[0-9]*$', ''
            $escProj = [regex]::Escape($proj)
            $escBase = [regex]::Escape($basePrefix)
            if ($n -match "^$escProj-(.+)$") { return $matches[1] }
            if ($basePrefix -and $n -match "^$escBase-(.+)$") { return $matches[1] }
        }
        return $n
    }

    if ([string]::IsNullOrWhiteSpace($TargetName)) {
        $rawTarget = [System.IO.Path]::GetFileNameWithoutExtension($RepoUrl)
        $TargetName = Get-CleanModuleName $rawTarget
    } else {
        $TargetName = Get-CleanModuleName $TargetName
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
