#!/bin/bash

on_password_already_changed() {
  # ensure that 'filename' is only the name of the script without the path
  filename=$(echo $0 | rev | cut -d "/" -f 1 |rev)
  sed -i -z "s|if \[ -f $HOME/$filename ]; then\n  bash $HOME/$filename\nfi||g" "$HOME/.bashrc"
  rm $0
}

default_password="password"

my_user=$(whoami)
echo "$default_password" | su $my_user &>/dev/null
exit_state=$?

if [ $exit_state -eq 0 ]; then
  echo -e "*** WARNING: The default password '""$default_password""' for $my_user has not been changed. This is a HUGE security risk! Change your password immediatly.\n"
  if ! passwd; then
    echo -e "\n Setting up a new password failed, you can repeat the process everytime by entering the following command:\n\n\tpasswd\n\n"
  else
    echo "** PASSOWRD CHANGED SUCCESSFULLY"
    on_password_already_changed
  fi
else
  on_password_already_changed
fi 
