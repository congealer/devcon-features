#!/usr/bin/env bash
set -e

USERNAME=$(id -un)

# The CLI resolves _REMOTE_USER_HOME by looking the user up in the base image,
# in a build step that runs before any Feature does. It therefore comes through
# empty when an earlier Feature is the one that creates the user, as
# common-utils does when given a 'username' that the image does not have. Look
# it up again here, where /etc/passwd is current. 'installsAfter' is what makes
# this lookup succeed.
if [ -z "$_REMOTE_USER_HOME" ]; then
  _REMOTE_USER_HOME=$(getent passwd "$_REMOTE_USER" | cut -d: -f6)
fi
[ -n "$_REMOTE_USER_HOME" ] || {
  echo "Could not resolve the home directory of '$_REMOTE_USER'"
  exit 1
}

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


# prezto is a zsh framework, so zsh is not optional: install it when the image
# does not already carry it. git is needed for the clone below.
# 'ca-certificates' is only a Recommends of git, so with --no-install-recommends
# the CA bundle never gets built and the clone below fails with "Problem with
# the SSL CA cert". It is not a command, hence the file test.
missing=""
hash zsh 2>/dev/null || missing="$missing zsh"
hash git 2>/dev/null || missing="$missing git"
[ -f /etc/ssl/certs/ca-certificates.crt ] || missing="$missing ca-certificates"
if [ -n "$missing" ]; then
  echo "Installing:$missing"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y --no-install-recommends $missing
  rm -rf /var/lib/apt/lists/*
fi

# install.sh runs as root, so everything below has to be handed to the remote
# user. On the bare distro images that user *is* root and sudo is not installed,
# so only reach for sudo when the two actually differ.
if [ "$(id -un)" = "$_REMOTE_USER" ]; then
  run_as_user() { "$@"; }
else
  run_as_user() { sudo -u "$_REMOTE_USER" "$@"; }
fi

# Applied before the early exit below, so that installing onto an image which
# already carries prezto still honours the option. The CLI passes options
# through as the option id in upper case.
if [ "${SETZSHASDEFAULT:-true}" = "true" ]; then
  echo "Setting zsh as the login shell for $_REMOTE_USER"
  chsh -s "$(command -v zsh)" "$_REMOTE_USER"
fi

marker_begin="# >>> devcontainer extraZshrc >>>"
marker_end="# <<< devcontainer extraZshrc <<<"

# Not an early exit, so that the extraZshrc option below is honoured on an
# image which already carries prezto.
if [ -d $prezto_dir ]
then
  echo "Prezto already installed, skipping the clone and the symlinks."
else
  echo ""
  echo "Git cloning Prezto into $prezto_dir"
  run_as_user git clone --recursive https://github.com/sorin-ionescu/prezto.git $prezto_dir || {
    echo "Failed to clone prezto into $prezto_dir"
    exit 1
  }

  echo ""
  for rcfile in $(find "$_REMOTE_USER_HOME"/.zprezto/runcoms -type f -not -name "README.md"); do
    dest="$_REMOTE_USER_HOME/.$(basename $rcfile)"
    if [ -f $dest ] || [ -h $dest ]
    then
      backup="$dest.prezto_backup"
      echo "Backing up $dest to $backup"
      run_as_user mv $dest $backup
    fi
    echo "Linking $rcfile to $dest"
    run_as_user ln -s -f $rcfile $dest
  done

  if [ -f "$(dirname $0)/zpreztorc" ]
  then
    run_as_user mv $_REMOTE_USER_HOME/.zprezto/runcoms/zpreztorc $_REMOTE_USER_HOME/.zprezto/runcoms/zpreztorc_org
    run_as_user cp "$(dirname $0)/zpreztorc" $_REMOTE_USER_HOME/.zprezto/runcoms/zpreztorc
  fi
fi

# ~/.zshrc is the symlink to this runcom, whose last line invites exactly this
# ("Customize to your needs...").
if [ -n "${EXTRAZSHRC:-}" ]
then
  runcom="$prezto_dir/runcoms/zshrc"
  echo "Appending the extra lines to $runcom"
  # Drop the block an earlier run left behind, so that installing twice does
  # not stack the same lines up.
  run_as_user sed -i "/$marker_begin/,/$marker_end/d" "$runcom"
  cat <<EOF | run_as_user tee -a "$runcom" > /dev/null
$marker_begin
$EXTRAZSHRC
$marker_end
EOF
fi

echo "Prezto is now installed. Login into, or reload zsh to activate."
