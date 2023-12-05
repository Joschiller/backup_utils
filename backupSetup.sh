#!/bin/bash

helpFunction()
{
  echo ""
  echo "usage: $0 <-i | -c> <file-name>"
  echo "          [-u <0 | 1>]"
  echo "          [-a <relative-folder-path> <-r | -d [-k]>]"
  echo ""
  echo "usage: $0 <--init | --configure> <file-name>"
  echo "          [--set-backup-utils-update <0 | 1>]"
  echo "          [--add <relative-folder-path> <--repository|--repo | --directory [--ignore-existing-files]>]"
  exit 1
}

# default values
basePath="$(pwd)"
command=""
fileName=""
runUpdate=-1
addFolder=""
addFolderMode=""
keepExisting=0

printScript()
{
  echo "==========       SCRIPT CONTENT       =========="
  cat "$fileName"
}

# read options
if options="$(getopt -o i:c:u:a:rdkh -l init:,configure:,set-backup-utils-update:,add:,repository,repo,directory,ignore-existing-files,help -- "$@")"; then
  eval set -- "$options"
  while true
  do
    case "${1,,}" in
      -i|--init)
        if [ -z $command ]; then
          command="init"
          fileName="$2"
        else
          if [ $command == "init" ]; then
            echo "CONFLICTING OPTIONS FOR -i"
          fi
          if [ $command == "config" ]; then
            echo "CONFLICTING OPTIONS: -i AND -c"
          fi
          helpFunction
        fi
        shift # skip argument
        ;;
      -c|--configure)
        if [ -z $command ]; then
          command="config"
          fileName="$2"
        else
          if [ $command == "init" ]; then
            echo "CONFLICTING OPTIONS: -i AND -c"
          fi
          if [ $command == "config" ]; then
            echo "CONFLICTING OPTIONS FOR -c"
          fi
          helpFunction
        fi
        shift # skip argument
        ;;
      -u|--set-backup-utils-update)
        if [ $runUpdate == -1 ]; then
          runUpdate=$2
        else
          echo "CONFLICTING OPTIONS FOR -u"
          helpFunction
        fi
        shift # skip argument
        ;;
      -a|--add)
        if [ -z $addFolder ]; then
          addFolder=$2
        else
          echo "CONFLICTING OPTIONS FOR -a"
          helpFunction
        fi
        shift # skip argument
        ;;
      -r|--repository|--repo)
        if [ -z $addFolderMode ]; then
          addFolderMode="repository"
        else
          echo "CONFLICTING OPTIONS: -r AND -d"
          helpFunction
        fi ;;
      -d|--directory)
        if [ -z $addFolderMode ]; then
          addFolderMode="directory"
        else
          echo "CONFLICTING OPTIONS: -r AND -d"
          helpFunction
        fi ;;
      -k|--ignore-existing-files) keepExisting=1 ;;
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
  echo "MISSING OPTION: -i | -c"
  helpFunction
fi

if [ -z "$fileName" ]; then
  echo "MISSING VALUE: <file-name>"
  helpFunction
fi

if [[ "$command" == "config" && $runUpdate == -1 && -z $addFolder ]]; then
  echo "MISSING OPTION: -u <0 | 1> | -a <relative-folder-path>"
  helpFunction
fi

if [[ ! -z "$addFolder" && -z "$addFolderMode" ]]; then
  echo "MISSING OPTION: -r | -d"
  helpFunction
fi

if [[ "$addFolderMode" == "repository" && $keepExisting == 1 ]]; then
  echo "CONFLICTING OPTIONS: -r AND -k"
  helpFunction
fi

# correct file name if needed
if [[ ! "$fileName" == *.sh ]]; then
  fileName="${fileName}.sh"
fi

# run the script
if [ $command == "init" ]; then
  echo "========== INITIALIZING BACKUP SCRIPT =========="
  if [ -f "$fileName" ]; then
    echo "FILE ALREADY EXISTS"
  else
    touch "$fileName"
    if [[ $runUpdate == 1 || $runUpdate == -1 ]]; then
      echo -e "echo ---------- PULLING BACKUP_UTILS ----------\ncd backup_utils\ngit pull\ncd ..\n" >> "$fileName"
    fi
    echo "echo ----------    RUNNING BACKUP    ----------" >> "$fileName"
  fi
  printScript
fi

if [ $command == "config" ]; then
  echo "========== CONFIGURING BACKUP SCRIPT  =========="

  firstLine=$(head -n 1 "$fileName")
  if [ $runUpdate == 0 ]; then
    if [[ $firstLine == "echo ---------- PULLING BACKUP_UTILS ----------" ]]; then
      echo "REMOVING PULL"
      sed -i -e '1,5d' "$fileName"
    else
      echo "PULL ALREADY REMOVED"
    fi
  fi
  if [ $runUpdate == 1 ]; then
    if [[ $firstLine == "echo ---------- PULLING BACKUP_UTILS ----------" ]]; then
      echo "PULL ALREADY ADDED"
    else
      echo "ADDING PULL"
      echo -e "echo ---------- PULLING BACKUP_UTILS ----------\ncd backup_utils\ngit pull\ncd ..\n\n$(cat "$fileName")" > "$fileName"
    fi
  fi

  if [[ ! -z $addFolder ]]; then
    configLineRepository="./backup_utils/backupRepositories.sh -r backup -c ${addFolder}/backup.config -d ${addFolder}"
    configLineDirectory="./backup_utils/backupFromLocalPath.sh -r backup -c ${addFolder}/backup.config -d ${addFolder}"
    configLineDirectoryKeepExisting="./backup_utils/backupFromLocalPath.sh -r backup -c ${addFolder}/backup.config -d ${addFolder} -k"

    added=0
    if ! grep -q -F "$configLineRepository" "$fileName"; then
      if ! grep -q -F "$configLineDirectory" "$fileName"; then
        if ! grep -q -F "$configLineDirectoryKeepExisting" "$fileName"; then
          added=1
          echo "ADDING $addFolder"
          if [[ "$addFolderMode" == "repository" ]]; then
            echo "$configLineRepository" >> "$fileName"
          fi
          if [[ "$addFolderMode" == "directory" ]]; then
            if [[ $keepExisting == 1 ]]; then
              echo "$configLineDirectoryKeepExisting" >> "$fileName"
            else
              echo "$configLineDirectory" >> "$fileName"
            fi
          fi
          mkdir -p "$addFolder"
          if [ ! -f "${addFolder}/backup.config" ]; then
            cd "$addFolder"
            touch "backup.config"
            cd $basePath
          fi
        fi
      fi
    fi
    if [ $added == 0 ]; then
      echo "$fileName ALREADY CONTAINS $addFolder"
    fi
  fi

  printScript
fi
