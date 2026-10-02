function Register-InNuxtConfig {
    param(
        [string]$ModulePath
    )

    $configFile = ".\nuxt.config.ts"
    if (-not (Test-Path $configFile)) {
        $configFile = ".\nuxt.config.js"
    }
    if (-not (Test-Path $configFile)) {
        $configFile = ".\nuxt.config.mjs"
    }

    if (Test-Path $configFile) {
        $content = Get-Content $configFile -Raw -Encoding utf8
        if ($content -notmatch [regex]::Escape($ModulePath)) {
            if ($content -match "modules:\s*\[") {
                $replacement = "modules: [`n    '$ModulePath',"
                $content = $content -replace "modules:\s*\[", $replacement
            } elseif ($content -match "defineNuxtConfig\(\{") {
                $replacement = "defineNuxtConfig({`n  modules: ['$ModulePath'],"
                $content = $content -replace "defineNuxtConfig\(\{", $replacement
            }
            Set-Content -Path $configFile -Value $content -Encoding utf8
        }
    }
}

function New-NxModule {
    param(
        [string]$ModuleName,
        [string]$CliDir
    )

    if ([string]::IsNullOrWhiteSpace($ModuleName)) {
        Write-Host "[ERROR] Module name is required." -ForegroundColor Red
        Write-Host "Usage: nx -m <module_name>"
        return
    }

    # Feature-Driven Development rule: must be run inside an existing Nuxt project
    $isInsideNuxt = (Test-Path ".\nuxt.config.ts") -or (Test-Path ".\nuxt.config.js") -or (Test-Path ".\nuxt.config.mjs")
    if (-not $isInsideNuxt) {
        Write-Host "[ERROR] Feature modules must be created inside an existing Nuxt project." -ForegroundColor Red
        Write-Host "[HINT] Navigate to your Nuxt project root (where nuxt.config.ts is located) or create one with:" -ForegroundColor Yellow
        Write-Host "  nx create <project_name>" -ForegroundColor White
        return
    }

    $configKey = $ModuleName -replace '-', '_'
    $modulesDir = ".\modules"
    if (-not (Test-Path $modulesDir)) {
        New-Item -ItemType Directory -Path $modulesDir -Force | Out-Null
    }

    $targetDir = Join-Path $modulesDir $ModuleName
    if (Test-Path $targetDir) {
        Write-Host "[ERROR] Directory '$targetDir' already exists. Aborting." -ForegroundColor Red
        return
    }

    Write-Host "[INFO] Scaffolding feature module '$ModuleName' in $targetDir..." -ForegroundColor Cyan

    $subdirs = @(
        "$targetDir\pages",
        "$targetDir\components",
        "$targetDir\composables",
        "$targetDir\services",
        "$targetDir\types",
        "$targetDir\stores"
    )
    foreach ($d in $subdirs) {
        New-Item -ItemType Directory -Path $d -Force | Out-Null
    }

    function Render-Template {
        param($src, $dest)
        if (Test-Path $src) {
            $c = Get-Content $src -Raw -Encoding utf8
            $c = $c -replace '\{\{MODULE_NAME\}\}', $ModuleName
            $c = $c -replace '\{\{CONFIG_KEY\}\}', $configKey
            Set-Content -Path $dest -Value $c -Encoding utf8
        }
    }

    # Nuxt Kit module definition: auto-registers components, composables, stores, and pages
    Render-Template "$CliDir\templates\index_ts.template" "$targetDir\index.ts"

    # Module subdirs templates & documentation
    Render-Template "$CliDir\templates\module_dirs\pages\index_vue.template" "$targetDir\pages\index.vue"
    Render-Template "$CliDir\templates\module_dirs\pages\README.md.template" "$targetDir\pages\README.md"

    Render-Template "$CliDir\templates\module_dirs\components\ExampleComponent.vue.template" "$targetDir\components\ExampleComponent.vue"
    Render-Template "$CliDir\templates\module_dirs\components\README.md.template" "$targetDir\components\README.md"

    Render-Template "$CliDir\templates\module_dirs\composables\useExample.ts.template" "$targetDir\composables\useExample.ts"
    Render-Template "$CliDir\templates\module_dirs\composables\README.md.template" "$targetDir\composables\README.md"

    Render-Template "$CliDir\templates\module_dirs\services\exampleService.ts.template" "$targetDir\services\exampleService.ts"
    Render-Template "$CliDir\templates\module_dirs\services\README.md.template" "$targetDir\services\README.md"

    Render-Template "$CliDir\templates\module_dirs\types\example.types.ts.template" "$targetDir\types\example.types.ts"
    Render-Template "$CliDir\templates\module_dirs\types\README.md.template" "$targetDir\types\README.md"

    Render-Template "$CliDir\templates\module_dirs\stores\exampleStore.ts.template" "$targetDir\stores\exampleStore.ts"
    Render-Template "$CliDir\templates\module_dirs\stores\README.md.template" "$targetDir\stores\README.md"

    # Auto-register module in nuxt.config.ts
    Register-InNuxtConfig "./modules/$ModuleName"

    # Sync into nx.config.json if file exists
    $nxConfigPath = ".\nx.config.json"
    if (Test-Path $nxConfigPath) {
        try {
            $json = Get-Content $nxConfigPath -Raw | ConvertFrom-Json
            if ($null -ne $json.modules) {
                $alreadyExists = $false
                foreach ($m in $json.modules) {
                    if ($m.name -eq $ModuleName) { $alreadyExists = $true; break }
                }
                if (-not $alreadyExists) {
                    $newMod = [PSCustomObject]@{
                        name = $ModuleName
                        type = "local"
                        path = "./modules/$ModuleName"
                    }
                    $list = [System.Collections.ArrayList]@($json.modules)
                    $list.Add($newMod) | Out-Null
                    $json.modules = $list
                    $json | ConvertTo-Json -Depth 5 | Set-Content $nxConfigPath -Encoding utf8
                }
            }
        } catch {}
    }

    # Refresh Nuxt TypeScript declarations at the project root
    Write-Host "[INFO] Refreshing Nuxt TypeScript declarations (nuxt prepare)..." -ForegroundColor Cyan
    cmd.exe /c "npx nuxt prepare"

    Write-Host ""
    Write-Host "[SUCCESS] Feature module '$ModuleName' created and connected to host project!" -ForegroundColor Green
    Write-Host "[INFO] Components, composables, stores, and pages are immediately available." -ForegroundColor Cyan
    Write-Host "  - Route : http://localhost:3000/$ModuleName" -ForegroundColor White
    Write-Host "  - Path  : ./modules/$ModuleName" -ForegroundColor White
    Write-Host ""
}

