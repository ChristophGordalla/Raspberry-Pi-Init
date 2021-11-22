#!/bin/bash

set -e


if [ -f $HOME/.ssh/id_rsa ]; then
  echo -e "\n** Public key authentification is enabled. To login with public private keys, copy the private key to your local machine."
  echo -e "To do so, make sure that an .ssh folder exists in your local machine and enter the following command from the home folder of your LOCAL MACHINE:"
  echo -e "\n\tscp $user@<IP_OF_PI>:/home/$user/.ssh/id_rsa .ssh/\n"
  echo -e "** AFTERWARDS delete the private key on your pi by entering the following command on your PI:"
  echo -e "\n\trm /home/$user.ssh/id_rsa\n\n"
  echo -e "Keeping the private key on the pi is a SECURITY RISK. Take action as described above."
else
  filename=$(echo $0 | rev | cut -d "/" -f 1 |rev)
  sed -i -z "s|if \[ -f $HOME/$filename ]; then\n  bash $HOME/$filename\nfi||g" "$HOME/.bashrc"
  rm $0
fi

