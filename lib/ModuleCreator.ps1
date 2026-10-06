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
        if ($content -match "getDiscoveredModules") {
            # Auto-discovery takes care of registering it dynamically
            return
        }
        if ($content -notmatch [regex]::Escape($ModulePath)) {
            if ($content -match "modules:\s*\[") {
                $replacement = "modules: [`n    '$ModulePath',"
                $content = $content -replace "modules:\s*\[", $replacement
            } elseif ($content -match "defineNuxtConfig\(\{") {
                $replacement = "defineNuxtConfig({`n  modules: ['$ModulePath'],"
                $content = $content -replace "defineNuxtConfig\(\{", $replacement
            }
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            $resolvedPath = if ([System.IO.Path]::IsPathRooted($configFile)) { $configFile } else { Join-Path (Get-Location).Path $configFile }
            [System.IO.File]::WriteAllText($resolvedPath, $content, $utf8NoBom)
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
        Write-Host "Usage: nx -m <module_name>" -ForegroundColor Yellow
        return
    }

    # Normalize name (strips easy-trade-module- or *-module- prefix if typed)
    $ModuleName = $ModuleName -replace '^[A-Za-z0-9_.-]+-module-', '' -replace '^easy-trade-', ''

    $isInsideNuxt = (Test-Path ".\nuxt.config.ts") -or (Test-Path ".\nuxt.config.js") -or (Test-Path ".\nuxt.config.mjs")
    $configKey = $ModuleName -replace '-', '_'
    
    if ($isInsideNuxt) {
        $modulesDir = ".\modules"
        if (-not (Test-Path $modulesDir)) {
            New-Item -ItemType Directory -Path $modulesDir -Force | Out-Null
        }
        $targetDir = Join-Path $modulesDir $ModuleName
    } else {
        $targetDir = Join-Path (Get-Location).Path $ModuleName
    }

    if (Test-Path $targetDir) {
        Write-Host "[ERROR] Directory '$targetDir' already exists. Aborting." -ForegroundColor Red
        return
    }

    $pascalName = ($ModuleName -split '-' | ForEach-Object { if ($_.Length -gt 0) { $_.Substring(0,1).ToUpper() + $_.Substring(1) } else { "" } }) -join ''
    $camelName = if ($pascalName.Length -gt 0) { $pascalName.Substring(0,1).ToLower() + $pascalName.Substring(1) } else { "" }

    function Render-Template {
        param($src, $dest)
        if (Test-Path $src) {
            $c = Get-Content $src -Raw -Encoding utf8
            $c = $c -replace '\{\{MODULE_NAME\}\}', $ModuleName
            $c = $c -replace '\{\{CONFIG_KEY\}\}', $configKey
            $c = $c -replace '\{\{PASCAL_NAME\}\}', $pascalName
            $c = $c -replace '\{\{CAMEL_NAME\}\}', $camelName
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            $resolvedDest = if ([System.IO.Path]::IsPathRooted($dest)) { $dest } else { Join-Path (Get-Location).Path $dest }
            [System.IO.File]::WriteAllText($resolvedDest, $c, $utf8NoBom)
        }
    }

    Write-Host "[INFO] Scaffolding complete module '$ModuleName' in $targetDir..." -ForegroundColor Cyan

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

    # 1. Runtime Nuxt Kit definition (consumed by host projects)
    Render-Template "$CliDir\templates\index_ts.template" "$targetDir\index.ts"

    # 2. Module manifest (for sidebar navigation & metadata)
    if (Test-Path "$CliDir\templates\module_json.template") {
        Render-Template "$CliDir\templates\module_json.template" "$targetDir\module.json"
    }

    # 3. Module subdirs templates & documentation
    Render-Template "$CliDir\templates\module_dirs\pages\index_vue.template" "$targetDir\pages\index.vue"
    Render-Template "$CliDir\templates\module_dirs\pages\README.md.template" "$targetDir\pages\README.md"

    Render-Template "$CliDir\templates\module_dirs\components\ExampleComponent.vue.template" "$targetDir\components\${pascalName}Component.vue"
    Render-Template "$CliDir\templates\module_dirs\components\README.md.template" "$targetDir\components\README.md"

    Render-Template "$CliDir\templates\module_dirs\composables\useExample.ts.template" "$targetDir\composables\use${pascalName}.ts"
    Render-Template "$CliDir\templates\module_dirs\composables\README.md.template" "$targetDir\composables\README.md"

    Render-Template "$CliDir\templates\module_dirs\services\exampleService.ts.template" "$targetDir\services\${camelName}Service.ts"
    Render-Template "$CliDir\templates\module_dirs\services\README.md.template" "$targetDir\services\README.md"

    Render-Template "$CliDir\templates\module_dirs\types\example.types.ts.template" "$targetDir\types\${camelName}.types.ts"
    Render-Template "$CliDir\templates\module_dirs\types\README.md.template" "$targetDir\types\README.md"

    Render-Template "$CliDir\templates\module_dirs\stores\exampleStore.ts.template" "$targetDir\stores\${camelName}Store.ts"
    Render-Template "$CliDir\templates\module_dirs\stores\README.md.template" "$targetDir\stores\README.md"

    # 4. Configuration & Git files
    Render-Template "$CliDir\templates\standalone\package_json.template" "$targetDir\package.json"
    Render-Template "$CliDir\templates\standalone\README.md.template" "$targetDir\README.md"
    Copy-Item "$CliDir\templates\gitignore.template" "$targetDir\.gitignore" -Force
    Render-Template "$CliDir\templates\standalone\tsconfig_json.template" "$targetDir\tsconfig.json"

    # 5. Host project registration
    if ($isInsideNuxt) {
        Register-InNuxtConfig "./modules/$ModuleName"
        $nxConfigPath = ".\nx.config.json"
        if (Test-Path $nxConfigPath) {
            try {
                $json = Get-Content $nxConfigPath -Raw | ConvertFrom-Json
                if ($null -ne $json.modules) {
                    $exists = $false
                    foreach ($m in $json.modules) { if ($m.name -eq $ModuleName) { $exists = $true; break } }
                    if (-not $exists) {
                        $newMod = [PSCustomObject]@{ name = $ModuleName; type = "autonomous"; path = "./modules/$ModuleName" }
                        $list = [System.Collections.ArrayList]@($json.modules)
                        $list.Add($newMod) | Out-Null
                        $json.modules = $list
                        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
                        $resolvedNx = if ([System.IO.Path]::IsPathRooted($nxConfigPath)) { $nxConfigPath } else { Join-Path (Get-Location).Path $nxConfigPath }
                        [System.IO.File]::WriteAllText($resolvedNx, ($json | ConvertTo-Json -Depth 5), $utf8NoBom)
                    }
                }
            } catch {}
        }
    }

    # 6. Refresh Nuxt types
    Write-Host "[INFO] Refreshing Nuxt TypeScript declarations (nuxt prepare)..." -ForegroundColor Cyan
    cmd.exe /c "npx nuxt prepare"

    Write-Host ""
    Write-Host "[SUCCESS] Module '$ModuleName' created successfully in $targetDir!" -ForegroundColor Green
    Write-Host "  - Route locale  : http://localhost:3000/$ModuleName" -ForegroundColor White
    Write-Host "  - Dossier local : ./modules/$ModuleName" -ForegroundColor White
    Write-Host ""
}

