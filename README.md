# spooky2-presets
 Script to make generator group presets
 
 - Takes a "snapshot" of a range of generators with named preset
   - This can later be used and restored as running programs
 - Takes dated backups (can be set up as a cron job)
 - Option to restore from backups

 ### Installation

 Download script

 ```bash
 curl -sSL -o ~/.scripts/spooky2_preset.sh  https://github.com/tmiland/spooky2-presets/raw/main/spooky2_preset.sh
 ```

 Symlink:
 ```bash
  ln -sfn ~/.scripts/spooky2_preset.sh ~/.local/bin/spooky2_preset
 ```

Create credentials file:

```bash
touch /root/.spooky2_credentials
```
with content:
```bash
username=YOURUSER
password=YOURPASSWORD
```
Give permissions:
```bash
sudo chmod 400 /root/.spooky2_credentials
```
Mount spooky2 folder (**Change username**):

```bash
# Mount Spooky2 smb disk on boot
//192.168.1.100/spooky2 /media/spooky2 cifs rw,user=YOURUSER,uid=1000,gid=1000,iocharset=utf8,suid,credentials=/root/.spooky2_credentials,file_mode=0664,dir_mode=0777 0 0
```

Change to mounted spooky2 network share in script:
```bash
folder=/media/spooky2
```

Forders that will be created:

```bash
backups=$HOME/.spooky2_backups
presets=$HOME/.spooky2_presets
```

Change to the amount of gens you need (range E.g: (1..4 or 4..8)) in script:
```bash
generators=( CH{1..8}.txt )
```

## Usage

```bash
Usage: spooky2_preset [option]

  --create-preset     | -cp           create preset
  --use-preset        | -up           use preset
  --backup            | -b            backup presets
  --restore-backup    | -rb           restore backup presets
```

#### Disclaimer 

*** ***Use at own risk*** ***

### License

[![MIT License Image](https://upload.wikimedia.org/wikipedia/commons/thumb/0/0c/MIT_logo.svg/220px-MIT_logo.svg.png)](https://github.com/tmiland/spooky2-presets/blob/master/LICENSE)

[MIT License](https://github.com/tmiland/spooky2-presets/blob/master/LICENSE)