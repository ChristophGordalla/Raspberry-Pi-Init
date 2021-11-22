#!/bin/bash

if id "pi" &>/dev/null; then
    echo -e "\n*** WARNING: User 'pi' still exists. This is a potential security risk. Remove user 'pi' with the command:\n\n\tsudo userdel -r -f pi\n\n"
else
    # ensure that 'filename' is only the name of the script without the path
    filename=$(echo $0 | rev | cut -d "/" -f 1 | rev)
    sed -i -z "s|if \[ -f $HOME/$filename ]; then\n  bash $HOME/$filename\nfi||g" "$HOME/.bashrc"
    rm $0
fi
