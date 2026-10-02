$allArgs = $args


$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# If running inside a generated project, locate nxt-cli subfolder if present
if (Test-Path (Join-Path $ScriptDir "nxt-cli")) {
    $CliLibDir = Join-Path $ScriptDir "nxt-cli"
} else {
    $CliLibDir = $ScriptDir
}

# Source PowerShell modules
. (Join-Path $CliLibDir "lib\HelpFormatter.ps1")
. (Join-Path $CliLibDir "lib\ManViewer.ps1")
. (Join-Path $CliLibDir "lib\GitHandler.ps1")
. (Join-Path $CliLibDir "lib\TailwindInstaller.ps1")
. (Join-Path $CliLibDir "lib\ProgressBar.ps1")
. (Join-Path $CliLibDir "lib\ProjectCreator.ps1")
. (Join-Path $CliLibDir "lib\ModuleCreator.ps1")
. (Join-Path $CliLibDir "lib\ModuleImporter.ps1")
. (Join-Path $CliLibDir "lib\ModuleUpdater.ps1")
. (Join-Path $CliLibDir "lib\ModuleLister.ps1")
. (Join-Path $CliLibDir "lib\ModuleRemover.ps1")
. (Join-Path $CliLibDir "lib\CliInitializer.ps1")

if ($allArgs.Length -eq 0) {
    Show-NxHelp
    exit 0
}

$first = $allArgs[0]
$second = if ($allArgs.Length -gt 1) { $allArgs[1] } else { "" }
$third = if ($allArgs.Length -gt 2) { $allArgs[2] } else { "" }
$fourth = if ($allArgs.Length -gt 3) { $allArgs[3] } else { "" }

switch ($first) {
    { $_ -in "-h", "--help" } {
        Show-NxHelp
        break
    }
    { $_ -in "man", "--man" } {
        Show-NxMan -CliDir $CliLibDir
        break
    }
    { $_ -in "init", "--init" } {
        Initialize-NxCli -CliDir $CliLibDir
        break
    }
    { $_ -in "-d", "--delete", "remove" } {
        Remove-NxModule -ModuleName $second -CliDir $CliLibDir
        break
    }
    "create" {
        New-NxProject -ProjectName $second -CliDir $CliLibDir
        break
    }
    { $_ -in "-m", "--module" } {
        if ($third -in "-d", "--delete") {
            Remove-NxModule -ModuleName $second -CliDir $CliLibDir
        } elseif ($second -in "-d", "--delete") {
            Remove-NxModule -ModuleName $third -CliDir $CliLibDir
        } else {
            New-NxModule -ModuleName $second -CliDir $CliLibDir
        }
        break
    }
    { $_ -in "-i", "--import" } {
        if ($third -in "-d", "--delete") {
            Remove-NxModule -ModuleName $second -CliDir $CliLibDir
        } else {
            $branch = if ($fourth) { $fourth } else { "main" }
            Import-NxModule -RepoUrl $second -TargetName $third -CliDir $CliLibDir -Branch $branch
        }
        break
    }
    { $_ -in "-u", "--update" } {
        Update-NxModule -ModuleName $second
        break
    }
    { $_ -in "-l", "--list" } {
        Show-NxModules
        break
    }
    default {
        Write-Host "[ERROR] Unknown command or option '$first'." -ForegroundColor Red
        Write-Host "Run 'nx --help' for usage."
        exit 1
    }
}
