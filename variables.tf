variable "user_rg_name" {
  description = "Resouce group name for Azure Virtual Machine"
  type        = string
  default     = ""
}

variable "region" {
  description = "Resouce group region for Azure Virtual Machine"
  type        = string
  default     = "eastus"
}

variable "pem_key_file" {
  description = "Key Name with extension and location"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "az_key" {
  description = "Key Name without extension and with location"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "user_vnet_name" {
  description = "Virtual Network Name for Azure Virtual Machine"
  type        = string
  default     = ""
}

variable "user_subnet_name" {
  description = "Available subnet name"
  type        = string
  default     = ""
}

variable "public_ip_name" {
  description = "Public IP Name for Azure Virtual Machine"
  type        = string
  default     = "NACSchedulerIP"
}

variable "nsg_name" {
  description = "Network Security Group Name for Azure Virtual Machine"
  type        = string
  default     = "NACSchedulerNSG"
}

variable "network_interface_name" {
  description = "Network Interface Name for Azure Virtual Machine"
  type        = string
  default     = "NACSchedulerNIC"
}

variable "nac_scheduler_name" {
  description = "NAC Scheduler Virtual Machine Name"
  type        = string
  default     = ""
}