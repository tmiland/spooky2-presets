#!/usr/bin/env bash
# shellcheck disable=SC2030,SC2031,SC2015,SC2221,SC2222,SC2059,SC2206

## Author: Tommy Miland (@tmiland) - Copyright (c) 2023


######################################################################
####                     spooky2_presets.sh                       ####
####              Automatic spooky2 presets script                ####
####           Script to make generator group presets             ####
####                   Maintained by @tmiland                     ####
######################################################################

#VERSION='1.0.0' # Must stay on line 14 for updater to fetch the numbers

#------------------------------------------------------------------------------#
#
# MIT License
#
# Copyright (c) 2023 Tommy Miland
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
#------------------------------------------------------------------------------#
## Uncomment for debugging purpose
# set -o errexit
# set -o pipefail
# set -o nounset
# set -o xtrace
year=$(date +"%4Y")
month=$(date +"%m")
day=$(date +"%d")
time=$(date +"%H-%M-%S")

folder=/media/spooky2
folder2=/media/spooky2-zwift-pc
folder3=/media/spooky2-laptop-pc
files=$folder/Data
files2=$folder2/Data
files3=$folder3/Data
preset_collections="$folder/Preset Collections/User"
preset_collections2="$folder2/Preset Collections/User"
preset_collections3="$folder3/Preset Collections/User"

scandata="$folder/ScanData"
scandata2="$folder2/ScanData"
scandata3="$folder3/ScanData"

custom_databases="$folder/Custom Databases"
custom_databases2="$folder2/Custom Databases"
custom_databases3="$folder3/Custom Databases"

generators=( CH{1..6}.txt )
backup_generators=( CH{1..9}.txt )
backup_generators2=( CH{7..9}.txt )
backups="$preset_collections/Backup"
#backups2="$preset_collections2/Backup"
reverse_lookup_folder="$preset_collections/Biofeedback/Reverse Lookup"
reverse_lookup_folder2="$preset_collections2/Biofeedback/Reverse Lookup"
reverse_lookup_folder3="$preset_collections3/Biofeedback/Reverse Lookup"
presets=$backups/.spooky2_presets
preset=$presets/"$2"
win_host=192.168.1.16
win_user=Reserve

# Set backup2 on/off - default on
BACKUP2=${BACKUP2:-off}

# For renaming preset settings
# files="/media/spooky2/Preset Collections/User"
# presets=( *.txt )

# for p in "${backup_generators[@]}"; do
#   find "$files" -type f -name "$p" -print0 | while read -r -d '' file; do
#     sed -i -e 's|"Auto_Resume=False"|"Auto_Resume=True"|g' "$file"
#     sed -i -e 's|"Manual_Start=True"|"Manual_Start=False"|g' "$file"
#   done
# done

reboot() {
  if ! dpkg -s samba-common >/dev/null 2>&1; then
    sudo apt-get install samba-common
  fi
  net rpc shutdown -r -I "$win_host" -U "$win_user"
}

create_reverse_lookup_folder() {
  rlf="$reverse_lookup_folder/$year/$month/$day"
  if [ ! -d "$rlf" ]; then
    mkdir -p "$rlf"
  fi
  if [[ -d $files2 ]]; then
    rlf2="$reverse_lookup_folder2/$year/$month/$day"
    if [ ! -d "$rlf2" ]; then
      mkdir -p "$rlf2"
    fi
  else
    echo "Location: $files is not available..."
    exit
  fi
}

create_preset() {
  if [[ ! -d "$preset" ]]; then
    mkdir -p "$preset"
  elif [[ -d "$preset" ]]; then
    echo ""
    read -rp "Found a folder with that name... Do you want to overwrite? [y/n] " ANSWER
    echo ""
    case $ANSWER in
      [Yy]* )
        echo "overwriting..."
        ;;
      [Nn]* )
        exit 1
        ;;
      * ) echo "Enter Y, N or Q, please." ;;
    esac
  fi

  for g in "${generators[@]}"; do
    find "$files" -type f -name "$g" -print0 | while read -r -d '' file; do
      cp -rp "$file" "$preset/$g"
    done
  done
  echo ""
  echo "Preset(s) has been successfully copied"
  echo ""
  echo "location:" "$file" "$preset"
  echo ""
}

rsync_args=-aqhutPt

channel_sync() {
  # Sync CH7.txt from laptop-pc to main spooky2-pc
  #rsync $rsync_args --include "CH7.txt" --exclude "*" "$files3"/ "$files"
  cp -rp "$files3/CH7.txt" "$files/"
  # Sync CH8.txt from laptop-pc to main spooky2-pc
  #rsync $rsync_args --include "CH8.txt" --exclude "*" "$files3"/ "$files"
  cp -rp "$files3/CH8.txt" "$files/"
}

scandata_sync() {
  # Take not the folder A but all of its content and put it into folder B (with the slash)
  # https://unix.stackexchange.com/a/203854
  # Sync from main spooky2 pc to zwift-pc
  rsync $rsync_args "$scandata/" "$scandata2"
  # Sync from main spooky2 pc to laptop-pc
  rsync $rsync_args "$scandata/" "$scandata3"
  # Sync from zwift-pc to main spooky2 pc
  rsync $rsync_args "$scandata2/" "$scandata"
  # Sync from laptop-pc to main spooky2 pc
  rsync $rsync_args "$scandata3/" "$scandata"
  # Sync from laptop-pc to zwift-pc
  rsync $rsync_args "$scandata3/" "$scandata2"
}

preset_collection_sync() {
  # Take not the folder A but all of its content and put it into folder B (with the slash)
  # https://unix.stackexchange.com/a/203854
  # Sync from main spooky2 pc to zwift-pc
  rsync $rsync_args "$preset_collections/" "$preset_collections2"
  # Sync from main spooky2 pc to laptop-pc
  rsync $rsync_args "$preset_collections/" "$preset_collections3"
  # Sync from zwift-pc to main spooky2 pc
  rsync $rsync_args "$preset_collections2/" "$preset_collections"
  # Sync from laptop-pc to main spooky2 pc
  rsync $rsync_args "$preset_collections3/" "$preset_collections"
}

custom_database_sync() {
  # Sync from main spooky2 pc to zwift-pc
  rsync $rsync_args --exclude={/backup/,/old/} "$custom_databases/" "$custom_databases2"
  # Sync from main spooky2 pc to laptop-pc
  rsync $rsync_args --exclude={/backup/,/old/} "$custom_databases/" "$custom_databases3"
  # Sync Custom.csv from main spooky2 pc to laptop-pc
  rsync $rsync_args --include "Custom.csv" --exclude "*" "$folder"/ "$folder2"
  # Sync Custom.csv from main spooky2 pc to zwift-pc
  rsync $rsync_args --include "Custom.csv" --exclude "*" "$folder"/ "$folder3"
  # Sync Custom.csv from zwift-pc to main spooky2 pc
  rsync $rsync_args --include "Custom.csv" --exclude "*" "$folder2"/ "$folder"
  # Sync Custom.csv from laptop-pc to main spooky2 pc
  rsync $rsync_args --include "Custom.csv" --exclude "*" "$folder3"/ "$folder"
}

sync() {
  channel_sync
  scandata_sync
  preset_collection_sync
  custom_database_sync
}
# interval="86400" # 24 hours
# interval="3600" # 1 hour
interval="60" # 1 minute
interval_sync() {
  while true
  do
    sync
    echo "Sleeping $interval seconds till the next update..."
    sleep $interval
  done
}

backup_presets() {
  create_reverse_lookup_folder
  bfolder="$year/$month/$day/$time"
  if [[ -d $files ]]; then
    for g in "${backup_generators[@]}"; do
      find "$files" -type f -name "$g" -print0 | while read -r -d '' file; do
        # Create a backup
        if [ ! -d "$backups/$bfolder" ]; then
          mkdir -p "$backups/$bfolder"
        fi
        cp -rp "$files/$g" "$backups/$bfolder/$g"
      done
    done
  else
    echo "Location: $files is not available..."
    exit
  fi
  if [ "$BACKUP2" = "on" ]; then
    if [[ -d $files2 ]]; then
      for g in "${backup_generators2[@]}"; do
        find "$files2" -type f -name "$g" -print0 | while read -r -d '' file; do
          # Create a backup from files2 to files, then rsync from files back to files2
          cp -rp "$files2/$g" "$backups/$bfolder/$g"
          rsync -aq "$backups" "$preset_collections2"
        done
      done
    else
      echo "Location: $files2 is not available..."
      exit
    fi
  fi
  echo ""
  echo "Channel presets successfully backed up to:"
  echo ""
  echo "$backups/$bfolder"
  echo ""
}

cron_backup_presets() {
  backups_array=$(ls "$backups/$year/$month/$day")
  bfolder="$backups_array"
  for g in "${backup_generators[@]}"; do

    # if cmp --silent -- "$files/$g" "$bfolder/$g"; then
    #   echo "$files/$g" is equal to "$backups/$bfolder/$g"
    # else
    #   echo "$files/$g" is older than "$backups/$bfolder/$g"
    # fi

    if [[ "$files/$g" -nt "$backups/$bfolder/$g" ]]; then
      #backup_presets
      echo "$files/$g" is newer to "$backups/$bfolder/$g"
      # else
      #   echo "$files/$g" is older than "$backups/$bfolder/$g"
    fi
  done
}

restore_backup_presets() {
  presets_array=$(ls "$backups")
  year_dirs=($presets_array)

  read -rp "$(
          f=0
          # shellcheck disable=SC2068
          for d in ${year_dirs[@]} ; do
                  echo "$((++f)): $d"
          done

          echo -ne "Please select a directory > "
  )" selection

  year_selected_dir="${year_dirs[$((selection-1))]}"

  echo "You selected $year_selected_dir"
  #############################
  month_presets_array=$(ls "$backups/$year_selected_dir")
  month_dirs=($month_presets_array)

  read -rp "$(
          f=0
          # shellcheck disable=SC2068
          for d in ${month_dirs[@]} ; do
                  echo "$((++f)): $d"
          done

          echo -ne "Please select a directory > "
  )" selection

  month_selected_dir="$year_selected_dir/${month_dirs[$((selection-1))]}"

  echo "You selected $month_selected_dir"
  #############################
  day_presets_array=$(ls "$backups/$month_selected_dir")
  day_dirs=($day_presets_array)

  read -rp "$(
        f=0
        # shellcheck disable=SC2068
        for d in ${day_dirs[@]} ; do
                echo "$((++f)): $d"
        done

        echo -ne "Please select a directory > "
  )" selection

  day_selected_dir="$month_selected_dir/${day_dirs[$((selection-1))]}"

  echo "You selected $day_selected_dir"
  #############################
  time_presets_array=$(ls "$backups/$day_selected_dir")
  time_dirs=($time_presets_array)

  read -rp "$(
          f=0
          # shellcheck disable=SC2068
          for d in ${time_dirs[@]} ; do
                  echo "$((++f)): $d"
          done

          echo -ne "Please select a directory > "
  )" selection

  time_selected_dir="$day_selected_dir/${time_dirs[$((selection-1))]}"

  echo "You selected $time_selected_dir"
  #############################
  for g in "${backup_generators[@]}"; do
    find "$backups/$time_selected_dir" -type f -name "$g" -print0 | while read -r -d '' file; do
      # Restore files
      cp -rp "$backups/$time_selected_dir/$g" "$files/$g"
    done
  done
  echo ""
  echo "Preset(s) has been successfully restored"
  echo ""
  echo "location:" "From: $backups" "To: $files"
  echo ""
  echo "Go to Utils > Rescan devices to use as preset(s) for all generators"
}

use_preset() {

  presets_array=$(ls "$presets")
  dirs=($presets_array)

  read -rp "$(
          f=0
          # shellcheck disable=SC2068
          for d in ${dirs[@]} ; do
                  echo "$((++f)): $d"
          done

          echo -ne "Please select a directory > "
  )" selection

  selected_dir="${dirs[$((selection-1))]}"

  echo "You selected $selected_dir"
  # Create a backup before restoring files
  backup_presets
  for g in "${generators[@]}"; do
    find "$presets/$selected_dir" -type f -name "$g" -print0 | while read -r -d '' file; do
      # Restore files
      cp -rp "$presets/$selected_dir/$g" "$files/$g"
    done
  done
  echo ""
  read -rp "Do you want to reboot the remote computer? [y/n] " reboot
  echo ""
  case $reboot in
    [Yy]* )
      reboot
      echo "rebooting..."
      ;;
    [Nn]* )
      exit 1
      ;;
    * ) echo "Enter Y, N or Q, please." ;;
  esac
  echo "Go to Utils > Rescan devices to use channel presets"
}

usage() {
  # shellcheck disable=SC2046
  printf "Usage: %s %s [option]\\n" "" $(basename "$0")
  echo
  printf "  --create-preset     | -cp           create preset\\n"
  printf "  --use-preset        | -up           use preset\\n"
  printf "  --backup            | -b            backup presets\\n"
  printf "  --backup-sync       | -bs           backup and sync presets\\n"
  printf "  --sync              | -s            run folder sync\\n"
  printf "  --restore-backup    | -rb           restore backup presets\\n"
  printf "\\n"
  echo
}

ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --help | -h)
      usage
      exit 0
      ;;
    --create-preset | -cp)
      shift
      create_preset
      ;;
    --use-preset | -up)
      shift
      use_preset
      ;;
    --backup | -b)
      shift
      backup_presets
      ;;
    --backup-sync | -bs)
      shift
      echo "Running sync before backup..."
      sync
      echo "Done."
      backup_presets
      echo "Running sync after backup..."
      sync
      echo "Done."
      ;;
    --sync | -s)
      shift
      echo "Running sync..."
      sync
      echo "Done."
      ;;
    --interval-sync | -is)
      shift
      interval_sync
      ;;
    --cron-backup | -cb)
      shift
      cron_backup_presets
      ;;
    --restore-backup | -rb)
      shift
      restore_backup_presets
      ;;
    -*|--*)
      printf "Unrecognized option: %s\\n\\n" "$1"
      usage
      exit 1
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done

set -- "${ARGS[@]}"