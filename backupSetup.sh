#!/bin/bash

helpFunction()
{
  echo ""
  echo "usage: $0 <-i | -c> <file-name>"
  echo "          [-u <0 | 1>]"
  echo "          [-a <relative-folder-path>]"
  exit 1
}

# default values
basePath="$(pwd)"
command=""
fileName=""
runUpdate=-1
addFolder=""

printScript()
{
  echo "==========       SCRIPT CONTENT       =========="
  cat "$fileName"
}

# read options
while getopts "i:c:u:a:" opt
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
      echo -e "cd backup_utils\ngit pull\ncd ..\n" >> "$fileName"
    fi
  fi
  printScript
fi

if [ $command == "config" ]; then
  echo "========== CONFIGURING BACKUP SCRIPT  =========="

  firstLine=$(head -n 1 "$fileName")
  if [ $runUpdate == 0 ]; then
    if [[ $firstLine == "cd backup_utils" ]]; then
      echo "REMOVING PULL"
      sed -i -e '1,4d' "$fileName"
    else
      echo "PULL ALREADY REMOVED"
    fi
  fi
  if [ $runUpdate == 1 ]; then
    if [[ $firstLine == "cd backup_utils" ]]; then
      echo "PULL ALREADY ADDED"
    else
      echo "ADDING PULL"
      echo -e "cd backup_utils\ngit pull\ncd ..\n\n$(cat "$fileName")" > "$fileName"
    fi
  fi

  if [[ ! -z $addFolder ]]; then
    echo "ADDING $addFolder"
    configLine="./backup_utils/backupRepositories.sh -r backup -c ${addFolder}/backup.config -d ${addFolder}"
    if grep -q -F "$configLine" "$fileName"; then
      echo "$fileName ALREADY CONTAINS $addFolder"
    else
      echo "$configLine" >> "$fileName"
      mkdir -p "$addFolder"
      if [ ! -f "${addFolder}/backup.config" ]; then
        cd "$addFolder"
        touch "backup.config"
        cd $basePath
      fi
    fi
  fi

  printScript
fi
