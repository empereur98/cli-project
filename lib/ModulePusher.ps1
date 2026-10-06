function Push-NxModule {
    param(
        [string]$ModuleName,
        [string]$CommitMessage,
        [string]$Branch
    )

    if ([string]::IsNullOrWhiteSpace($ModuleName)) {
        Write-Host "[ERROR] Module name is required." -ForegroundColor Red
        Write-Host "Usage: nx -p <module_name> [commit_message] [branch]  OR  nx push <module_name> [message]" -ForegroundColor Yellow
        return
    }

    # Normalize module name (strips easy-trade-module- or *-module- prefix)
    $cleanName = $ModuleName -replace '^[A-Za-z0-9_.-]+-module-', '' -replace '^easy-trade-', ''
    $targetDir = ""

    if (Test-Path ".\modules\$cleanName") {
        $targetDir = ".\modules\$cleanName"
    } elseif (Test-Path ".\modules\$ModuleName") {
        $targetDir = ".\modules\$ModuleName"
    } elseif (Test-Path ".\$cleanName") {
        $targetDir = ".\$cleanName"
    } elseif (Test-Path ".\$ModuleName") {
        $targetDir = ".\$ModuleName"
    } else {
        Write-Host "[ERROR] Module '$ModuleName' not found in .\modules\$cleanName or .\modules\$ModuleName." -ForegroundColor Red
        return
    }

    if (-not (Test-Path (Join-Path $targetDir ".git"))) {
        Write-Host "[ERROR] Module directory '$targetDir' is not an initialized Git repository. Cannot push." -ForegroundColor Red
        Write-Host "[HINT] Make sure this module was cloned from a Git repository or initialized with git init." -ForegroundColor Yellow
        return
    }

    $msg = if ([string]::IsNullOrWhiteSpace($CommitMessage)) { "feat: update $cleanName module" } else { $CommitMessage }

    Write-Host "[INFO] Staging, committing and pushing module '$cleanName' from $targetDir..." -ForegroundColor Cyan
    Push-Location $targetDir
    try {
        git add .
        $changes = git status --porcelain 2>$null
        if ($changes) {
            git commit -m $msg
            Write-Host "[GIT] Committed changes: '$msg'" -ForegroundColor Green
        } else {
            Write-Host "[INFO] Working tree clean. Pushing existing commits..." -ForegroundColor Yellow
        }

        $targetBranch = if ([string]::IsNullOrWhiteSpace($Branch)) {
            $currBranch = git branch --show-current 2>$null
            if (-not [string]::IsNullOrWhiteSpace($currBranch)) { $currBranch } else { "main" }
        } else {
            $Branch
        }

        Write-Host "[INFO] Pushing to remote repository on branch '$targetBranch'..." -ForegroundColor Cyan
        git push origin $targetBranch
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "[SUCCESS] Module '$cleanName' pushed successfully to remote repository (origin/$targetBranch)!" -ForegroundColor Green
            Write-Host ""
        } else {
            Write-Host "[ERROR] git push failed for module '$cleanName'. Check remote permissions or run git status inside $targetDir." -ForegroundColor Red
        }
    } finally {
        Pop-Location
    }
}
