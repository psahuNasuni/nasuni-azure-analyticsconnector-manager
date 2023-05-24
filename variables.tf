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

variable "sp_application_id" {
  description = "Azure Service Priincipal Client ID"
  type        = string
  default     = ""
}

variable "sp_secret" {
  description = "Azure Service Priincipal Secret"
  type        = string
  default     = ""
}

variable "github_organization" {
  description = "github organization used by Users, default is nasuni-labs"
  default     = "psahuNasuni"
}

variable "git_repo_ui" {
  description = "git_repo_ui for userinterface specific repo"
  default     = "nasuni-azure-userinterface"
}

variable "git_branch" {
  default = ""
}

variable "acs_resource_group" {
  description = "acs resource group"
  default     = ""
}

variable "acs_admin_app_config_name" {
  description = "Azure acs_admin_app_config_name"
  type        = string
  default     = ""
}

variable "edgeappliance_resource_group" {
  description = "Resouce group name for Azure Virtual Machine"
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

variable "use_private_ip" {
  description = "Use Private IP"
  type        = string
  default     = "N"
}

variable "search_outbound_subnet" {
  description = "Available subnet name in Virtual Network for outbound traffic integration."
  type        = string
  default     = ""
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  default     = ""
}

variable "networking_resource_group" {
  description = "Resouce group of networking"
  type        = string
  default     = ""
}