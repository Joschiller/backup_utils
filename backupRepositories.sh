#!/bin/bash

helpFunction()
{
  echo ""
  echo "usage: $0 -r <backup | add | remove> [-v <repository-url>]"
  echo "          [-c <relative-file-path>]"
  echo "          [-d <relative-folder-path>]"
  exit 1
}

# default values
basePath="$(pwd)"
command=""
commandValue=""
configFile="./backupRepositories.config"
backupPath="./"

# read options
while getopts "r:v:c:d:" opt
do
  case "$opt" in
    r) command="$OPTARG" ;;
    v) commandValue="$OPTARG" ;;
    c) configFile="$OPTARG" ;;
    d) backupPath="$OPTARG" ;;
    ?) helpFunction ;;
  esac
done

# validate options
if [ -z "$command" ]; then
  echo "MISSING COMMAND: backup | add | remove"
  helpFunction
fi

if [[ ("$command" == "add" || "$command" == "remove") && -z "$commandValue" ]]; then
  echo "MISSING VALUE: repository-url"
  helpFunction
fi

if [ -z "$configFile" ]; then
  echo "MISSING VALUE: relative-file-path"
  helpFunction
fi
if [ -z "$backupPath" ]; then
  echo "MISSING VALUE: relative-folder-path"
  helpFunction
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
    echo "==========   NEW CONFIG    =========="
    cat "$configFile"
  fi
fi
if [ "$command" == "remove" ]; then
  if grep -q "$commandValue" "$configFile"; then
    echo "REMOVING $commandValue FROM $configFile"
    grep -v -xF -e "$commandValue" "$configFile" > "${configFile}.tmp" && mv "${configFile}.tmp" "$configFile"
    echo "==========   NEW CONFIG    =========="
    cat "$configFile"
  else
    echo "$configFile does not contain $commandValue"
    echo "==========     CONFIG      =========="
    cat "$configFile"
  fi
fi

if [ "$command" == "backup" ]; then
  echo "==========     CONFIG      =========="
  cat "$configFile"
  echo "========== RUNNING BACKUP  =========="
  while IFS= read -r line
  do
    mkdir -p "$backupPath"
    cd "$backupPath"
    repoDirectory=$(basename "$line")

    if [ ! -d "$repoDirectory" ]; then
      echo ""
      echo "> CLONING $line to $(pwd)/$repoDirectory"
      git clone "$line"
    else
      echo ""
      echo "> PULLING $line to $(pwd)/$repoDirectory"
      cd "$repoDirectory"
      git pull
      cd ..
    fi
    cd "$basePath"
  done < "$configFile"
  echo "========== BACKUP FINISHED =========="
fi

exit 0
