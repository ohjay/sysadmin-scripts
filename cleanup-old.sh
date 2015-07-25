#!/bin/bash
# cleanup-old
# A utility script for removing old and unecessary files from secondary storage.
# Any files in the current directory or any subdirectories may be considered.
# Note: this is potentially a dangerous script, as it involves the deletion of files!
# 
# For every file that has not been modified for over 100 days, the user will be asked 
# if he/she wants to remove that file from the system. If he/she says no, then he/she
# will be given the option to ignore that file the next time this command is run.
# 
# $LastChangedDate: 2015-07-22 (Wed, 22 Jul 2015) $

# The file containing the confirm function
. utility/util-functions.sh

# rm_file <file>
# Asks the user whether or not he/she wants to remove the given file.
# If so, this function will remove the file. Otherwise, the user will be given a chance
# to add the file to the "ignore" list (i.e. list of files to  be ignored by this command).
function rm_file {
    eval file="$1"
    
    # Set the prompt strings
    rm_prompt=$'\n'"${file}"$' has not been modified for over 100 days.\nDo you want to remove '"${file}"'?'
    ignore_prompt="Do you want to add ${file} to the ignore list?"
    
    if confirm "\${rm_prompt}"; then
        rm "${file}"
    elif confirm "\${ignore_prompt}"; then
        echo "${file}" >> ~/.cleanup-ignore.txt
    fi
}

# check_files <filepath> <num_days>
# Considers all old files (i.e. files that have not been accessed for > 100 days) 
# on the given filepath for removal. (If a directory is empty, the FIND commands will complain.)
function check_files {
    eval filepath="$1"
    local num_days=$1
    
    while IFS= read -u 3 -r -d '' file; do
        # Check that the file is not in the ignore list
        if ! grep -Fxq "${file}" ~/.cleanup-ignore.txt; then
            rm_file "\${file}"
        fi
    done 3< <(find "${filepath}"* -maxdepth 0 -mmin +$((60 * 24 * 100)) -print0)
    # Make sure the user wants to descend into a directory
    while IFS= read -u 3 -r -d '' dir; do
        descend_prompt="Do you want to descend into the directory "${dir}"?"
        if confirm "\${descend_prompt}"; then
            check_files "\${dir}/"
        fi
    done 3< <(find "${filepath}"* -maxdepth 0 -type d -print0)
}

### Main script ###
# Create the ignore file if it doesn't already exist
if [ ! -f ~/.cleanup-ignore.txt ]; then
    echo "" > ~/.cleanup-ignore.txt
fi

check_files "./"
