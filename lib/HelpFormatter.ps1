function Show-NxHelp {
    Write-Host "NX - Autonomous Nuxt Module & Project Scaffolder" -ForegroundColor White
    Write-Host "Usage:" -ForegroundColor Cyan
    Write-Host "  nx <command> [options] [args]  ou  .\nx.ps1 <command> [options] [args]"
    Write-Host ""
    Write-Host "Commands:" -ForegroundColor Cyan
    Write-Host "  create <project_name>        Scaffold new Nuxt project with Tailwind & embedded ./nx" -ForegroundColor Green
    Write-Host "  -m, --module <name>          Scaffold local feature module in ./modules/ (must run in project)" -ForegroundColor Green
    Write-Host "  -d, --delete <name>          Remove module or model from main project" -ForegroundColor Green
    Write-Host "  --init, init                 Initialize global 'nx' CLI in system/user PATH" -ForegroundColor Green
    Write-Host "  -i, --import [url|name]      Import module(s) from nx.config.json or GitHub URL" -ForegroundColor Green
    Write-Host "  -u, --update [name]          Pull latest Git changes for a module or all modules" -ForegroundColor Green
    Write-Host "  -p, --push <name> [msg]      Stage, commit, and push module changes to remote Git" -ForegroundColor Green
    Write-Host "  -l, --list                   List all installed modules with version, repo, and role" -ForegroundColor Green
    Write-Host "  man, --man                   Open the manual documentation page" -ForegroundColor Green
    Write-Host "  -h, --help                   Display this help message and exit" -ForegroundColor Green
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Cyan
    Write-Host "  nx --init"
    Write-Host "  nx create trading-frontend"
    Write-Host "  nx -m trading-auth"
    Write-Host "  nx -m trading-auth -d"
    Write-Host "  nx -d trading-auth"
    Write-Host "  nx -i https://github.com/my-org/trading-auth.git"
    Write-Host "  nx -u trading-auth"
    Write-Host "  nx -l"
    Write-Host "  nx man"
    Write-Host ""
}
