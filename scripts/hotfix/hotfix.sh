#!/bin/bash

# Logging function
log() {
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

tag_operation=$1

if [ "$tag_operation" == "start" ]; then
    log "STARTING HOTFIX PROCESS"

    log "STEP 1: Switching to main branch"
    if ! output=$(git checkout main 2>&1); then
        log "ERROR: Failed to switch to main branch"
        log "Command output: $output"
        exit 1
    fi

    # Increment version number
    new_version=$(cz bump --dry-run --increment PATCH --yes 2>/dev/null | grep 'tag to create:' | awk '{print $4}')
    log "New version to be hotfixed: $new_version"

    log "STEP 2: Starting git flow hotfix with version $new_version"
    if ! output=$(git flow hotfix start "$new_version" 2>&1); then
        log "ERROR: Failed to start git flow hotfix"
        log "Command output: $output"
        exit 1
    fi

    log "HOTFIX PROCESS STARTED SUCCESSFULLY"

elif [ "$tag_operation" == "finish" ]; then
    log "STARTING HOTFIX FINISH PROCESS"

    log "STEP 1: Getting the new version from Commitizen"
    if ! cz_output=$(cz bump --dry-run --increment PATCH --yes 2>&1); then
        log "ERROR: Failed to get new version from Commitizen"
        log "Command output: $cz_output"
        exit 1
    fi
    cz_new_version=$(echo "$cz_output" | grep 'tag to create:' | awk '{print $4}')
    if [ -z "$cz_new_version" ]; then
        log "ERROR: Failed to parse new version from Commitizen output"
        exit 1
    fi
    log "New version to be hotfixed: $cz_new_version"

    log "STEP 2: Bumping the version using Commitizen"
    if ! output=$(cz bump --increment PATCH --yes 2>&1); then
        log "ERROR: Failed to bump version using Commitizen"
        log "Command output: $output"
        exit 1
    fi

    log "STEP 3: Generating changelog incrementally"
    if ! output=$(cz changelog --incremental 2>&1); then
        log "ERROR: Failed to generate changelog incrementally"
        log "Command output: $output"
        exit 1
    fi

    log "Please review the CHANGELOG.md file, make any necessary edits and save the file."
    read -p "Press [Enter] to continue"

    log "STEP 4: Adding CHANGELOG.md to git"
    if ! output=$(git add CHANGELOG.md 2>&1); then
        log "ERROR: Failed to add CHANGELOG.md to git"
        log "Command output: $output"
        exit 1
    fi

    log "STEP 5: Committing the updated changelog"
    if ! output=$(git commit -m "docs(changelog): updating changelog with changes of current hotfix

auto generating changelog incrementally using commitizen" 2>&1); then
        log "ERROR: Failed to commit updated changelog"
        log "Command output: $output"
        exit 1
    fi

    log "STEP 6: Creating a temporary changelog for hotfix finish"
    if ! output=$(cz ch "$cz_new_version" --dry-run 2>&1 | sed -e 's/^## //' -e 's/^### //' -e 's/^-\(.*\)$/\t- \1/' > tag-message.txt); then
        log "ERROR: Failed to create temporary changelog"
        log "Command output: $output"
        exit 1
    fi

    log "Please review the tag-message.txt file, make any necessary edits and save the file."
    read -p "Press [Enter] to continue"

    log "STEP 7: Deleting the tag to prevent conflicts"
    if ! output=$(git tag -d "$cz_new_version" 2>&1); then
        log "ERROR: Failed to delete tag"
        log "Command output: $output"
        exit 1
    fi

    log "STEP 8: Setting GIT_MERGE_AUTOEDIT to no to prevent merge messages"
    export GIT_MERGE_AUTOEDIT=no

    log "STEP 9: Finishing the git flow hotfix"
    if ! output=$(git flow hotfix finish -f tag-message.txt "$cz_new_version" 2>&1); then
        log "ERROR: Failed to finish git flow hotfix"
        log "Command output: $output"
        unset GIT_MERGE_AUTOEDIT
        rm tag-message.txt
        exit 1
    fi

    log "STEP 10: Unsetting GIT_MERGE_AUTOEDIT"
    unset GIT_MERGE_AUTOEDIT

    log "STEP 11: Cleaning up temporary changelog"
    rm tag-message.txt

    log "HOTFIX FINISH PROCESS COMPLETED SUCCESSFULLY"
    
else
    log "ERROR: Invalid operation. Please specify 'start' or 'finish' as the first argument."
    exit 1
fi
