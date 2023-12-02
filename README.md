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

## Example Setup for These Scripts

In the following example, a directory structure is given, where the backups should be stored as follows:

```
./
|-- backup_utils/
    |-- backupRepositories.sh
    \-- backupSetup.sh
|-- firstRepositoryBackup/
    |-- someRepository/
        \-- ... some files within the repository ...
    \-- backup.config
|-- secondRepositoryBackup/
    |-- someRepository/
        \-- ... some files within the repository ...
    \-- backup.config
\-- backup.sh
```

Using `./backup_utils/backupSetup.sh` the configuration of this backup structure could be created as follows:

```sh
# 1. create local clone of the backup_utils
git clone https://github.com/Joschiller/backup_utils

# 2. init
./backup_utils/backupSetup.sh -i backup
# to disable the automatic pull on the backup_utils, add `-u 0` at the end

# 3. setup directories
./backup_utils/backupSetup.sh -c backup -a ./firstRepositoryBackup

./backup_utils/backupSetup.sh -c backup -a ./secondRepositoryBackup

# 4. add repositories to backup
./backup_utils/backupRepositories.sh -r add -v https://firstDomain.com/.../someRepository -c ./firstRepositoryBackup/backup.config

./backup_utils/backupRepositories.sh -r add -v https://secondDomain.com/.../someRepository -c ./secondRepositoryBackup/backup.config
```

To run the backup, `./backup.sh` can then be executed.
