function Update-NxModule {
    param(
        [string]$ModuleName
    )

    $modulesDir = ".\modules"

    if (-not [string]::IsNullOrWhiteSpace($ModuleName)) {
        $ModuleName = $ModuleName -replace '^easy-trade-module-', ''
        $targetDir = Join-Path $modulesDir $ModuleName
        if (-not (Test-Path $targetDir)) {
            Write-Host "[ERROR] Module '$ModuleName' not found in $modulesDir." -ForegroundColor Red
            return
        }

        Write-Host "[INFO] Updating module '$ModuleName'..." -ForegroundColor Cyan
        Push-Location $targetDir
        try {
            $branch = git branch --show-current 2>$null
            if (-not [string]::IsNullOrWhiteSpace($branch)) {
                git pull origin $branch
            } else {
                git pull
            }
        } finally {
            Pop-Location
        }

        if (Test-Path (Join-Path $targetDir "tsconfig.json")) {
            Set-Content -Path (Join-Path $targetDir "tsconfig.json") -Value '{"extends": "../../.nuxt/tsconfig.json"}' -Encoding utf8
        }
    } else {
        Write-Host "[INFO] Updating all modules in $modulesDir..." -ForegroundColor Cyan
        if (Test-Path $modulesDir) {
            Get-ChildItem -Directory $modulesDir | ForEach-Object {
                $dir = $_.FullName
                $mod = $_.Name
                if (Test-Path (Join-Path $dir ".git")) {
                    Write-Host "[UPDATE] Pulling latest changes for '$mod'..." -ForegroundColor Cyan
                    Push-Location $dir
                    try {
                        $branch = git branch --show-current 2>$null
                        if (-not [string]::IsNullOrWhiteSpace($branch)) {
                            git pull origin $branch
                        } else {
                            git pull
                        }
                    } finally {
                        Pop-Location
                    }

                    if (Test-Path (Join-Path $dir "tsconfig.json")) {
                        Set-Content -Path (Join-Path $dir "tsconfig.json") -Value '{"extends": "../../.nuxt/tsconfig.json"}' -Encoding utf8
                    }
                }
            }
        }
    }

    Write-Host "[INFO] Refreshing npm dependencies & Nuxt types..." -ForegroundColor Cyan
    cmd.exe /c "npm install"
    cmd.exe /c "npx nuxt prepare"

    Write-Host "[SUCCESS] Update process completed." -ForegroundColor Green
}
