# Raspberry-Pi-Init

These project can be used to initialize your Raspberry Pi after its first boot.

* `init_pi.sh`: Main script. Pi will reboot after
* `variables.conf: Variables to be configured. 
* `delete_pi_user.sh`: Demands the user to delete the default `pi` user. During the execution of `init_pi.sh`, a new user is created, but the default `pi` user remains on the system. This is a potential security risk. That is why, after the Raspberry Pi reboots in the end of the execution of `init_pi.sh`, `delete_pi_user.sh` is called at every login until the default `pi` user has been deleted. 
* `set_new_password.sh`: Script to make the user change the default password from `variables.conf`. After `init_pi.sh` has been run successfully, the pi will reboot. After this, `set_new_password.sh` is called at every login until the user has changed the default password. 


These scripts have been tested successfully on the models Raspberry Pi B+, 3B, 4, and Zero WH.

## Run Scripts

Set up the variable to your needs in `variables.conf`. After this, create a folder `/boot/scripts/` and copy all files to this folder. Su to root, cd in that folder and then run `init_pi.sh` with `variables.conf` as argument:

