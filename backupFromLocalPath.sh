#!/bin/bash

helpFunction()
{
  echo ""
  echo "usage: $0 -r <backup | add | remove> [-v <absolute-folder-path>]"
  echo "          [-c <relative-file-path>]"
  echo "          [-d <relative-folder-path>]"
  echo "          [-k]"
  echo "          [-s]"
  echo ""
  echo "usage: $0 --run <backup | add | remove> [--value <absolute-folder-path>]"
  echo "          [--config-file <relative-file-path>]"
  echo "          [--target-directory <relative-folder-path>]"
  echo "          [--ignore-existing-files]"
  echo "          [--silent]"
  exit 1
}

# default values
basePath="$(pwd)"
command=""
commandValue=""
configFile=""
backupPath=""
ignoreExistingFiles=0
silent=0

# read options
if options="$(getopt -o r:v:c:d:ksh -l run:,value:,config-file:,target-directory:,ignore-existing-files,silent,help -- "$@")"; then
  eval set -- "$options"
  while true
  do
    case "${1,,}" in
      -r|--run)
        if [ -z $command ]; then
          command="$2"
        else
          echo "CONFLICTING OPTIONS FOR -r"
          helpFunction
        fi
        shift # skip argument
        ;;
      -v|--value)
        if [ -z $commandValue ]; then
          commandValue="$2"
        else
          echo "CONFLICTING OPTIONS FOR -v"
          helpFunction
        fi
        shift # skip argument
        ;;
      -c|--config-file)
        if [ -z $configFile ]; then
          configFile="$2"
        else
          echo "CONFLICTING OPTIONS FOR -c"
          helpFunction
        fi
        shift # skip argument
        ;;
      -d|--target-directory)
        if [ -z $backupPath ]; then
          backupPath="$2"
        else
          echo "CONFLICTING OPTIONS FOR -d"
          helpFunction
        fi
        shift # skip argument
        ;;
      -k|--ignore-existing-files) ignoreExistingFiles=1 ;;
      -s|--silent) silent=1 ;;
      -h|--help) helpFunction ;;
      --)
        shift
        break
        ;;
      *) helpFunction ;;
    esac
    shift
  done
fi

# validate options
if [ -z "$command" ]; then
  echo "MISSING COMMAND: backup | add | remove"
  helpFunction
fi

if [[ ("$command" == "add" || "$command" == "remove") && -z "$commandValue" ]]; then
  echo "MISSING VALUE: absolute-folder-path"
  helpFunction
fi

if [ -z "$configFile" ]; then
  configFile="./backupFromLocalPath.config"
fi
if [ -z "$backupPath" ]; then
  backupPath="./"
fi

if [ ! -f "$configFile" ]; then
  echo "CONFIG FILE NOT FOUND: $configFile"
  exit 1
fi

# run the script
echo "==========    ARGUMENTS    =========="
echo "base directory:   $basePath"
echo "config file:      $configFile"
echo "target directory: $backupPath"

if [ "$command" == "add" ]; then
  if grep -q "$commandValue" "$configFile"; then
    echo "$configFile already contains $commandValue"
    echo "==========     CONFIG      =========="
    cat "$configFile"
  else
    echo "ADDING $commandValue TO $configFile"
    echo "$commandValue" >> "$configFile"
    echo "MARKING $commandValue AS BACKUPABLE"
    cd "$commandValue"
    touch .backupable
    cd "$basePath"
    echo "==========   NEW CONFIG    =========="
    cat "$configFile"
  fi
fi
if [ "$command" == "remove" ]; then
  if grep -q "$commandValue" "$configFile"; then
    echo "REMOVING $commandValue FROM $configFile"
    grep -v -xF -e "$commandValue" "$configFile" > "${configFile}.tmp"
    mv "${configFile}.tmp" "$configFile"
    echo "==========   NEW CONFIG    =========="
    cat "$configFile"
  else
    echo "$configFile does not contain $commandValue"
    echo "==========     CONFIG      =========="
    cat "$configFile"
  fi
fi

backupFiles()
{
  source=$1
  target=$2
  ignoreExisting=$3

  for item in $source/*
  do
    if [ $(basename "$item") == ".backupable" ]; then
      [[ $silent -eq 0 ]] && echo "- SKIP            : $item"
    else
      if [[ -f "${target}/$(basename "$item")" || -d "${target}/$(basename "$item")" ]]; then
        if [ -d "$item" ]; then
          # start recursive check
          mkdir -p "${target}/$(basename "$item")"
          backupFiles "$item" "${target}/$(basename "$item")" $ignoreExisting
          target=$(dirname "$target") # "up" navigation
        else
          if [ $ignoreExisting == 1 ]; then
            [[ $silent -eq 0 ]] && echo "- SKIP (existing) : $item"
          else
            if [ "$item" -nt "${target}/$(basename "$item")" ]; then
              # run copy
              [[ $silent -eq 0 ]] && echo "- COPY            : $item"
              if [ -f "$item" ]; then
                cp "$item" "${target}/$(basename "$item")"
              fi
            else
              [[ $silent -eq 0 ]] && echo "- SKIP (unchanged): $item"
            fi
          fi
        fi
      else
        # run copy
        [[ $silent -eq 0 ]] && echo "- COPY            : $item"
        if [ -f "$item" ]; then
          cp "$item" "${target}/$(basename "$item")"
        fi
        if [ -d "$item" ]; then
          mkdir -p "${target}/$(basename "$item")"
          backupFiles "$item" "${target}/$(basename "$item")" $ignoreExisting
          target=$(dirname "$target") # "up" navigation
        fi
      fi
    fi
  done
}

if [ "$command" == "backup" ]; then
  echo "==========     CONFIG      =========="
  cat "$configFile"
  echo "========== RUNNING BACKUP  =========="
  while IFS= read -r line
  do
    if [ -f "${line}/.backupable" ]; then
      backupableDirectoryName=$(basename "$line")
      fullTargetDirectoryName="${backupPath}/${backupableDirectoryName}"

      if [ ! -d "$fullTargetDirectoryName" ]; then
        echo ""
        echo "> CLONING $line to $fullTargetDirectoryName"
      else
        echo ""
        echo "> PULLING $line to $fullTargetDirectoryName"
      fi

      mkdir -p "$fullTargetDirectoryName"

      dotGlobSetting=$(shopt -p | grep dotglob)
      shopt -s dotglob # enable to also copy invisible files
      backupFiles $line "$fullTargetDirectoryName" $ignoreExistingFiles
      $dotGlobSetting # set to previous value
    else
      echo "MISSING .backupable FILE IN: $line"
      echo "SKIPPING $line"
    fi
  done < "$configFile"
  echo "========== BACKUP FINISHED =========="
fi

exit 0
