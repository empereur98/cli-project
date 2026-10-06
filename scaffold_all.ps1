$mods = @(
    'risk-management',
    'transactions',
    'coins',
    'trading',
    'competitions',
    'mass-bonuses',
    'messaging',
    'commissions',
    'prop-trading',
    'audit-logs',
    'settings'
)

$CliLibDir = Join-Path (Get-Location) "nxt-cli"

. (Join-Path $CliLibDir "lib\ModuleCreator.ps1")

foreach ($m in $mods) {
    Write-Host "Creating module: $m"
    New-NxModule -ModuleName $m -CliDir $CliLibDir
}
