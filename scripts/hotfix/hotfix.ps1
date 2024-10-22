# Logging function
function Log {
    param([string]$message)
    Write-Output "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $message"
}

$tag_operation = $args[0]

if ($tag_operation -eq "start") {
    Log "STARTING HOTFIX PROCESS"

    Log "STEP 1: Switching to main branch"
    $stdout = git checkout main 2>&1
    if ($LASTEXITCODE -ne 0) {
        Log "ERROR: Failed to switch to main branch"
        Write-Error $stdout
        exit 1
    }
    
    # Increment version number
    $new_version = cz bump --dry-run --increment PATCH --yes | Select-String 'tag to create:' | ForEach-Object { $_.ToString().Split()[3] }
    Log "New version to be hotfixed: $new_version"

    Log "STEP 2: Starting git flow hotfix with version $new_version"
    $stdout = git flow hotfix start $new_version 2>&1
    if ($LASTEXITCODE -ne 0) {
        Log "ERROR: Failed to start git flow hotfix"
        Write-Error $stdout
        exit 1
    }

    Log "HOTFIX PROCESS STARTED SUCCESSFULLY"

} elseif ($tag_operation -eq "finish") {
    Log "STARTING HOTFIX FINISH PROCESS"

    Log "STEP 1: Getting the new version from Commitizen"
    $cz_new_version = cz bump --dry-run --increment PATCH --yes 2>$null | Select-String 'tag to create:' | ForEach-Object { $_.ToString().Split()[3] }
    if ([string]::IsNullOrEmpty($cz_new_version)) {
        Log "ERROR: Failed to get new version from Commitizen"
        exit 1
    }
    Log "New version to be hotfixed: $cz_new_version"

    Log "STEP 2: Bumping the version using Commitizen"
    $stdout = cz bump --increment PATCH --yes 2>&1
    if ($LASTEXITCODE -ne 0) {
        Log "ERROR: Failed to bump version using Commitizen"
        Write-Error $stdout
        exit 1
    }

    Log "STEP 3: Generating changelog incrementally"
    $stdout = cz changelog --incremental 2>&1
    if ($LASTEXITCODE -ne 0) {
        Log "ERROR: Failed to generate changelog incrementally"
        Write-Error $stdout
        exit 1
    }

    Log "Please review the CHANGELOG.md file, make any necessary edits and save the file."
    $null = Read-Host -Prompt "Press [Enter] to continue"

    Log "STEP 4: Adding CHANGELOG.md to git"
    $stdout = git add CHANGELOG.md 2>&1
    if ($LASTEXITCODE -ne 0) {
        Log "ERROR: Failed to add CHANGELOG.md to git"
        Write-Error $stdout
        exit 1
    }

    Log "STEP 5: Committing the updated changelog"
    $stdout = git commit -m "docs(changelog): updating changelog with changes of current hotfix

    auto generating changelog incrementally using commitizen" 2>&1
    if ($LASTEXITCODE -ne 0) {
        Log "ERROR: Failed to commit updated changelog"
        Write-Error $stdout
        exit 1
    }

    Log "STEP 6: Creating a temporary changelog for hotfix finish"
    $stdout = cz ch $cz_new_version --dry-run 2>$null | ForEach-Object { $_ -replace '^(#+)\s*', '' -replace '^-\s*', "`t - " } | Out-File -FilePath tag-message.txt -Encoding utf8
    if ($LASTEXITCODE -ne 0) {
        Log "ERROR: Failed to create temporary changelog"
        Write-Error $stdout
        exit 1
    }

    Log "Please review the tag-message.txt file, make any necessary edits and save the file."
    $null = Read-Host -Prompt "Press [Enter] to continue"

    Log "STEP 7: Deleting the tag to prevent conflicts"
    $stdout = git tag -d $cz_new_version 2>&1
    if ($LASTEXITCODE -ne 0) {
        Log "ERROR: Failed to delete tag"
        Write-Error $stdout
        exit 1
    }

    Log "STEP 8: Setting GIT_MERGE_AUTOEDIT to no to prevent merge messages"
    $env:GIT_MERGE_AUTOEDIT = "no"

    Log "STEP 9: Finishing the git flow hotfix"
    $stdout = git flow hotfix finish -f tag-message.txt "$cz_new_version" 2>&1
    if ($LASTEXITCODE -ne 0) {
        Log "ERROR: Failed to finish git flow hotfix"
        Write-Error $stdout
        $env:GIT_MERGE_AUTOEDIT = ""
        Remove-Item tag-message.txt
        exit 1
    }

    Log "STEP 10: Unsetting GIT_MERGE_AUTOEDIT"
    $env:GIT_MERGE_AUTOEDIT = ""

    Log "STEP 11: Cleaning up temporary changelog"
    Remove-Item tag-message.txt

    Log "HOTFIX FINISH PROCESS COMPLETED SUCCESSFULLY"

} else {
    Log "ERROR: Invalid operation. Please specify 'start' or 'finish' as the first argument."
    exit 1
}
