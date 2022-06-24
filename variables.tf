variable "nac_scheduler_resource_group_name" {
  description = "Resouce group name for Azure Virtual Machine"
  type        = string
  default     = "demovmtest"
}

variable "nac_scheduler_resource_group_location" {
  description = "Resouce group location for Azure Virtual Machine"
  type        = string
  default     = "eastus"
}

variable "pem_key_file" {
  description = "Key Name with extension with location"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "az_key_name" {
  description = "Key Name without extension with location"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "vnet_rs_group_name" {
  description = "Resouce group name of provided_vnet"
  type        = string
  default     = "AzResource-01"
}

variable "subnet_available" {
  description = "Available subnet name in provided Vnet"
  type        = string
  default     = "Private"
}

variable "azurerm_virtual_network_name" {
  description = "Virtual Network Name for Azure Virtual Machine"
  type        = string
  default     = "DemoVnet"
}

variable "azurerm_subnet_name" {
  description = "Subnet Name for Azure Virtual Machine"
  type        = string
  default     = "mySubnet"
}

variable "azurerm_public_ip_name" {
  description = "Public IP Name for Azure Virtual Machine"
  type        = string
  default     = "myPublicIP"
}

variable "azurerm_network_security_group_name" {
  description = "Network Security Group Name for Azure Virtual Machine"
  type        = string
  default     = "myNetworkSecurityGroup"
}

variable "azurerm_network_interface_name" {
  description = "Network Interface Name for Azure Virtual Machine"
  type        = string
  default     = "myNIC"
}

variable "ip_configuration_name" {
  description = "IP Configuration Name for Azure Virtual Machine"
  type        = string
  default     = "myNicConfiguration"
}

variable "azurerm_linux_virtual_machine_name" {
  description = "Linux Virtual Machine Name"
  type        = string
  default     = "myVM"
}

variable "use_private_ip" {
  description = "To Provision Azure Virtual Machine in provided network"
  type        = string
  default     = "N"
}

# variable "vnet_available" {
#   description = "To Provision Azure Virtual Machine in provided network"
#   type        = string
#   default     = "Y"
# }
