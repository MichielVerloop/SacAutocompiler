# SacAutocompiler
The autocompile shell script will listen for files changes in its directory and subdirectories, automatically compiling any changed .sac files. 
If the compilation succeeds, it will also run the file.

## Features
* Automatically compiles .sac files in its directory and subdirectories.
* Runs the compiled file if the compilation is succesful.
* Automatically updates to a newer version of the script if available. (Can be disabled)

## Requirements
* A working version of the sac compiler on your path
* The tool inotify-tools should be installed. It will automatically install if it is not yet installed.
