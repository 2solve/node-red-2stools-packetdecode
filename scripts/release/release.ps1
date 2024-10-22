# Logging function
function Log {
    param([string]$message)
    Write-Output "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $message"
}

Log "STARTING RELEASE PROCESS"

# STEP 1: Switching to develop branch
Log "STEP 1: Switching to develop branch"
$stdout = git checkout develop 2>&1
if ($LASTEXITCODE -ne 0) {
    Log "ERROR: Failed to switch to develop branch"
    Write-Error $stdout
    exit 1
}

# STEP 2: Getting the new version from Commitizen
Log "STEP 2: Getting the new version from Commitizen"
$cz_new_version = & cz bump --dry-run --yes | Select-String 'tag to create:' | ForEach-Object { $_.ToString().Split(' ')[3] } 
if ([string]::IsNullOrEmpty($cz_new_version)) {
    Log "ERROR: Failed to get new version from Commitizen"
    exit 1
}
Log "New version to be released: $cz_new_version"

# STEP 3: Starting git flow release with version $cz_new_version
Log "STEP 3: Starting git flow release with version $cz_new_version"
$stdout = git flow release start $cz_new_version 2>&1
if ($LASTEXITCODE -ne 0) {
    Log "ERROR: Failed to start git flow release"
    Write-Error $stdout
    exit 1
}

# STEP 4: Bumping the version using Commitizen
Log "STEP 4: Bumping the version using Commitizen"
$stdout = cz bump --yes 2>&1
if ($LASTEXITCODE -ne 0) {
    Log "ERROR: Failed to bump version using Commitizen"
    Write-Error $stdout
    exit 1
}

# STEP 5: Generating changelog incrementally
Log "STEP 5: Generating changelog incrementally"
$stdout = cz changelog --incremental 2>&1
if ($LASTEXITCODE -ne 0) {
    Log "ERROR: Failed to generate changelog incrementally"
    Write-Error $stdout
    exit 1
}

Log "Please review the CHANGELOG.md file, make any necessary edits and save the file."
$null = Read-Host -Prompt "Press [Enter] to continue"

# STEP 6: Adding CHANGELOG.md to git
Log "STEP 6: Adding CHANGELOG.md to git"
$stdout = git add CHANGELOG.md 2>&1
if ($LASTEXITCODE -ne 0) {
    Log "ERROR: Failed to add CHANGELOG.md to git"
    Write-Error $stdout
    exit 1
}

# STEP 7: Committing the updated changelog
Log "STEP 7: Committing the updated changelog"
$stdout = git commit -m "docs(changelog): updating changelog with changes of current release

auto generating changelog incrementally using commitizen" 2>&1
if ($LASTEXITCODE -ne 0) {
    Log "ERROR: Failed to commit updated changelog"
    Write-Error $stdout
    exit 1
}

# STEP 8: Creating a temporary changelog for release finish
Log "STEP 8: Creating a temporary changelog for release finish"
$stdout = cz ch $cz_new_version --dry-run |
    ForEach-Object { $_ -replace '^(#+)\s*', '' -replace '^-\s*', "`t - " } |
    Out-File -FilePath tag-message.txt -Encoding utf8 2>&1
if ($LASTEXITCODE -ne 0) {
    Log "ERROR: Failed to create temporary changelog"
    Write-Error $stdout
    exit 1
}

Log "Please review the tag-message.txt file, make any necessary edits and save the file."
$null = Read-Host -Prompt "Press [Enter] to continue"

# STEP 9: Deleting the tag to prevent conflicts
Log "STEP 9: Deleting the tag to prevent conflicts"
$stdout = git tag -d $cz_new_version 2>&1
if ($LASTEXITCODE -ne 0) {
    Log "ERROR: Failed to delete tag"
    Write-Error $stdout
    exit 1
}

# STEP 10: Setting GIT_MERGE_AUTOEDIT to no to prevent merge messages
Log "STEP 10: Setting GIT_MERGE_AUTOEDIT to no to prevent merge messages"
$env:GIT_MERGE_AUTOEDIT = "no"

# STEP 11: Finishing the git flow release
Log "STEP 11: Finishing the git flow release"
$stdout = git flow release finish -f tag-message.txt "$cz_new_version" 2>&1
if ($LASTEXITCODE -ne 0) {
    Log "ERROR: Failed to finish git flow release"
    Write-Error $stdout
    Remove-Item tag-message.txt
    $env:GIT_MERGE_AUTOEDIT = ""
    exit 1
}

# STEP 12: Unsetting GIT_MERGE_AUTOEDIT
Log "STEP 12: Unsetting GIT_MERGE_AUTOEDIT"
$env:GIT_MERGE_AUTOEDIT = ""

# STEP 13: Cleaning up temporary changelog
Log "STEP 13: Cleaning up temporary changelog"
Remove-Item tag-message.txt

Log "RELEASE PROCESS COMPLETED SUCCESSFULLY"
