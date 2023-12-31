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
folder=/media/spooky2
files=$folder/Data
generators=( CH{1..8}.txt )
backups=$HOME/.spooky2_backups
presets=$HOME/.spooky2_presets
preset=$presets/"$2"

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
  date=$(date +"%d.%m.%4Y")
  for g in "${generators[@]}"; do
    find "$files" -type f -name "$g" -print0 | while read -r -d '' file; do
      # Create a backup
      if [ ! -d "$backups/$date" ]; then
        mkdir -p "$backups/$date"
      fi
      cp -rp "$files/$g" "$backups/$date/$g"
    done
  done
  echo ""
  echo "Channel presets successfully backed up to:"
  echo ""
  echo "$backups/$date"
  echo ""
}

restore_backup_presets() {
  backups=$(ls "$backups")
  preset=("$backups")
  # Credit: https://stackoverflow.com/a/23953375
  menu() {
    clear
    echo "Avaliable backup presets:"
    for i in "${!preset[@]}"; do
      printf "%3d%s) %s\n" $((i+1)) "${choices[i]:- }" "${preset[i]}"
    done
    [[ "$msg" ]] && echo "$msg"; :
  }

  prompt="Check an option (again to uncheck, ENTER when done): "
  while menu && read -rp "$prompt" num && [[ "$num" ]]; do
    [[ "$num" != *[![:digit:]]* ]] && (( num > 0 && num <= ${#preset[@]} )) || {
      msg="Invalid option: $num"; continue
    }
    ((num--)); msg="${preset[num]} was ${choices[num]:+un}checked"
    [[ "${choices[num]}" ]] && choices[num]="" || choices[num]="[+]"
  done

  printf "You selected"; msg=" nothing"
  for i in "${!preset[@]}"; do
    [[ "${choices[i]}" ]] && { printf " %s" "${preset[i]}"; msg=""; }
  done
  echo "$msg"
  for g in "${generators[@]}"; do
    find "$files" -type f -name "$g" -print0 | while read -r -d '' file; do
      # Restore files
      cp -rp "$backups/$msg$g" "$files/$g"
      echo ""
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
  presets=$(ls "$presets")
  preset=($presets)

  # Credit: https://stackoverflow.com/a/23953375
  menu() {
    clear
    echo "Avaliable presets:"
    for i in "${!preset[@]}"; do
      printf "%3d%s) %s\n" $((i+1)) "${choices[i]:- }" "${preset[i]}"
    done
    [[ "$msg" ]] && echo "$msg"; :
  }

  prompt="Check an option (again to uncheck, ENTER when done): "
  while menu && read -rp "$prompt" num && [[ "$num" ]]; do
    [[ "$num" != *[![:digit:]]* ]] && (( num > 0 && num <= ${#preset[@]} )) || {
      msg="Invalid option: $num"; continue
    }
    ((num--)); msg="${preset[num]} was ${choices[num]:+un}checked"
    [[ "${choices[num]}" ]] && choices[num]="" || choices[num]="[+]"
  done

  printf "You selected"; msg=" nothing"
  if ! [[ $msg == "nothing" ]]; then
    echo "$msg..."
    exit
  fi
  for i in "${!preset[@]}"; do
    [[ "${choices[i]}" ]] && { printf " %s" "${preset[i]}"; msg=""; }
  done
  echo "$msg"
  for g in "${generators[@]}"; do
    find "$files" -type f -name "$g" -print0 | while read -r -d '' file; do
      # Create a backup before restoring files
      backup_presets
      # Restore files
      cp -rp "$presets/$msg$g" "$files/$g"
    done
  done
  echo "Go to Utils > Rescan devices to use as preset for all generators"
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