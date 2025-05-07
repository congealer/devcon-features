#!/usr/bin/env zsh
set -e

USERNAME=$(id -un)
prezto_dir="$_REMOTE_USER_HOME/.zprezto"
echo "Install 'prezto' on $_REMOTE_USER_HOME"

# The 'install.sh' entrypoint script is always executed as the root user.
#
# These following environment variables are passed in by the dev container CLI.
# These may be useful in instances where the context of the final 
# remoteUser or containerUser is useful.
# For more details, see https://containers.dev/implementors/features#user-env-var
echo "The effective dev container remoteUser is '$_REMOTE_USER'"
echo "The effective dev container remoteUser's home directory is '$_REMOTE_USER_HOME'"

echo "The effective dev container containerUser is '$_CONTAINER_USER'"
echo "The effective dev container containerUser's home directory is '$_CONTAINER_USER_HOME'"


hash zsh 2>/dev/null || { 
  echo "Zsh, isn't installed on your system, you're going to need to install that first."
  exit 1
}

if [ -d $prezto_dir ]
then
  echo "Prezto already installed, exiting installation."
  exit
fi

echo ""
echo "Git cloning Prezto into $prezto_dir"
hash git 2>/dev/null && sudo -u $_REMOTE_USER git clone --recursive https://github.com/sorin-ionescu/prezto.git $prezto_dir || {
  echo "git not installed"
  exit 1
}

echo ""
# Use find instead of zsh glob
for rcfile in $(find "$_REMOTE_USER_HOME"/.zprezto/runcoms -type f -not -name "README.md"); do
  dest="$_REMOTE_USER_HOME/.$(basename $rcfile)"
  if [ -f $dest ] || [ -h $dest ]
  then
    backup="$dest.prezto_backup"
    echo "Backing up $dest to $backup"
    sudo -u $_REMOTE_USER mv $dest $backup
  fi
  echo "Linking $rcfile to $dest"
  sudo -u $_REMOTE_USER ln -s -f $rcfile $dest
done

if [ -f "$(dirname $0)/zpreztorc" ]
then
  sudo -u $_REMOTE_USER mv $_REMOTE_USER_HOME/.zprezto/runcoms/zpreztorc $_REMOTE_USER_HOME/.zprezto/runcoms/zpreztorc_org
  sudo -u $_REMOTE_USER cp "$(dirname $0)/zpreztorc" $_REMOTE_USER_HOME/.zprezto/runcoms/zpreztorc
fi

echo "Prezto is now installed. Login into, or reload zsh to activate."
