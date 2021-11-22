#!/bin/bash

##############################################################
###                                                        ###
###   Author: Christoph Gordalla                           ###
###   Date: 2021-09-23                                     ###
###                                                        ###
###   Use as root ('sudo -i'):                             ###
###                                                        ###
###     ./init_pi variables.conf                           ###
###                                                        ###
###                                                        ###
###   This scripts automates some basic configuration      ###
###   tasks after the first boot of the raspberry pi.      ###
###   A file with variables must be passed to the          ###
###   script as argument.                                  ###
###                                                        ###
###   The script assumes that a wifi connection has        ###
###   already been established by adding a pre-configured  ###
###   a 'wpa_supplicant.conf' file to /boot of the SD      ###
###   card with the Raspbian image.                        ###
###                                                        ###
##############################################################


set -e

script_password="set_new_password.sh"
script_move_ssh="move_ssh_key.sh"
script_delete_pi_user="delete_pi_user.sh"

# copy the scripts for what needs to be done 
# after the restart from /boot/scripts/
# to /home/$user/, change their ownerships,
# and adds a lines to /home/$user/.bashrc
# to make those lines executable
#
# $1 name of the file to be copied
copy_script() {
  path_script="/home/$user/"
  cp /boot/scripts/$1 $path_script
  chown "$user":"$group" $path_script$1
  echo -e "\nif [ -f $path_script$1 ]; then\n  bash $path_script$1\nfi\n" >> /home/$user/.bashrc
}

# set time zone and country
adjust_locales() {
  echo -e "\n\n\n*** LOCALE, COUNTRY AND TIME ZONE SETTINGS ***\n"
  
  etc_default_locale="/etc/default/locale"
  etc_locale_gen="/etc/locale.gen"
  
  # the following lines perform manually
  # what is done interactively by
  # 'sudo dpkg-reconfigure locales' 
  # (which in term is what 'raspi-config'
  # is calling when choosing the option
  # '5 Localisation Options' -> 'L1 Locale')	
  sed -i s/"# $loc_lang"/"$loc_lang"/g $etc_locale_gen
  sed -i s/"# $loc_non_lang"/"$loc_non_lang"/g $etc_locale_gen
  locale-gen
  update-locale LANG=$loc_lang LANGUAGE=$loc_lang
  . $etc_default_locale
  echo "** Updated locales $loc_lang for language related setting and $loc_non_lang for other locale settings"
  
  timedatectl set-timezone "$timezone"
  raspi-config nonint do_wifi_country "$country"  
  echo "** Adjusted time zone and wifi country settings"
}


# update repos and install additional packages
install_packages() {
  echo -e "\n\n\n*** UPDATING AND INSTALLING PACKAGES ***\n"
  
  apt update  
  #apt upgrade
  apt install ${packages_install[@]} -y
  apt remove ${packages_remove[@]} -y
  apt autoremove -y
}


# change the hostname of the raspberry pi
change_hostname() {
  echo -e "\n\n\n*** HOSTNAME SETTINGS ***\n"
  
  raspi-config nonint do_hostname "$hostname"
  echo "** Changed hostname to $hostname"
}


# assign static ips to the devices eth0 and wlan0
# and restart dhcp daemon 
assign_static_ips() {
  echo -e "\n\n\n*** SETTING STATIC IPS ***\n"
  
  devices=("eth0" "wlan0")
  dhcpcd_conf="/etc/dhcpcd.conf"
  resolv_conf="/etc/resolv.conf"
  
  ip_eth0="$ip_base""$((100+$number))"
  ip_wlan0="$ip_base""$((200+$number))"
  ips_device=($ip_eth0 $ip_wlan0)
  
  ip_router=$(ip r | grep default | cut -d " " -f 3)
  ips_dns=$(cat "$resolv_conf" | grep nameserver | cut -d " " -f 2)
  ip_dns_line=""
  
  iter=0
  for device in ${devices[@]}; do
    IP_PI=${ips_device[${iter}]}
    echo "interface "$device >> $dhcpcd_conf
    echo "static ip_address="$IP_PI >> $dhcpcd_conf
    echo "static routers="$ip_router >> $dhcpcd_conf
    echo "static domain_name_servers="${ips_dns[*]} >> $dhcpcd_conf
    echo "" >> $dhcpcd_conf
    echo "** Assigned IP $IP_PI to device $device"
    iter=$(expr $iter + 1)
  done
  
  #for device in ${devices[@]}; do
	#ip addr flush dev $device
  #done
  
  #systemctl stop dhcpcd
  #systemctl start dhcpcd
  #echo "** Stopped and started dhcp daemon"
}


# delete pi user and create a new default user with the same user groups as pi (includind 'sudo')
create_user() {
  echo -e "\n\n\n*** USER SETTINGS ***\n"
  
  default_password="password"
  
  # all groups of pi user except 'pi' group 
  groups_pi=$(groups pi |cut -d : -f 2 | cut -d " " -f 3- | tr " " ",")
  addgroup "$group"
  useradd -m -p $(perl -e 'print crypt($ARGV[0], "password")' "$default_password") "$user" -g "$group" -G "$groups_pi"
  echo -e "** Created new user $user in group $group with default password '""$default_password""'"
  echo -e "** IMMEDIATLY MODIFY THIS PASSWORD AT YOUR NEXT LOGIN BY ENTERING THE COMMAND:\n\n\tpasswd\n\n"
  echo -e "** Cannot delete user pi since this was the ssh login user. At your next login you can delete it by entering the command:\n\n\tsudo userdel -r -f pi\n\n"
  
  # copy script to request the user to change his password 
  copy_script "$script_password"
  # copy script to request the user to delete the pi user 
  copy_script "$script_delete_pi_user"
}


# enables ssh, creates a key pair for $user,
# and adjusts the sshd_config to allow key authentification
# from everywhere and password authentification 
# from ips within the the network of the pi only (e.g. 192.168.1.*)
set_ssh() {
  echo -e "\n\n\n*** SSH settings ***\n"
  
  sshd_conf="/etc/ssh/sshd_config"
  
  # enable ssh config
  if [ $(raspi-config nonint get_ssh) -eq 1 ]; then
    raspi-config nonint do_ssh 0
    echo "** Activated ssh daemon"
  fi
  
  # move public key from /boot or create a key pair
  mkdir /home/$user/.ssh
  if [ -f /boot/$public_key ]; then
    mv /boot/$public_key /home/$user/.ssh/
    echo "** Moved public key $public_key to /home/$user/.ssh/"
  else
    echo "** No public key file given. Will generate new public private key pair"
    private_key=$(echo $public_key | rev | cut -d "." -f 2- | rev)
    ssh-keygen -b 4096 -t rsa -N '' -f /home/$user/.ssh/$private_key -C "$user""@""$hostname"
    # copy script to request the user to move the private ssh key
    copy_script "$script_move_ssh"
    
    echo "** Created ssh keypair in /home/$user/.ssh/id_rsa"
    echo -e "\n** To login with public private keys, copy the private key to your local machine."
    echo -e "To do so, make sure that an .ssh folder exists in your local machine and enter the following command from the home folder of your LOCAL MACHINE:"
    echo -e "\n\tscp $user@$ip_base$((200+$number)):/home/$user/.ssh/id_rsa .ssh/\n"
    echo -e "** Afterwards delete the private key on your pi by entering the following command on your PI:"
    echo -e "\n\trm /home/$user/.ssh/id_rsa\n\n"
  fi
  cat /home/$user/.ssh/$public_key > /home/$user/.ssh/authorized_keys
  chown -R "$user":"$group" /home/$user/.ssh
  chmod 700 /home/$user/.ssh
  chmod 600 /home/$user/.ssh/authorized_keys  
  
  # modify ssh config
  echo "AllowUsers $user" >> $sshd_conf
  echo "PubkeyAuthentication yes" >> $sshd_conf
  echo "PasswordAuthentication no" >> $sshd_conf
  echo "Match address ""$ip_base""0/24" >> $sshd_conf
  echo "	PasswordAuthentication yes" >> $sshd_conf
  echo "** Adjusted $sshd_conf"
  
  #systemctl reload ssh
  echo -e "** Adjusted SSH config:"
  echo -e "**\t-Allowing only user $user"
  echo -e "**\t-Enabling public/private key authorization"
  echo -e "**\t-Password authentification is only possible from within the local network"
}


# creates some ls aliases for $user
create_aliases() {
  echo -e "\n\n\n*** CREATING ALIASES ***\n"
  
  bash_aliases="/home/$user/.bash_aliases"
  touch "$bash_aliases"
  chown "$user":"$group" "$bash_aliases"
  for alias in "${aliases[@]}"; do
    echo "alias $alias" >> $bash_aliases
  done
}


# set bootmode $bootmode
set_boot_mode() {
  echo -e "\n\n\n*** BOOTMOODE SETTINGS ***\n"
  
  raspi-config nonint do_boot_behaviour "$bootmode"
  echo "** Set bootmode $bootmode" 
}


# main method
# 
# $1 name of the configuration file with variable
# ('variables.conf' by default), this parameter should
# be $1 from the script itself
main() {
  if [ $# -ne 1 ]; then
    echo "ERROR: Expected config file as single argument." >&2
    exit 1
  fi
  
  filename=$1
  
  if [ ! -f $filename  ]; then
    echo "ERROR: File $filename does not exist." >&2
    exit 1
  fi
  
  source $filename
  
  hostname="$hostname_base""$number"
  
  adjust_locales
  install_packages
  change_hostname
  assign_static_ips
  create_user
  set_ssh
  create_aliases
  set_boot_mode
  
  reboot
}

main $1
