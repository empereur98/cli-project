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

    $targetDir = ""
    if (Test-Path ".\modules\$ModuleName") {
        $targetDir = ".\modules\$ModuleName"
    } elseif (Test-Path ".\$ModuleName") {
        $targetDir = ".\$ModuleName"
    } else {
        Write-Host "[ERROR] Module or model '$ModuleName' not found in .\modules\$ModuleName or .\$ModuleName." -ForegroundColor Red
        return
    }

    Write-Host "[INFO] Removing module '$ModuleName' from project..." -ForegroundColor Yellow

    # Unregister from nuxt.config.ts
    $nuxtConfig = ".\nuxt.config.ts"
    if (Test-Path $nuxtConfig) {
        $c = Get-Content $nuxtConfig -Raw -Encoding utf8
        $c = $c -replace "['`"]./modules/$ModuleName['`"],*", ""
        $c = $c -replace "['`"]~/modules/$ModuleName['`"],*", ""
        Set-Content -Path $nuxtConfig -Value $c -Encoding utf8
    }

    # Unregister from nx.config.json
    $nxConfigPath = ".\nx.config.json"
    if (Test-Path $nxConfigPath) {
        try {
            $json = Get-Content $nxConfigPath -Raw | ConvertFrom-Json
            if ($null -ne $json.modules) {
                $filtered = @($json.modules | Where-Object { $_.name -ne $ModuleName })
                $json.modules = $filtered
                $json | ConvertTo-Json -Depth 5 | Set-Content $nxConfigPath -Encoding utf8
            }
        } catch {}
    }

    # Delete physical directory
    Remove-Item -Path $targetDir -Recurse -Force
    Write-Host "[SUCCESS] Deleted directory $targetDir" -ForegroundColor Green

    # Refresh Nuxt types if inside a Nuxt project
    if ((Test-Path ".\nuxt.config.ts") -or (Test-Path ".\nuxt.config.js")) {
        Write-Host "[INFO] Refreshing Nuxt declarations..." -ForegroundColor Cyan
        cmd.exe /c "npx nuxt prepare"
    }

    Write-Host ""
    Write-Host "[SUCCESS] Module '$ModuleName' removed successfully from project." -ForegroundColor Green
    Write-Host ""
}
