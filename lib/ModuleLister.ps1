function Get-NxModuleRow {
    param(
        [string]$Dir
    )

    $modName = Split-Path -Leaf $Dir
    $version = ""
    $remote = ""
    $role = ""

    # 1. Version via git tag or package.json
    if (Test-Path (Join-Path $Dir ".git")) {
        $gitTag = git -C $Dir describe --tags --abbrev=0 2>$null
        if (-not $gitTag) {
            $gitTag = git -C $Dir tag 2>$null | Select-Object -Last 1
        }
        if ($gitTag) {
            $version = $gitTag
        }
    }

    $pkgJsonPath = Join-Path $Dir "package.json"
    if (-not $version -and (Test-Path $pkgJsonPath)) {
        try {
            $pkg = Get-Content $pkgJsonPath -Raw | ConvertFrom-Json
            if ($pkg.version) {
                $version = "v$($pkg.version)"
            }
        } catch {}
    }
    if (-not $version) { $version = "v1.0.0" }

    # 2. Remote repository
    if (Test-Path (Join-Path $Dir ".git")) {
        $remote = git -C $Dir config --get remote.origin.url 2>$null
    }

    if (-not $remote -and (Test-Path ".\nx.config.json")) {
        try {
            $nxConfig = Get-Content ".\nx.config.json" -Raw | ConvertFrom-Json
            $found = $nxConfig.modules | Where-Object { $_.name -eq $modName } | Select-Object -First 1
            if ($found -and $found.repository) {
                $remote = $found.repository
            }
        } catch {}
    }
    if (-not $remote) { $remote = "Local" }

    # 3. Usage / Role
    if (Test-Path $pkgJsonPath) {
        try {
            $pkg = Get-Content $pkgJsonPath -Raw | ConvertFrom-Json
            if ($pkg.description) {
                $role = $pkg.description
            }
        } catch {}
    }

    $readmePath = Join-Path $Dir "README.md"
    if (-not $role -and (Test-Path $readmePath)) {
        $firstLines = Get-Content $readmePath -TotalCount 5 2>$null
        foreach ($l in $firstLines) {
            if ($l -notmatch '^#' -and $l.Trim().Length -gt 0) {
                $role = $l.Trim()
                break
            }
        }
    }
    if (-not $role) { $role = "Module autonome" }

    return [PSCustomObject]@{
        ModuleName = $modName
        Version    = $version
        Repository = $remote
        Role       = $role
    }
}

function Show-NxModules {
    $modulesDir = ""
    if (Test-Path ".\modules") {
        $modulesDir = ".\modules"
    } elseif ((Split-Path -Leaf (Get-Location).Path) -eq "modules") {
        $modulesDir = "."
    } elseif (Test-Path "..\modules") {
        $modulesDir = "..\modules"
    }

    $moduleList = [System.Collections.Generic.List[PSCustomObject]]::new()

    if ($modulesDir -and (Test-Path $modulesDir)) {
        Get-ChildItem -Directory $modulesDir | ForEach-Object {
            $name = $_.Name
            if ($name -ne "node_modules" -and $name -ne ".git" -and $name -ne "nxt-cli") {
                $moduleList.Add((Get-NxModuleRow -Dir $_.FullName))
            }
        }
    }

    if ((Test-Path ".\nuxt.config.ts") -or (Test-Path ".\nuxt.config.js")) {
        Get-ChildItem -Directory ".\" | ForEach-Object {
            $name = $_.Name
            if ($name -ne "modules" -and $name -ne "nxt-cli" -and $name -ne "node_modules" -and $name -ne ".git" -and $name -ne "app" -and $name -ne "public" -and $name -ne "server") {
                if ((Test-Path (Join-Path $_.FullName "index.ts")) -and (Test-Path (Join-Path $_.FullName "package.json"))) {
                    $exists = $false
                    foreach ($m in $moduleList) { if ($m.ModuleName -eq $name) { $exists = $true; break } }
                    if (-not $exists) {
                        $moduleList.Add((Get-NxModuleRow -Dir $_.FullName))
                    }
                }
            }
        }
    }

    Write-Host "`nINSTALLED NUXT MODULES" -ForegroundColor White
    Write-Host ("-" * 85)

    if ($moduleList.Count -gt 0) {
        $moduleList | Format-Table -Property @{Label="NOM DU MODULE"; Expression={$_.ModuleName}}, @{Label="VERSION"; Expression={$_.Version}}, @{Label="DEPOT DISTANT"; Expression={$_.Repository}}, @{Label="USAGE / ROLE"; Expression={$_.Role}} -AutoSize
    } else {
        Write-Host "Aucun module trouvé." -ForegroundColor Gray
    }

    Write-Host ("-" * 85)
    Write-Host "Total: " -NoNewline
    Write-Host "$($moduleList.Count)" -ForegroundColor Green -NoNewline
    Write-Host " module(s) installé(s).`n"
}
