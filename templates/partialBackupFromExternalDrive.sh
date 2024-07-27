#!/bin/bash

helpFunction()
{
  echo ""
  echo "usage: $0 -b <backup-option> -d <source-drive>"
  echo ""
  echo "usage: $0 --backup <backup-option> --drive <source-drive>"
  echo ""
  echo "Available backup options:"
  echo "- ... TODO: list your backup options here - e.g.: ..."
  echo "- photos : all_photos -> bulk_data/photos"
  exit 1
}

# default values
basePath="$(pwd)"
backupOption=""
sourceDrive=""

# read options
if options="$(getopt -o b:d:h -l backup:,drive:,help -- "$@")"; then
  eval set -- "$options"
  while true
  do
    case "${1,,}" in
      -b|--backup)
        if [ -z $backupOption ]; then
          backupOption="$2"
        else
          echo "CONFLICTING OPTIONS for -b"
          helpFunction
        fi
        shift # skip argument
        ;;
      -d|--drive)
        if [ -z $sourceDrive ]; then
          sourceDrive="$2"
        else
          echo "CONFLICTING OPTIONS for -d"
          helpFunction
        fi
        shift # skip argument
        ;;
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
if [ -z "$backupOption" ]; then
  echo "MISSING OPTION: -b"
  helpFunction
fi

if [ -z "$sourceDrive" ]; then
  echo "MISSING OPTION: -d"
  helpFunction
fi

# cleanup sourceDrive

if [[ ! "$sourceDrive" == */ ]]; then
  sourceDrive="${sourceDrive}/"
fi

if [[ ! "$sourceDrive" == /* ]]; then
  sourceDrive="/${sourceDrive}"
fi

# map parameters

sourcePath=""
targetPath=""
ignoreExistingFiles=0
silent=1

# TODO: define your mappings here - e.g.:

if  [[ "$backupOption" == "photos" ]]; then # NOTE: this is just an example
  sourcePath="all_photos"
  targetPath="bulk_data"
  ignoreExistingFiles=1 # in this example case we do not want to alter existing files
fi

if [ -z "$sourcePath" ]; then
  echo "UNKNOWN BACKUP OPTION: $backupOption"
  helpFunction
fi

if [ -z "$targetPath" ]; then
  echo "UNKNOWN BACKUP OPTION: $backupOption"
  helpFunction
fi

# the example source path will look something like this: /d/all_photos
# the example target path will look something like this: ./bulk_data/photos
completeSourcePath="$sourceDrive$sourcePath" # will always be an absolute path
completeTargetPath="./$targetPath/$backupOption" # will always be a relative path to the location of this script

echo "========== MAPPED PARAMETERS =========="

echo "completeSourcePath = $completeSourcePath"
echo "completeTargetPath = $completeTargetPath"

if [ ! -d "$completeSourcePath" ]; then
  echo "The source path does not exist: $completeSourcePath"
  exit 1
fi

# check source directory configuration

if [ ! -f "${completeSourcePath}/.backupable" ]; then
  echo "MISSING .backupable FILE IN: $completeSourcePath"
  exit 1
fi

# run the script

# TODO: use the correct path of the backup_utils - this example asserts, that a current version of the backup utils is located right next to this script
./backup_utils/modules/cloneSourceDirectoryToTargetDirectory.sh "$completeSourcePath" "$completeTargetPath" $ignoreExistingFiles $silent

echo "==========  BACKUP FINISHED  =========="
