#!/bin/bash

# Logging function
log() {
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log "STARTING RELEASE PROCESS"

log "STEP 1: Switching to develop branch"
if ! output=$(git checkout develop 2>&1); then
    log "ERROR: Failed to switch to develop branch"
    log "Command output: $output"
    exit 1
fi

log "STEP 2: Getting the new version from Commitizen"
if ! cz_output=$(cz bump --dry-run --yes 2>&1); then
    log "ERROR: Failed to get new version from Commitizen"
    log "Command output: $cz_output"
    exit 1
fi
cz_new_version=$(echo "$cz_output" | grep 'tag to create:' | awk '{print $4}')
if [ -z "$cz_new_version" ]; then
    log "ERROR: Failed to parse new version from Commitizen output"
    exit 1
fi
log "New version to be released: $cz_new_version"

log "STEP 3: Starting git flow release with version $cz_new_version"
if ! output=$(git flow release start "$cz_new_version" 2>&1); then
    log "ERROR: Failed to start git flow release"
    log "Command output: $output"
    exit 1
fi

log "STEP 4: Bumping the version using Commitizen"
if ! output=$(cz bump --yes 2>&1); then
    log "ERROR: Failed to bump version using Commitizen"
    log "Command output: $output"
    exit 1
fi

log "STEP 5: Generating changelog incrementally"
if ! output=$(cz changelog --incremental 2>&1); then
    log "ERROR: Failed to generate changelog incrementally"
    log "Command output: $output"
    exit 1
fi

log "Please review the CHANGELOG.md file, make any necessary edits and save the file."
read -p "Press [Enter] to continue"

log "STEP 6: Adding CHANGELOG.md to git"
if ! output=$(git add CHANGELOG.md 2>&1); then
    log "ERROR: Failed to add CHANGELOG.md to git"
    log "Command output: $output"
    exit 1
fi

log "STEP 7: Committing the updated changelog"
if ! output=$(git commit -m "docs(changelog): updating changelog with changes of current release

auto generating changelog incrementally using commitizen" 2>&1); then
    log "ERROR: Failed to commit updated changelog"
    log "Command output: $output"
    exit 1
fi

log "STEP 8: Creating a temporary changelog for release finish"
if ! output=$(cz ch "$cz_new_version" --dry-run 2>/dev/null | sed -e 's/^## //' -e 's/^### //' -e 's/^-\(.*\)$/\t- \1/' > tag-message.txt 2>&1); then
    log "ERROR: Failed to create temporary changelog"
    log "Command output: $output"
    exit 1
fi

log "Please review the tag-message.txt file, make any necessary edits and save the file."
read -p "Press [Enter] to continue"

log "STEP 9: Deleting the tag to prevent conflicts"
if ! output=$(git tag -d "$cz_new_version" 2>&1); then
    log "ERROR: Failed to delete tag"
    log "Command output: $output"
    exit 1
fi

log "STEP 10: Setting GIT_MERGE_AUTOEDIT to no to prevent merge messages"
export GIT_MERGE_AUTOEDIT=no

log "STEP 11: Finishing the git flow release"
if ! output=$(git flow release finish -f tag-message.txt "$cz_new_version" 2>&1); then
    log "ERROR: Failed to finish git flow release"
    log "Command output: $output"
    unset GIT_MERGE_AUTOEDIT
    rm tag-message.txt
    exit 1
fi

log "STEP 12: Unsetting GIT_MERGE_AUTOEDIT"
unset GIT_MERGE_AUTOEDIT

log "STEP 13: Cleaning up temporary changelog"
rm tag-message.txt

log "RELEASE PROCESS COMPLETED SUCCESSFULLY"
