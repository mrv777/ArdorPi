#!/bin/bash

# echo "$pass" | sudo -S ./build.sh
# echo "$pass" | sudo -S ./build.sh --clean

# Builds a Raspbian lite image with some customizations include default locale, username, pwd, host name, boot setup customize etc.
# Must be run on Debian Buster or Ubuntu Xenial and requires some "horsepower".

SECONDS=0
clean=false

while [[ $# -ge 1 ]]; do
    i="$1"
    case $i in
        -c|--clean)
            clean=true
            shift
            ;;
        *)
            echo "Unrecognized option $1"
            exit 1
            ;;
    esac
    shift
done

read -r -t 2 -d $'\0' pi_pwd

if [ -z "$pi_pwd" ]; then
  echo "Pi user password is required (pass via stdin)" >&2
  exit 1
fi

# Script is in /boot/setup, switch to non-root pi-gen path per install script. Assuming default pi user.
#pushd /home/pi/pi-gen

# setup environment variables to tweak config. SD card write script will prompt for WIFI creds.
cat > config <<EOL
export IMG_NAME=ardor-raspbian
export RELEASE=buster
export DEPLOY_ZIP=1
export LOCALE_DEFAULT=en_US.UTF-8
export TARGET_HOSTNAME=ardor-pi
export KEYBOARD_KEYMAP=us
export KEYBOARD_LAYOUT="English (US)"
export TIMEZONE_DEFAULT=America/New_York
export FIRST_USER_NAME=ardor
export FIRST_USER_PASS="${pi_pwd}"
export ENABLE_SSH=1
EOL

# Skip stages 3-5, only want Raspbian lite
touch ./stage3/SKIP ./stage4/SKIP ./stage5/SKIP
touch ./stage4/SKIP_IMAGES ./stage5/SKIP_IMAGES

pushd stage2

# don't need NOOBS
rm -f EXPORT_NOOBS || true


# ----- Begin Stage 02, Step 04 - Get Ardor Prereqs Step -----
step="04-ardor-install-prereq"
if [ -d "$step" ]; then rm -Rf $step; fi
mkdir $step && pushd $step

cat > 00-packages <<RUN
nginx unzip curl openjdk-8-jre jq
RUN

popd
# ----- End Stage 02, Step 04 - Get Ardor Prereqs Step -----

# ----- Begin Stage 02, Step 05 - Ardor Install Step -----
step="05-ardor-install"
if [ -d "$step" ]; then rm -Rf $step; fi
mkdir $step && pushd $step

ARDOR_MAINNET_FOLDER="ardor-mainnet"
ARDOR_MAINNET_SERVICE="ardor-mainnet"

NXT_MAINNET_PROPERTIES_FILE_CONTENT="
nxt.apiServerEnforcePOST=true
nxt.maxPrunableLifetime=-1
nxt.includeExpiredPrunable=true
nxt.apiServerHost=0.0.0.0
nxt.allowedBotHosts=*

## Contract Runnner Configuration ##
## see https://ardordocs.jelurida.com/Lightweight_Contracts for detailed informations ##
# nxt.addOns=nxt.addons.ContractRunner
# addon.contractRunner.secretPhrase=<secretphrase>
# addon.contractRunner.feeRateNQTPerFXT.IGNIS=250000000
"

ARDOR_MAINNET_SERVICE_FILE_CONTENT="
[Unit]
Description=Ardor-Mainnet
After=syslog.target
After=network.target

[Service]
RestartSec=2s
Type=simple
WorkingDirectory=/home/ardor/${ARDOR_MAINNET_FOLDER}/
ExecStart=/bin/bash /home/ardor/${ARDOR_MAINNET_FOLDER}/run.sh
Restart=always

[Install]
WantedBy=multi-user.target
"


cat > 00-run-chroot.sh <<RUN
#!/bin/bash
echo "Download and prepare Ardor"
wget https://www.jelurida.com/ardor-client.zip -q --show-progress
unzip -qq ardor-client.zip
mv ardor /home/ardor/ardor-mainnet

echo "" && echo "[INFO] downloading mainnet blockchain ..."
wget https://www.jelurida.com/Ardor-nxt_db.zip

echo "" && echo "[INFO] unzipping mainnet blockchain ..."
unzip Ardor-nxt_db.zip

echo "" && echo "[INFO] moving mainnet blockchain to ardor mainnet folder ..."
mv nxt_db/ /home/ardor/${ARDOR_MAINNET_FOLDER}/

echo "" && echo "[INFO] creating ardor mainnet configuration ..."
echo "${NXT_MAINNET_PROPERTIES_FILE_CONTENT}" > /home/ardor/${ARDOR_MAINNET_FOLDER}/conf/nxt.properties



echo "" && echo "[INFO] cleaning up ..."
sudo apt autoremove -y
rm -rf ardor-client.zip nxt_db.txt Ardor-nxt_db.zip

echo "" && echo "[INFO] creating ardor services ..."
sudo mkdir -p /etc/systemd/system
echo "${ARDOR_MAINNET_SERVICE_FILE_CONTENT}" | sudo tee /etc/systemd/system/${ARDOR_MAINNET_SERVICE}.service > /dev/null
sudo systemctl enable ${ARDOR_MAINNET_SERVICE}.service

echo "" && echo "[INFO] setting ownership of ardor folders ..."
sudo chown -R ardor:ardor /home/ardor/${ARDOR_MAINNET_FOLDER}

echo "" && echo "[INFO] creating update script ..."
wget https://raw.githubusercontent.com/mrv777/ArdorPi/master/update-nodes.sh
mv update-nodes.sh /home/ardor/
sudo chmod 700 /home/ardor/update-nodes.sh
(sudo crontab -l 2>> /dev/null; echo "0 2 * * *  /bin/bash /home/ardor/update-nodes.sh >/dev/null 2>&1") | sudo crontab -

echo "" && echo "[INFO] creating dashboard ..."
wget https://github.com/mrv777/ArdorPi/raw/master/ardorPiDash.zip
unzip ardorPiDash.zip -d /var/www/html
rm ardorPiDash.zip
RUN

chmod +x 00-run-chroot.sh

popd
# ----- End Stage 02, Step 05 - Ardor Install Step -----

popd # stage 02

# run build
if [ "$clean" = true ] ; then
    echo "Running build with clean to rebuild last stage"
    CLEAN=1 ./build.sh
else
    echo "Running build"
    ./build.sh
fi

exitCode=$?

duration=$SECONDS
echo "Build process completed in $(($duration / 60)) minutes"

if [ $exitCode -ne 0 ]; then
    echo "Custom Raspbian lite build failed with exit code ${exitCode}" ; exit -1
fi

ls ./deploy