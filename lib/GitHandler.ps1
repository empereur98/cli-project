function Setup-Git {
    param(
        [string]$TargetDir,
        [string]$GitignoreTemplate
    )

    if (Test-Path $GitignoreTemplate) {
        Copy-Item -Path $GitignoreTemplate -Destination (Join-Path $TargetDir ".gitignore") -Force
    }

    # Verify if interactive host
    if (-not [Environment]::UserInteractive) {
        Write-Host "[GIT] Non-interactive mode detected. Skipping git initialization."
        return
    }

    Write-Host ""
    $useGit = Read-Host "Do you want to initialize Git in this module? [y/N]"
    if ($useGit -match '^(y|yes)$') {
        $branchName = Read-Host "Enter main branch name [default: main]"
        if ([string]::IsNullOrWhiteSpace($branchName)) {
            $branchName = "main"
        }

        $remoteUrl = Read-Host "Enter GitHub remote repository URL (optional)"

        Write-Host "[GIT] Initializing repository on branch '$branchName'..." -ForegroundColor Cyan
        Push-Location $TargetDir
        try {
            git init -b $branchName 2>$null
            if ($LASTEXITCODE -ne 0) {
                git init 2>$null
            }
            if (-not [string]::IsNullOrWhiteSpace($remoteUrl)) {
                git remote add origin $remoteUrl 2>$null
                Write-Host "[GIT] Remote origin set to $remoteUrl" -ForegroundColor Green
            }
        }
        finally {
            Pop-Location
        }
    } else {
        Write-Host "[GIT] Git initialization skipped."
    }
}

function Test-RepoExists {
    param(
        [string]$RepoUrl
    )

    if ([string]::IsNullOrWhiteSpace($RepoUrl)) {
        return $false
    }

    git ls-remote $RepoUrl HEAD 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        return $true
    }

    git ls-remote $RepoUrl 2>$null | Out-Null
    return ($LASTEXITCODE -eq 0)
}
