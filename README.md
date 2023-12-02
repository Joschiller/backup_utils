# backup_utils

This repository contains helper scripts for backup tasks.

## `./backupSetup.sh`

> **To use this script, a local clone of tis repository must exist next to where the backup script should be initialized!**
>
> If a backup script should be initialized at a location `./backup.sh`, the clone of this repository must be located at `./backup_utils`.

Using this script, a local backup directory structure can be created. This directory structure is set up to use the `./backupRepositories.sh` script below.

The script can be run with the following options:

> `./backupSetup.sh <-i | -c> <file-name> [<option> <value> ...]`

| Option                      | Explanation                                                                                                                                                                   |
| :-------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `-i <file-name>`            | initializes a local backup script (if not provided, the file extension `.sh` will be added to the file name) - accepts the further option `-u`                                |
| `-c <file-name>`            | changes the configuration within the local backup script (if not provided, the file extension `.sh` will be added to the file name) - expects the further option `-u` or `-a` |
| `-u <0 \| 1>`               | enables (`1`) or disables (`0`) the git pull on the `backup_utils` that may be performed before running the backup script                                                     |
| `-a <relative-folder-path>` | overhand a directory name that shall be initialized for a backup                                                                                                              |

> After configuring the backup script, the backup can be run by simply executing the script.

## `./backupRepositories.sh`

> **To use this script, Git must be installed locally!**

This script runs the backup for all repositories given in a `.config` file by cloning them to a local location. By default, a config file with the name `backupRepositories.config` will be used that is contained in the current working directory. The backup folders will also be put in the same folder.

The config file must contain a list of repository URLs that will be cloned or pulled.

> Be aware, that repositories are only cloned if no folder with their name exists next to the config file. Otherwise, a `git pull` will be performed. Meaning: repository names cannot occur several times within the same target backup folder!

The script can be run with the following commands and options:

> `./backupRepositories.sh -r <command> [-v <value>] [<option> <value> ...]`

| Command  | Expected Value     | Explanation                                  |
| :------- | :----------------- | :------------------------------------------- |
| `backup` |                    | runs the backup process                      |
| `add`    | `<repository-url>` | adds a repository to the `.config` file      |
| `remove` | `<repository-url>` | removes a repository from the `.config` file |

| Option                      | Explanation                                                                         |
| :-------------------------- | :---------------------------------------------------------------------------------- |
| `-c <relative-file-path>`   | overhand a different config file relative to the current working directory          |
| `-d <relative-folder-path>` | overhand a different target backup folder relative to the current working directory |
