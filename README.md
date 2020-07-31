# ArdorPi

![ArdorPi Dashboard](https://github.com/mrv777/ArdorPi/raw/master/ardorPiScreen.png)

## RaspberryPi Image with Ardor preinstalled
- Ardor already installed and bootstrapped
- Node set as archival and openAPI
- Starts Ardor up on boot as a service
- Automatically checks for updates daily and will apply them if found
- Pretty homepage with links to wallet, test api page, and ardordocs currently
- Can build the image yourself customizing some settings and getting newest kernel if you wanted

### Instructions
Download here: [Prebuild Image](https://ardor.tools/ardor-raspbian-lite.zip)  
Flash using [Etcher](https://www.balena.io/etcher/)  
Boot Pi and you should be able to access the dashboard with http://{{IP of RaspberryPi}}

#### Login
Username: ardor  
Password: pi

## Build yourself

Tested on Ubuntu 18.04.4 LTS

- sudo apt -y install coreutils quilt parted qemu-user-static debootstrap zerofree zip dosfstools bsdtar libcap2-bin grep rsync xz-utils file git curl bc
- git clone https://github.com/mrv777/pi-gen.git (You could also try the newest version here, but untested: https://github.com/RPi-Distro/pi-gen.git)
- cd pi-gen
- wget https://github.com/mrv777/ArdorPi/raw/master/ardorpi.sh
- echo "pi" | sudo bash ./ardorpi.sh (You can change **pi** to whatever password you want to set for the user Ardor)