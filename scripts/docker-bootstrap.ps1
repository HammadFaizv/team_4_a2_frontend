param(
    [switch]$Yes
)

$ErrorActionPreference = 'Stop'

function Invoke-DockerStep {
    param(
        [Parameter(Mandatory)]
        [string]$Description,

        [Parameter(Mandatory)]
        [string[]]$Arguments
    )

    Write-Host "`n==> $Description" -ForegroundColor Cyan
    & docker @Arguments

    if ($LASTEXITCODE -ne 0) {
        throw "$Description failed with exit code $LASTEXITCODE."
    }
}

$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot

if (-not $Yes) {
    Write-Warning 'The scale seed replaces all existing GigTask PostgreSQL data and the three GigTask MongoDB collections.'
    $confirmation = Read-Host 'Type SEED to continue'

    if ($confirmation -cne 'SEED') {
        Write-Host 'Cancelled; no Docker or database changes were made.'
        exit 0
    }
}

try {
    Invoke-DockerStep 'Building and starting Docker services' @('compose', 'up', '-d', '--build')
    Invoke-DockerStep 'Running backend migrations' @('compose', 'exec', '-T', 'backend', 'npm', 'run', 'migrate')
    Invoke-DockerStep 'Replacing data with the scale dataset' @('compose', 'exec', '-T', 'backend', 'npm', 'run', 'seed:scale')
    Invoke-DockerStep 'Showing service status' @('compose', 'ps')

    Write-Host "`nGigTask is ready at http://localhost:5173" -ForegroundColor Green
}
catch {
    Write-Error $_
    exit 1
}
