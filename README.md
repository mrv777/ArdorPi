# ArdorPi
## RaspberryPi Image with Ardor preinstalled

![ArdorPi Dashboard](https://github.com/mrv777/ArdorPi/raw/master/ardorPiScreen.png)

[Prebuild Image](https://ardor.tools/ardor-raspbian-lite.zip)
Flash using [Etcher](https://www.balena.io/etcher/)

#### Login
Username: ardor
Passwod: pi

## Build yourself

Tested on Ubuntu 18.04.4 LTS

- sudo apt -y install coreutils quilt parted qemu-user-static debootstrap zerofree zip dosfstools bsdtar libcap2-bin grep rsync xz-utils file git curl bc
- git clone https://github.com/mrv777/pi-gen.git
- cd pi-gen
- wget https://github.com/mrv777/ArdorPi/raw/master/ardorpi.sh
- echo "pi" | sudo bash ./ardorpi.sh (You can change **pi** to whatever password you want to set for the user Ardor)