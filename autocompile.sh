#!/bin/bash
LG='\033[1;32m'
NC='\033[0m' # No Color

# Auto updater, disable with auto_update=0
currentver=v1.1.0
auto_update=1
if [ $auto_update = 1 ]; then
  echo Checking for newer versions...
  newestver=$(timeout 1 curl -s https://api.github.com/repos/MichielVerloop/sacAutocompiler/releases/latest \
    | grep tag_name \
    | cut -d : -f 2 \
    | tr -d "\", ")
  retval=$?
  # If it didn't time out and the versions don't match, get the newest version.
  if [[ $newestver != "" ]]; then
    if [[ "$(printf '%s\n' "$newestver" "$currentver" | sort -V | head -n1)" \
      != "$newestver" ]]; then 
      echo Found a newer version, starting download.
      curl -s https://api.github.com/repos/MichielVerloop/sacAutocompiler/releases/latest \
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
echo -e ${LG}Now detecting file changes in $PWD.${NC}
2> /dev/null inotifywait -r -e close_write,moved_to,create -m . |
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
    fi
  fi
done