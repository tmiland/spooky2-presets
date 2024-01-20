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
files=$folder/Data
generators=( CH{1..5}.txt )
backup_generators=( CH{1..8}.txt )
backups="$folder/Preset Collections/User/Backup"
presets=$HOME/.spooky2_presets
preset=$presets/"$2"
win_host=192.168.1.16
win_user=Reserve

reboot() {
  if ! dpkg -s samba-common >/dev/null 2>&1; then
    sudo apt-get install samba-common
  fi
  net rpc shutdown -r -I "$win_host" -U "$win_user"
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

backup_presets() {
  bfolder="$year/$month/$day/$time"
  for g in "${backup_generators[@]}"; do
    find "$files" -type f -name "$g" -print0 | while read -r -d '' file; do
      # Create a backup
      if [ ! -d "$backups/$bfolder" ]; then
        mkdir -p "$backups/$bfolder"
      fi
      cp -rp "$files/$g" "$backups/$bfolder/$g"
    done
  done
  echo ""
  echo "Channel presets successfully backed up to:"
  echo ""
  echo "$backups/$bfolder"
  echo ""
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
    --restore-backup | -rb)
      shift
      restore_backup_presets
      ;;
    -*|--*)
      printf "Unrecognized option: $1\\n\\n"
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