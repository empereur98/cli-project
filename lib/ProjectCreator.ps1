function New-NxProject {
    param(
        [string]$ProjectName,
        [string]$CliDir
    )

    if ([string]::IsNullOrWhiteSpace($ProjectName)) {
        Write-Host "[ERROR] Project name is required." -ForegroundColor Red
        Write-Host "Usage: nx create <project_name>"
        return
    }

    $currentLocation = (Get-Location).Path
    $targetDir = Join-Path $currentLocation $ProjectName

    if (Test-Path $targetDir) {
        Write-Host "[ERROR] Directory '$targetDir' already exists. Aborting." -ForegroundColor Red
        return
    }

    Write-Host "[INFO] Creating Nuxt project '$ProjectName' in: $targetDir" -ForegroundColor Cyan


    $configKey = $ProjectName -replace '-', '_'

    $subdirs = @(
        "$targetDir\app\pages",
        "$targetDir\app\components",
        "$targetDir\app\composables",
        "$targetDir\app\services",
        "$targetDir\app\types",
        "$targetDir\app\stores",
        "$targetDir\modules"
    )
    foreach ($d in $subdirs) {
        New-Item -ItemType Directory -Path $d -Force | Out-Null
    }

    # Template replacements helper
    function Render-Template {
        param($src, $dest)
        if (Test-Path $src) {
            $c = Get-Content $src -Raw -Encoding utf8
            $c = $c -replace '\{\{MODULE_NAME\}\}', $ProjectName
            $c = $c -replace '\{\{CONFIG_KEY\}\}', $configKey
            $c = $c -replace '\{\{PROJECT_NAME\}\}', $ProjectName
            Set-Content -Path $dest -Value $c -Encoding utf8
        }
    }

    Render-Template "$CliDir\templates\package_json.template" "$targetDir\package.json"
    
    if (Test-Path "$CliDir\templates\nuxt_config_project.template") {
        Copy-Item "$CliDir\templates\nuxt_config_project.template" "$targetDir\nuxt.config.ts" -Force
    } else {
        Copy-Item "$CliDir\templates\nuxt_config.template" "$targetDir\nuxt.config.ts" -Force
    }

    Set-Content -Path "$targetDir\tsconfig.json" -Value '{"extends": "./.nuxt/tsconfig.json"}' -Encoding utf8
    Copy-Item "$CliDir\templates\gitignore.template" "$targetDir\.gitignore" -Force

    Render-Template "$CliDir\templates\nx_config_json.template" "$targetDir\nx.config.json"

    if (Test-Path "$CliDir\templates\app_vue_project.template") {
        Copy-Item "$CliDir\templates\app_vue_project.template" "$targetDir\app\app.vue" -Force
    } else {
        Render-Template "$CliDir\templates\app_vue.template" "$targetDir\app\app.vue"
    }

    # Scaffold predefined app directories
    Render-Template "$CliDir\templates\module_dirs\pages\index_vue.template" "$targetDir\app\pages\index.vue"
    Render-Template "$CliDir\templates\module_dirs\pages\README.md.template" "$targetDir\app\pages\README.md"

    Render-Template "$CliDir\templates\module_dirs\components\ExampleComponent.vue.template" "$targetDir\app\components\ExampleComponent.vue"
    Render-Template "$CliDir\templates\module_dirs\components\README.md.template" "$targetDir\app\components\README.md"

    Render-Template "$CliDir\templates\module_dirs\composables\useExample.ts.template" "$targetDir\app\composables\useExample.ts"
    Render-Template "$CliDir\templates\module_dirs\composables\README.md.template" "$targetDir\app\composables\README.md"

    Render-Template "$CliDir\templates\module_dirs\services\exampleService.ts.template" "$targetDir\app\services\exampleService.ts"
    Render-Template "$CliDir\templates\module_dirs\services\README.md.template" "$targetDir\app\services\README.md"

    Render-Template "$CliDir\templates\module_dirs\types\example.types.ts.template" "$targetDir\app\types\example.types.ts"
    Render-Template "$CliDir\templates\module_dirs\types\README.md.template" "$targetDir\app\types\README.md"

    Render-Template "$CliDir\templates\module_dirs\stores\exampleStore.ts.template" "$targetDir\app\stores\exampleStore.ts"
    Render-Template "$CliDir\templates\module_dirs\stores\README.md.template" "$targetDir\app\stores\README.md"

    # Tailwind
    Setup-Tailwind $targetDir

    # Embed ./nx wrapper & nxt-cli directory
    Copy-Item $CliDir "$targetDir\nxt-cli" -Recurse -Force
    Copy-Item "$CliDir\nx" "$targetDir\nx" -Force
    Copy-Item "$CliDir\nx.cmd" "$targetDir\nx.cmd" -Force
    Copy-Item "$CliDir\nx.ps1" "$targetDir\nx.ps1" -Force

    # Git init
    Setup-Git $targetDir "$CliDir\templates\gitignore.template"

    # Install dependencies & prepare
    Write-Host "[INFO] Installing dependencies for '$ProjectName'..." -ForegroundColor Cyan
    Push-Location $targetDir
    try {
        cmd.exe /c "npm install"
        cmd.exe /c "npx nuxt prepare"
    } finally {
        Pop-Location
    }

    Write-Host ""
    Write-Host "[SUCCESS] Nuxt project '$ProjectName' created with embedded ./nx wrapper." -ForegroundColor Green
    Write-Host "[NEXT STEPS]" -ForegroundColor Cyan
    Write-Host "  cd $targetDir" -ForegroundColor White
    Write-Host "  npm run dev" -ForegroundColor White
    Write-Host ""
}
