function Invoke-WithProgress {
    param(
        [string]$Message,
        [scriptblock]$ScriptBlock
    )

    $width = 25
    Write-Host -NoNewline "[PROGRESS] $Message... " -ForegroundColor Blue

    $job = Start-Job -ScriptBlock $ScriptBlock
    $step = 0

    while ($job.State -eq 'Running') {
        $step++
        if ($step -le 50) {
            $percent = $step
        } elseif ($step -le 150) {
            $percent = [math]::Floor(50 + ($step - 50) / 3)
        } else {
            $percent = [math]::Floor(83 + ($step - 150) / 10)
        }
        if ($percent -gt 92) { $percent = 92 }

        $filled = [math]::Floor(($percent * $width) / 100)
        $empty = $width - $filled
        $bar = ("█" * $filled) + ("░" * $empty)

        Write-Host -NoNewline "`r[PROGRESS] $Message... " -ForegroundColor Blue
        Write-Host -NoNewline "[$bar] " -ForegroundColor Cyan
        Write-Host -NoNewline ("{0,3}%" -f $percent) -ForegroundColor Yellow
        Start-Sleep -Milliseconds 400
    }

    $output = Receive-Job -Job $job -Keep
    $jobState = $job.State
    Remove-Job -Job $job -Force

    if ($jobState -eq 'Completed' -and -not $job.ChildJobs[0].Error) {
        $bar = "█" * $width
        Write-Host "`r[PROGRESS] $Message... [$bar] 100% [SUCCÈS]     " -ForegroundColor Green
        return $true
    } else {
        Write-Host "`r[PROGRESS] $Message... [ÉCHEC]                       " -ForegroundColor Red
        if ($job.ChildJobs[0].Error) {
            Write-Host "Error details:" -ForegroundColor Red
            $job.ChildJobs[0].Error | ForEach-Object { Write-Host $_ -ForegroundColor Red }
        }
        return $false
    }
}
