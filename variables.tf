

variable "infra_sub_id" {
    default       = ""
}

variable "shared_sub_id" {
    default       = ""
}

variable "owner" {
  default       = ""
  description   = "Resource owner"
}

variable "solution" {
  default = ""
}

variable "resource_group_name_suffix" {
  default       = "rg"
  description   = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "op_env" {
    default     = "asdk"
}

variable "resource_group_location" {
  default = "uksouth"
  description   = "Location of the resource group."
}

variable "location_identifier" {
  default       = "uks"
  description   = "TLA for location"
}

variable "vm_purpose" {
    default     = "tpl"
    description = "identifier for the VM purpose - e.g. nex = Nexus 3 Repository"
}

variable "vm_count" {
    default     = "001"
    description = " vm instance"
}

variable "project_name" {
    default     = "dse"
}

variable "data_disk_size" {
    default = 100
}


variable "data_disk_lun" {
  default    = 1
}

variable "user_name" {
  default = "azureuser"
}