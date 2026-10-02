function Show-NxMan {
    param(
        [string]$CliDir
    )

    $manFile = Join-Path $CliDir "man/nx.1"
    if (Test-Path $manFile) {
        $lines = Get-Content $manFile
        foreach ($line in $lines) {
            if ($line -match '^\.SH\s+(.*)') {
                Write-Host "`n$($matches[1])" -ForegroundColor Cyan
            } elseif ($line -match '^\.B\s+(.*)') {
                Write-Host "  $($matches[1])" -ForegroundColor Green
            } elseif ($line -match '^\.TP') {
                # paragraph break
            } elseif ($line -match '^\.\\"') {
                # comment
            } elseif ($line -match '^\.TH') {
                # title
            } else {
                $clean = $line -replace '\\f[IBRP]', '' -replace '\\-', '-'
                Write-Host "  $clean"
            }
        }
    } else {
        Write-Host "[ERROR] Manual page not found at $manFile" -ForegroundColor Red
    }
}
