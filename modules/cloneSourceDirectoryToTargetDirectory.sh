#!/bin/bash

# NOTE: This script is a sub module of "backupFromLocalPath.sh" and "partialBackupFromExternalDrive.sh" and is not intended to be called manually.
# Parameters:
# 1: absoluteFolder
#    - source directory
# 2: fullTargetDirectoryName
#    - target directory
# 3: ignoreExistingFiles
#    - whether existing files should not be overwritten even if they contain new changes
# 4: silent
#    - whether no progress statements should be shown

# map parameters

absoluteFolder="$1"
fullTargetDirectoryName="$2"
ignoreExistingFiles=$3
silent=$4

# init counters

checked=0
created=0
updated=0
skipped=0

backupFiles()
{
  source=$1
  target=$2
  ignoreExisting=$3

  for item in "$source"/*
  do
    if [ $(basename "$item") == ".backupable" ]; then
      [[ $silent -eq 0 ]] && echo "- SKIP            : $item"
      ((checked++))
      ((skipped++))
    else
      if [[ -f "${target}/$(basename "$item")" || -d "${target}/$(basename "$item")" ]]; then
        if [ -d "$item" ]; then
          # start recursive check
          [[ $silent -eq 1 ]] && echo "- CHECKING "$item""
          mkdir -p "${target}/$(basename "$item")"
          backupFiles "$item" "${target}/$(basename "$item")" $ignoreExisting
          # "up" navigation
          target=$(dirname "$target")
          source=$(dirname "$source")
          [[ $silent -eq 1 ]] && echo "- CHECKING $source"
        else
          ((checked++))
          if [ $ignoreExisting == 1 ]; then
            [[ $silent -eq 0 ]] && echo "- SKIP (existing) : $item"
            ((skipped++))
          else
            if [ "$item" -nt "${target}/$(basename "$item")" ]; then
              # run copy
              [[ $silent -eq 0 ]] && echo "- COPY            : $item"
              if [ -f "$item" ]; then
                cp "$item" "${target}/$(basename "$item")"
                ((updated++))
              fi
            else
              [[ $silent -eq 0 ]] && echo "- SKIP (unchanged): $item"
              ((skipped++))
            fi
          fi
        fi
      else
        # run copy
        [[ $silent -eq 0 ]] && echo "- COPY            : $item"
        if [ -f "$item" ]; then
          cp "$item" "${target}/$(basename "$item")"
          ((checked++))
          ((created++))
        fi
        if [ -d "$item" ]; then
          # start recursive backup
          [[ $silent -eq 1 ]] && echo "- CHECKING "$item""
          mkdir -p "${target}/$(basename "$item")"
          backupFiles "$item" "${target}/$(basename "$item")" $ignoreExisting
          # "up" navigation
          target=$(dirname "$target")
          source=$(dirname "$source")
          [[ $silent -eq 1 ]] && echo "- CHECKING $source"
        fi
      fi
    fi
  done
}

# run script

if [ ! -d "$fullTargetDirectoryName" ]; then
  echo "> CLONING $absoluteFolder to $fullTargetDirectoryName"
else
  echo "> PULLING $absoluteFolder to $fullTargetDirectoryName"
fi

mkdir -p "$fullTargetDirectoryName"

dotGlobSetting=$(shopt -p | grep dotglob)
shopt -s dotglob # enable to also copy invisible files
backupFiles "$absoluteFolder" "$fullTargetDirectoryName" $ignoreExistingFiles
$dotGlobSetting # set to previous value
echo "CHECKED FILES: $checked"
echo "CREATED FILES: $created"
echo "UPDATED FILES: $updated"
echo "SKIPPED FILES: $skipped"

absoluteTargetDirectoryName="/$(realpath --relative-base="/" "$fullTargetDirectoryName" --canonicalize-missing)" # convert all folders to absolute folders
echo "$(date +"%Y-%m-%d %T"): backed up $(($created + $updated)) file(s) to $absoluteTargetDirectoryName" >> "${absoluteFolder}/.backupable"
