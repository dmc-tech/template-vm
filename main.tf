data "azurerm_client_config" "current" {}

resource "random_id" "vm" {
  byte_length = 8
}

resource "azurerm_resource_group" "vm_rg" {
    provider            = azurerm.infra
    name                = lower("${var.resource_group_name_suffix}-${var.op_env}-${var.location_identifier}-${var.project_name}-${var.vm_purpose}-${var.vm_count}")
    location            = var.resource_group_location
}

data "azurerm_virtual_network" "spoke" {
    provider            = azurerm.infra
    name                = "vnet-${var.op_env}-uks-vm-spoke-001"
    resource_group_name = "${var.resource_group_name_suffix}-${var.op_env}-uks-vm-spoke-001"
}

data "azurerm_shared_image" "rocky_linux_85" {
    provider            = azurerm.shared
    name                = "vmimg-linux-gen2-rocky-8.5"
    gallery_name        = "con_uks_sig_001"
    resource_group_name = "${var.resource_group_name_suffix}-con-uks-sig-001"
}

data "azurerm_subnet" "spoke" {
    provider             = azurerm.infra
    name                 = "snet-${var.op_env}-uks-vm-spoke-001-001"
    virtual_network_name = "vnet-${var.op_env}-uks-vm-spoke-001"
    resource_group_name  = "${var.resource_group_name_suffix}-${var.op_env}-uks-vm-spoke-001"

}

data "azurerm_subnet" "svc" {
    provider             = azurerm.infra
    name                 = "snet-${var.op_env}-uks-svc-spoke-001-001"
    virtual_network_name = "vnet-${var.op_env}-uks-svc-spoke-001"
    resource_group_name  = "${var.resource_group_name_suffix}-${var.op_env}-uks-svc-spoke-001"

}

# Storage account to store binaries, scripts etc.

# resource "random_id" "storage_account" {
#   byte_length = 8
# }

# resource "azurerm_storage_account" "sa2" {
#   provider                       = azurerm.infra
#   name                           = substr("${lower(var.project_name)}${lower(var.op_env)}${lower(var.vm_purpose)}cr${lower(random_id.storage_account.hex)}",0,24)
#   resource_group_name            = azurerm_resource_group.vm_rg.name
#   location                       = azurerm_resource_group.vm_rg.location
#   account_kind                   = "StorageV2"
#   account_tier                   = "Standard"
#   account_replication_type       = "LRS"
#   public_network_access_enabled     = false
#   network_rules {
#     default_action               = "Deny"
#   }
# }

# data "azurerm_private_dns_zone" "svc_blob" {
#   name                = "privatelink.blob.core.windows.net"
#   resource_group_name = "${var.resource_group_name_suffix}-dev-uks-svc-spoke-001"
# }

# resource "azurerm_private_endpoint" "sa2" {
#   name                = "${azurerm_storage_account.sa2.name}-pep"
#   location            = azurerm_resource_group.vm_rg.location
#   resource_group_name = azurerm_resource_group.vm_rg.name
#   subnet_id           = data.azurerm_subnet.svc.id
#   private_service_connection {
#     name                           =  "${lower(var.project_name)}${lower(var.vm_purpose)}-pscon"
#     private_connection_resource_id = azurerm_storage_account.sa2.id
#     is_manual_connection           = false
#     subresource_names              = ["blob"]
#   }
#   depends_on = [
#      azurerm_storage_account.sa2
#   ]
# }
# resource "azurerm_private_dns_a_record" "dns_a" {
#   name                = "${azurerm_storage_account.sa2.name}-arecord"
#   zone_name           = data.azurerm_private_dns_zone.svc_blob.name
#   resource_group_name = data.azurerm_private_dns_zone.svc_blob.resource_group_name
#   ttl                 = 300
#   records             = [azurerm_private_endpoint.sa2.private_service_connection.0.private_ip_address]
#   depends_on = [
#      azurerm_storage_account.sa2
#   ]
# }

# resource "azurerm_storage_container" "assets" {
#   provider              = azurerm.infra
#   name                  = "assets"
#   storage_account_name  = azurerm_storage_account.sa2.name
#   container_access_type = "private"
#   depends_on = [
#      azurerm_private_dns_a_record.dns_a
#   ]
# }

# data "azurerm_storage_account_sas" "sa2" {
#   connection_string = azurerm_storage_account.sa2.primary_connection_string
#   https_only        = true
#   signed_version    = "2017-07-29"

#   resource_types {
#     service   = true
#     container = true
#     object    = true
#   }

#   services {
#     blob  = true
#     queue = false
#     table = false
#     file  = false
#   }

#   start  = timestamp()
#   expiry = timeadd(timestamp(), "8760h")

#   permissions {
#     read    = true
#     write   = true
#     delete  = false
#     list    = false
#     add     = true
#     create  = true
#     update  = false
#     process = false
#     tag     = false
#     filter  = false
#   }
# }

# resource "azurerm_storage_blob" "vm_vm_install" {
#   provider               = azurerm.infra
#   name                   = "vm-vm-install.sh"
#   storage_account_name   = azurerm_storage_account.sa2.name
#   storage_container_name = azurerm_storage_container.assets.name
#   type                   = "Block"
#   content_md5            = filemd5("./scripts/vm-vm-install.sh")
#   source                 = "./scripts/vm-vm-install.sh"

#   depends_on = [
#      azurerm_storage_container.assets
#   ]
# }

# resource "azurerm_storage_blob" "nix_tarball" {
#   provider               = azurerm.infra
#   name                   = "nix-2.16.1-x86_64-linux.tar.xz"
#   storage_account_name   = azurerm_storage_account.sa2.name
#   storage_container_name = azurerm_storage_container.assets.name
#   type                   = "Block"
#   content_md5            = filemd5("./nix/nix-2.16.1-x86_64-linux.tar.xz")
#   source                 = "./nix/nix-2.16.1-x86_64-linux.tar.xz"

#   depends_on = [
#      azurerm_storage_container.assets
#   ]
# }
# resource "azurerm_storage_blob" "nix_tarball_sha256" {
#   provider               = azurerm.infra
#   name                   = "nix-2.16.1-x86_64-linux.tar.xz.sha256"
#   storage_account_name   = azurerm_storage_account.sa2.name
#   storage_container_name = azurerm_storage_container.assets.name
#   type                   = "Block"
#   content_md5            = filemd5("./nix/nix-2.16.1-x86_64-linux.tar.xz.sha256")
#   source                 = "./nix/nix-2.16.1-x86_64-linux.tar.xz.sha256"

#   depends_on = [
#      azurerm_storage_container.assets
#   ]
# }

resource "azurerm_network_interface" "spoke" {
  name                = "vm-${var.op_env}-${var.location_identifier}-${var.project_name}-${var.vm_purpose}${var.vm_count}-nic"
  resource_group_name = azurerm_resource_group.vm_rg.name
  location            = var.resource_group_location

  ip_configuration {
    name                          = "ip1"
    subnet_id                     = data.azurerm_subnet.spoke.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_managed_disk" "vm_data" {
  name                 = "vm-${var.op_env}-${var.location_identifier}-${var.project_name}-${var.vm_purpose}${var.vm_count}-disk1"
  location             = azurerm_resource_group.vm_rg.location
  resource_group_name  = azurerm_resource_group.vm_rg.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size
}

resource "azurerm_virtual_machine_data_disk_attachment" "buildcr-data" {
  depends_on = [
    azurerm_managed_disk.vm_data,
    azurerm_linux_virtual_machine.vm
  ]
  managed_disk_id    = azurerm_managed_disk.vm_data.id
  virtual_machine_id = azurerm_linux_virtual_machine.vm.id
  lun                = var.data_disk_lun
  caching            = "ReadWrite"
}

resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}


resource "azurerm_linux_virtual_machine" "vm" {
  name                  = "vm-${var.op_env}-${var.location_identifier}-${var.project_name}-${var.vm_purpose}${var.vm_count}"
  location              = var.resource_group_location
  resource_group_name   = azurerm_resource_group.vm_rg.name
  network_interface_ids = [azurerm_network_interface.spoke.id]
  size                  = "Standard_D4s_v3"
  admin_username        = var.user_name

  admin_ssh_key {
        username = var.user_name
        public_key = tls_private_key.pk.public_key_openssh 
    }

 

  source_image_id = data.azurerm_shared_image.rocky_linux_85.id

    os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    disk_size_gb = 256
  }
  tags = {
    environment = "dev"
  
  }

  provisioner "local-exec" { # Create a "myKey.pem" to your computer!!
    command = "echo '${tls_private_key.pk.private_key_pem}' > ./vm-${var.op_env}-${var.location_identifier}-${var.project_name}-${var.vm_purpose}${var.vm_count}.pem"
  }
}

# resource "azurerm_virtual_machine_extension" "install_vm_config" {
#   name                 = "installvmHost"
#   virtual_machine_id   = azurerm_linux_virtual_machine.vm.id
#   publisher            = "Microsoft.Azure.Extensions"
#   type                 = "CustomScript"
#   type_handler_version = "2.1"
#   depends_on = [
#      azurerm_linux_virtual_machine.vm,
#      azurerm_storage_blob.vm_vm_install,
#      azurerm_storage_blob.nix_tarball,
#      azurerm_storage_blob.nix_tarball_sha256
#   ]

#   settings = <<SETTINGS
#     {
#       "fileUris": [
#                    "${azurerm_storage_blob.vm_vm_install.id}${data.azurerm_storage_account_sas.sa2.sas}&sr=b",
#                    "${azurerm_storage_blob.nix_tarball.id}${data.azurerm_storage_account_sas.sa2.sas}&sr=b",
#                    "${azurerm_storage_blob.nix_tarball_sha256.id}${data.azurerm_storage_account_sas.sa2.sas}&sr=b"                ]
#     }
# SETTINGS

# protected_settings = <<PROTECTED_SETTINGS
#     {
#       "commandToExecute": "sh vm-vm-install"
#     }
# PROTECTED_SETTINGS

# }

resource "null_resource" "output_pem_local" {
  
  triggers = {
    always_run = "${timestamp()}"
  }
   provisioner "local-exec" {
    command = "echo '${tls_private_key.pk.private_key_pem}' > ./vm-${var.op_env}-${var.location_identifier}-${var.project_name}-${var.vm_purpose}${var.vm_count}.pem"
  }
}


output "ip" {
  value = azurerm_network_interface.spoke.private_ip_address
}

output "ssh" {
  value = "ssh -i ./vm-${var.op_env}-${var.location_identifier}-${var.project_name}-${var.vm_purpose}${var.vm_count}.pem ${var.user_name}@${azurerm_network_interface.spoke.private_ip_address}"
}