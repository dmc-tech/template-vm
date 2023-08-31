# Nexus 3 VM deployment

This repo contains the Github Runner Nix deployment to a Rocky Linux VM.

## Tasks

### create-nexus-vm

Inputs: ENV, INSTANCE_NUMBER

The following Terraform template will deploy a Rocky Linux VM with a 256Gib OS disk and 100GiB Data disk. It is intended to run the full deployment, but environmental issues (with storage account endpoints) mean this cannot currently be achieved.

Pre-reqs:
* installation of [terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
   It will be run from Linux/WSL due to the supporting scripts being written in Bash.
* [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=dnf)

| Parameter Name| Values| Description|
|-|-|-|
|```ENV```| e.g "dev" "pre_prod" "prod" |it is used to refer to an environment setup file located in the ./env folder. For valid entries, check the folder and look for the file name pattern env_variables_<ENV>.sh (e.g. [env_variables_***dev***.sh](./env/env_variables_dev.sh))  |
|```INSTANCE_NUMBER```| VM instance number | instance of the runner. Make Unique to create a new runner|

The ENV instance calls a script located in ./env and setups up the environment, such as subscription names, Azure Tags, Region etc. New files can be derived from the [env_variables_dev.sh](./env/env_variables_dev.sh) file and modified as required. rename the file, e.g. ```env_variables_***pre_prod***.sh```

Ensure the user authenticating to Azure has Contributor rights to the Azure Subscription where creating the VM

```sh
az login --use-device-code
sh ./deploy-runner.sh -e $ENV -c $INSTANCE_NUMBER

```
Once the VM is created, the pem will be created in the current dir, with the name of the VM, and the IP address of the VM will be displayed.

### prep-vm-disk

The terraform created VM needs the disk extending and mounting. /tmp needs remounting to allow exec so the Nix installer will work

```sh
sudo su
DATA_DISK_LUN=1
MNT_DIR=data
pvcreate /dev/disk/azure/scsi1/lun$DATA_DISK_LUN
vgcreate datavg /dev/disk/azure/scsi1/lun$DATA_DISK_LUN
lvcreate -l 100%FREE -n datalv datavg
mkfs.xfs /dev/mapper/datavg-datalv
mkdir /$MNT_DIR
echo "/dev/mapper/datavg-datalv    /$MNT_DIR    xfs    defaults    0    2" >> /etc/fstab
mount /$MNT_DIR
exit
# Expand the disk. Original was 60GB. We need room so OS disk is provisioned as 256GB

sudo growpart /dev/sda 3

sudo pvresize /dev/sda3

# extend the root and home volumes
sudo lvextend -r -l +60%FREE /dev/mapper/vg1-root
sudo lvextend -r -l +60%FREE /dev/mapper/vg1-home

sudo mount -o remount,exec /tmp

```

