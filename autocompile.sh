#!/bin/bash

## Features
# Automatically compiles .sac files in its directory and subdirectories.
# Runs the compiled file if the compilation is succesful.
# Automatically updates to a newer version of the script if available.
# Can optionally provide a specific directory to set up watches for.

## Requirements
# A working version of the sac compiler on your path
# The tool inotify-tools should be installed. It will automatically install 
#   if it is not yet installed.

# You can disable automatic updates by setting auto_update=0
auto_update=1
currentver=v1.2.1
RE='\u001b[31m' # Red
LG='\033[1;32m' # Light green
NC='\033[0m' # No Color

# Define usage
usage()
{
  echo "Usage: $0 [-d directory]"
  exit 2
}


# Handle launch arguments
root_listen_path=$PWD

while getopts 'd:?h' c
do
  case $c in
    d) root_listen_path=$OPTARG;;
    h|?) usage ;; esac
done

[ ! -d $root_listen_path ] && echo Argument d: \"$root_listen_path\" is not a valid path. && usage


# Auto updater, disable with auto_update=0
if [ $auto_update = 1 ]; then
  echo Checking for newer versions...
  newestver=$(timeout 1 curl -s https://api.github.com/repos/MichielVerloop/SacAutocompiler/releases/latest \
    | grep tag_name \
    | cut -d : -f 2 \
    | tr -d "\", ")
  retval=$?
  # If it didn't time out and the versions don't match, get the newest version.
  if [[ $newestver != "" ]]; then
    if [[ "$(printf '%s\n' "$newestver" "$currentver" | sort -V | head -n1)" \
      != "$newestver" ]]; then 
      echo Found a newer version, starting download.
      curl -s https://api.github.com/repos/MichielVerloop/SacAutocompiler/releases/latest \
      | grep "browser_download_url" \
      | cut -d : -f 2,3 \
      | tr -d \" \
      | wget -qi - -O autocompile.sh
      chmod +x autocompile.sh
      echo Download finished. Restarting autocompile.sh...
      sleep 1
      exec ./autocompile.sh
    fi
    echo This version is up-to-date. Continuing.
    sleep 1
  else # newestver = ""
    # Ideally we wouldn't make another request here, but saving the first 
    # response breaks grep because we lose the line breaks.
    if [[ $(timeout 1 curl -s https://api.github.com/repos/MichielVerloop/sacAutocompiler/releases/latest | grep "API rate limit exceeded" ) != "" ]]; then
      echo API rate limit exceeded. Continuing without updating.
    else 
      echo Version checking timed out. Continuing without updating.
    fi
    sleep 2
  fi
else
  echo Warning: auto-update is disabled.
  sleep 1
fi

clear
# Install inotify-tools if it is not yet installed
dpkg -s inotify-tools > /dev/null 2>&1 # hide stdout and stderr 
ret=$?
if [ $ret -ne 0 ] ; then
  echo -e ${LG}Package inotify-tools is not yet installed. Installing...${NC}
  sudo apt-get install inotify-tools -y
  for ((i=5; i > 0; i--)); do
    echo -ne ${LG}Install finished. Setting up the autocompilation program in $i seconds...\\r${NC}
    sleep 1
  done
  clear
fi

# Get notified of all events in this folder and the underlying folders.
echo -e ${LG}Now detecting file changes in $root_listen_path.${NC}
2> /dev/null inotifywait -r -e create,modify,moved_to,close_write -m $root_listen_path |
while read -r directory events filename; do
  if [[ "$filename" = *".sac" ]]; then
    clear
    filepath=$directory$filename # Necessary to access the recursive files properly.
    echo -e ${LG}Save detected: compiling $filepath.${NC}
    sac2c -check tc $filepath 
    ret=$?
    if [ $ret -eq 0 ] ; then
      echo -e ${LG}Compilation succesful: running a.out.${NC}
      ./a.out
      if [ $ret -eq 0 ] ; then
        echo -e ${LG}Run succeeded.${NC}
      else
        echo -e ${RE}Run failed.${NC}
      fi
    else
      echo -e ${RE}Compilation failed.
    fi
  fi
done
