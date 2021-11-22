# Raspberry-Pi-Init

## Initialization Script and Configuration File

These project can be used to initialize your Raspberry Pi after its first boot. For this the following script is used together with a configuration file:

* `init_pi.sh`: Main script. Pi will reboot after
* `variables.conf: Variables to be configured. 

The init script will perform the following tasks:

* Adjust settings for locales
* Install a list of given packages
* Change the Pi's hostname
* Assign static IPs to a given set of the Pi's network adapters (e.g. eth0 and wlan0) 
* Create a new user
* Enable SSH for that user and create a public private key pair.
* Create aliases for a given set of alias-command pairs
* Set the boot mode of the Pi

## Run Scripts

Set up the variable to your needs in `variables.conf`. After this, create a folder `/boot/scripts/` and copy all files to this folder. Su to root, cd in that folder and then run `init_pi.sh` with `variables.conf` as argument:

After a successful run the Raspberry Pi will reboot. 

## Additional Scripts for Further Tasks

Besides of this, there are further script files

* `delete_pi_user.sh`: Demands the user to delete the default `pi` user. During the execution of `init_pi.sh`, a new user is created, but the default `pi` user remains on the system. This is a potential security risk. That is why, after the Raspberry Pi reboots in the end of the execution of `init_pi.sh`, `delete_pi_user.sh` is called at every login until the default `pi` user has been deleted. 
* `move_ssh_key.sh`: Demands the user to move the private key. `init_pi.sh` creates a public-private-key pair where *both* keys are stored in the default location `.ssh/` in the user's home. This script will remind the user to copy the private key from the Raspberry Pi to the client computers from which he wants to connect to the Raspberry Pi. Having a copy of the private key still stored on the Raspberry Pi is considered a security rist. That is why this script will print a message to the user's login terminal until the private key is moved to a different location.
* `set_new_password.sh`: Script to make the user change the default password from `variables.conf`. After `init_pi.sh` has been run successfully, the pi will reboot. After this, `set_new_password.sh` is called at every login until the user has changed the default password. 


These scripts have been tested successfully on the models Raspberry Pi B+, 3B, 4, and Zero WH.


