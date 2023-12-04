#!/bin/bash

helpFunction()
{
  echo ""
  echo "usage: $0 <-i | -c> <file-name>"
  echo "          [-u <0 | 1>]"
  echo "          [-a <relative-folder-path> <-r | -d [-k]>]"
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
while getopts "i:c:u:a:rdk" opt
do
  case "$opt" in
    i)
      if [ -z $command ]; then
        command="init"
        fileName="$OPTARG"
      else
        if [ $command == "init" ]; then
          echo "CONFLICTING OPTIONS FOR -i"
        fi
        if [ $command == "config" ]; then
          echo "CONFLICTING OPTIONS: -i AND -c"
        fi
        helpFunction
      fi ;;
    c)
      if [ -z $command ]; then
        command="config"
        fileName="$OPTARG"
      else
        if [ $command == "init" ]; then
          echo "CONFLICTING OPTIONS: -i AND -c"
        fi
        if [ $command == "config" ]; then
          echo "CONFLICTING OPTIONS FOR -c"
        fi
        helpFunction
      fi ;;
    u)
      if [ $runUpdate == -1 ]; then
        runUpdate=$OPTARG
      else
        echo "CONFLICTING OPTIONS FOR -u"
        helpFunction
      fi ;;
    a)
      if [ -z $addFolder ]; then
        addFolder=$OPTARG
      else
        echo "CONFLICTING OPTIONS FOR -a"
        helpFunction
      fi ;;
    r)
      if [ -z $addFolderMode ]; then
        addFolderMode="repository"
      else
        echo "CONFLICTING OPTIONS: -r AND -d"
        helpFunction
      fi ;;
    d)
      if [ -z $addFolderMode ]; then
        addFolderMode="directory"
      else
        echo "CONFLICTING OPTIONS: -r AND -d"
        helpFunction
      fi ;;
    k) keepExisting=1 ;;
    ?) helpFunction ;;
  esac
done

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
