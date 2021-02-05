#!/bin/bash
LG='\033[1;32m'
NC='\033[0m' # No Color

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