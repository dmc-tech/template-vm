#!/bin/bash

# This script is intended to setup a Rocky Linux VM so it is has the tools and config to run as a GitHub Actions Runner
# If required, on vm, install git and clone the githu-runner-vm repo locally. 
# The script is/was intended to be run as part of VM provisioning, but environmental issues (accessing storage accounts via private endoints) is currently inhibiting this.

# 

# Mount the disk provisioned as part of the Terraform deployment
set -xv
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# Change perms for the source directory
SOURCE_DIR=$(builtin cd $SCRIPT_DIR/..; pwd)
BASE_INSTALL_DIR=${SOURCE_DIR##*/}
INSTALL_TARGET=/opt



chmod 766 -R $SOURCE_DIR

export NEXUS_USERNAME=nexus

export NEXUS_VERSION='3.59.0-01'
export NEXUS_URL=https://download.sonatype.com/nexus/3/nexus-${NEXUS_VERSION}-unix.tar.gz


DATA_DISK_LUN=1
MNT_DIR=/data
sudo pvcreate /dev/disk/azure/scsi1/lun$DATA_DISK_LUN
sudo vgcreate datavg /dev/disk/azure/scsi1/lun$DATA_DISK_LUN
sudo lvcreate -l 100%FREE -n datalv datavg
sudo mkfs.xfs /dev/mapper/datavg-datalv
sudo mkdir $MNT_DIR
echo "/dev/mapper/datavg-datalv    $MNT_DIR    xfs    defaults    0    2" | sudo tee -a  /etc/fstab > /dev/null
sudo mount $MNT_DIR

# Expand the disk. Original was 60GB. We need room so OS disk is provisioned as 256GB

sudo growpart /dev/sda 3

sudo pvresize /dev/sda3

# extend the root and home volumes
sudo lvextend -r -l +60%FREE /dev/mapper/vg1-root
sudo lvextend -r -l +60%FREE /dev/mapper/vg1-home

sudo mount -o remount,exec /tmp


# Copy repo to shared area

sudo cp -r  $SOURCE_DIR $MNT_DIR/
sudo chmod 777 -R $MNT_DIR/$BASE_INSTALL_DIR

cd $MNT_DIR/$BASE_INSTALL_DIR

# Create nexus user
sudo adduser $NEXUS_USERNAME
sudo usermod -aG wheel $NEXUS_USERNAME

echo '%wheel ALL=(ALL) NOPASSWD:ALL' | sudo tee -a /etc/sudoers >/dev/null


# Java is needed...

sudo dnf install -y java-1.8.0-openjdk.x86_64

# Download Nexus

curl -L $NEXUS_URL --output nexus-${NEXUS_VERSION}-unix.tar.gz
sudo tar -xvzf ./nexus-${NEXUS_VERSION}-unix.tar.gz -C $INSTALL_TARGET

sudo mv $INSTALL_TARGET/nexus-3* $INSTALL_TARGET/nexus

sudo mv $INSTALL_TARGET/sonatype-work  $MNT_DIR/sonatype-work

sudo chown $NEXUS_USERNAME:$NEXUS_USERNAME -R $INSTALL_TARGET/nexus/
sudo chown $NEXUS_USERNAME:$NEXUS_USERNAME -R $MNT_DIR/sonatype-work/

printf 'run_as_user="%s"\n' "$NEXUS_USERNAME" | sudo tee $INSTALL_TARGET/nexus/bin/nexus.rc >/dev/null

# Change config locations in Java config file
sudo sed -i 's|\.\.\/sonatype-work|\/data\/sonatype-work|g' $INSTALL_TARGET/nexus/bin/nexus.vmoptions
sudo sed -i 's|-Dkaraf\.data=\.|-Dkaraf.data=\/data\/sonatype-work\/nexus3|g' $INSTALL_TARGET/nexus/bin/nexus.vmoptions
# .. And disable FIPS for Java, as it will cause errors and constant 'Initializing' in the web portal
echo -e '-Dcom.redhat.fips=false' | sudo tee -a $INSTALL_TARGET/nexus/bin/nexus.vmoptions >/dev/null


# Get ready for SSL certs

# create the ssl directory
sudo -u $NEXUS_USERNAME  mkdir $MNT_DIR/sonatype-work/nexus3/etc/ssl
# create staging directory for certs so nexus user can work with them
sudo mkdir $MNT_DIR/certs
sudo chown $NEXUS_USERNAME:$NEXUS_USERNAME $MNT_DIR/certs

# Create the service

cd $MNT_DIR/$BASE_INSTALL_DIR
sudo ln -s $INSTALL_TARGET/nexus/bin/nexus /etc/init.d/nexus
sudo cp ./nexus.service /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl enable nexus.service
sudo systemctl start nexus.service

# Allow the Nexus 3 ports
sudo firewall-cmd --add-port=8081/tcp
sudo firewall-cmd --add-port=8443/tcp

# to check Nexus is working:
# sudo tail -f $MNT_DIR/sonatype-work/nexus3/log/nexus.log

# get the admin password
# sudo cat $MNT_DIR/sonatype-work/nexus3/admin.password

log_file="$MNT_DIR/sonatype-work/nexus3/log/nexus.log"
desired_entry="Started Sonatype Nexus"

set +xv
echo "Waiting for  Nexus to start."
while true; do
    if sudo grep -q "$desired_entry" "$log_file"; then
        ADMIN_PASSWORD=$(sudo cat $MNT_DIR/sonatype-work/nexus3/admin.password)
        echo "Inital Nexus admin password: ${ADMIN_PASSWORD}"
        break
    else
        echo -n "."
        sleep 5  # Adjust the sleep duration as needed
    fi
done




