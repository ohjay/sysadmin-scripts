# sysadmin-scripts
Utility BASH scripts for basic system administration. Once downloaded, a script in this repository can be run from Bash shells via the command ./[script-filepath] or via aliasing 

## Options
These scripts can be made into permanent commands (like `echo` or `grep`, for example) fairly easily. There are more than one ways to do this:

- Create a $HOME/bin folder with `mkdir $HOME/bin`, and add the script to that folder (perhaps through `mv [script-filepath] $HOME/bin`). Put $HOME/bin on the PATH with the command `export PATH=$PATH:$HOME/bin`. If you want to execute the command à la builtin command (i.e. without the "sh" extension), feel free to delete aforementioned extension.
- Alternatively, you can create an alias for the command. A temporary alias can be created with "alias command-name='./[script-filepath]', while a permanent alias will require the same command to be added to the ~/.bash_profile and/or ~/.bashrc file.

##  Troubleshooting + FAQ
- **I don't have permission to execute the file!** 

⋅⋅⋅You can give yourself execute permission via the command `chmod +x [script-filepath]`.
