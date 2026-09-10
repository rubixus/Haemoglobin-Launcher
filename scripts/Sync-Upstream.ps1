# Sync Prism upstream into Haemoglobin fork without losing custom edits.
# Usage:
#   .\scripts\Sync-Upstream.ps1
#   .\scripts\Sync-Upstream.ps1 -Push
param([switch]$Push)

$ErrorActionPreference = "Stop"
$Git = "C:\Program Files\Git\cmd\git.exe"
if (-not (Test-Path $Git)) { $Git = "git" }

function Run-Git([string[]]$GitArgs) {
    Write-Host "> git $($GitArgs -join ' ')" -ForegroundColor Cyan
    & $Git @GitArgs
    if ($LASTEXITCODE -ne 0) { throw "git $($GitArgs -join ' ') failed with exit $LASTEXITCODE" }
}

$branch = (& $Git branch --show-current).Trim()
Write-Host "Starting branch: $branch"

# 1. Fetch upstream
Run-Git @("fetch", "upstream", "--prune")
Run-Git @("submodule", "update", "--init", "--recursive")

# 2. Fast-forward pristine develop (fails if develop has custom commits — intentional)
Run-Git @("checkout", "develop")
try {
    Run-Git @("merge", "--ff-only", "upstream/develop")
    Write-Host "develop fast-forwarded to upstream/develop" -ForegroundColor Green
} catch {
    Write-Host "" 
    Write-Host "develop has diverged (you probably committed custom code to develop)." -ForegroundColor Red
    Write-Host "Fix: move those commits to main, then reset develop to upstream/develop." -ForegroundColor Yellow
    Write-Host "  git checkout main" 
    Write-Host "  git cherry-pick develop..HEAD  # repeat as needed (check with git log develop..HEAD on develop)"
    Write-Host "  git checkout develop; git reset --hard upstream/develop"
    throw $_
}

# 3. Merge develop into main (preserves your edits; may conflict on same-line changes)
Run-Git @("checkout", "main")
try {
    Run-Git @("merge", "--no-edit", "develop")
    Write-Host "main merged with develop cleanly." -ForegroundColor Green
} catch {
    Write-Host ""
    Write-Host "Merge conflicts — your edits were NOT overwritten." -ForegroundColor Yellow
    Write-Host "Resolve with: git status, edit files, git add <files>, git commit" -ForegroundColor Yellow
    throw $_
}

Run-Git @("submodule", "update", "--init", "--recursive")

if ($Push) {
    Run-Git @("push", "origin", "develop")
    Run-Git @("push", "origin", "main")
    Write-Host "Pushed develop + main to origin." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "Done. Review with: git log --oneline --graph -15 main develop upstream/develop" -ForegroundColor Cyan
    Write-Host "Push when ready: .\scripts\Sync-Upstream.ps1 -Push  (or: git push origin develop main)"
}

if ($branch -ne "develop" -and $branch -ne "main") {
    Write-Host "Note: you started on '$branch', now on 'main'. Switch back if needed."
}
