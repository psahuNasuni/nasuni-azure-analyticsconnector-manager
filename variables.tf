variable "user_resource_group_name" {
  description = "Resouce group name for Azure Virtual Machine"
  type        = string
  default     = ""
}

variable "region" {
  description = "Resouce group region for Azure Virtual Machine"
  type        = string
  default     = "eastus"
}

variable "pem_key_path" {
  description = "Key Name with extension and location"
  type        = string
  default     = ""
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

variable "azure_username" {
  description = "Azure Subscription Scheduler User Name"
  type        = string
  default     = ""
}

variable "azure_password" {
  description = "Azure Subscription Password"
  type        = string
  default     = ""
}

variable "github_organization" {
  description = "github organization used by Users, default is nasuni-labs"
  default     = "psahuNasuni"
}

variable "git_repo_ui" {
  description = "git_repo_ui specific to certain repos"
  default     = "nasuni-azure-userinterface"
}

variable "acs_resource_group" {
  description = "git_repo_ui specific to certain repos"
  default     = ""
}

variable "acs_key_vault" {
  description = "git_repo_ui specific to certain repos"
  default     = ""
}
