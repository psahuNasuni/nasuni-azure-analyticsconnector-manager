locals {
  nsg_rules = {

    ssh = {
      name                       = "SSH"
      description                = "SSH Rule"
      priority                   = 300
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      source_port_ranges         = ["0-65535"]
      destination_port_ranges    = ["22"]
    }

    http = {
      name                       = "HTTP"
      description                = "HTTP Rule"
      priority                   = 310
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      source_port_ranges         = ["0-65535"]
      destination_port_ranges    = ["80"]
    }

  }
}

resource "random_id" "unique_sg_id" {
  byte_length = 2
}

data "azurerm_resource_group" "nac_scheduler_rg" {
  name = var.user_rg_name
}

data "azurerm_virtual_network" "VnetToBeUsed" {
  name                = var.user_vnet_name
  resource_group_name = var.user_rg_name
}

data "azurerm_subnet" "azure_subnet_name" {
  name                 = var.user_subnet_name
  virtual_network_name = var.user_vnet_name
  resource_group_name  = var.user_rg_name
}

resource "azurerm_public_ip" "nac_scheduler_public_ip" {
  name                = "${var.public_ip_name}-${random_id.unique_sg_id.dec}"
  location            = data.azurerm_resource_group.nac_scheduler_rg.location
  resource_group_name = data.azurerm_resource_group.nac_scheduler_rg.name
  allocation_method   = "Dynamic"

  depends_on = [data.azurerm_resource_group.nac_scheduler_rg]
}

resource "azurerm_network_security_group" "NACSchedulerSecurityGroup" {
  name                = "${var.nsg_name}-${random_id.unique_sg_id.dec}"
  location            = data.azurerm_resource_group.nac_scheduler_rg.location
  resource_group_name = data.azurerm_resource_group.nac_scheduler_rg.name

  depends_on = [data.azurerm_resource_group.nac_scheduler_rg]
}

resource "azurerm_network_security_rule" "NACSchedulerSecurityGroupRule" {
  for_each                    = local.nsg_rules
  name                        = each.key
  description                 = each.value.description
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  source_port_ranges          = each.value.source_port_ranges
  destination_port_ranges     = each.value.destination_port_ranges
  resource_group_name         = data.azurerm_resource_group.nac_scheduler_rg.name
  network_security_group_name = azurerm_network_security_group.NACSchedulerSecurityGroup.name

  depends_on = [azurerm_network_security_group.NACSchedulerSecurityGroup]
}

resource "azurerm_network_interface" "nac_scheduler_nic_public" {
  name                = "${var.network_interface_name}-${random_id.unique_sg_id.dec}"
  location            = data.azurerm_resource_group.nac_scheduler_rg.location
  resource_group_name = data.azurerm_resource_group.nac_scheduler_rg.name

  ip_configuration {
    name                          = "NACScheduler_nic_ip"
    subnet_id                     = data.azurerm_subnet.azure_subnet_name.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.nac_scheduler_public_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "nac_scheduler_nisg_association" {
  network_interface_id      = azurerm_network_interface.nac_scheduler_nic_public.id
  network_security_group_id = azurerm_network_security_group.NACSchedulerSecurityGroup.id
}

resource "azurerm_linux_virtual_machine" "NACScheduler" {
  name                = var.nac_scheduler_name
  location            = data.azurerm_resource_group.nac_scheduler_rg.location
  resource_group_name = data.azurerm_resource_group.nac_scheduler_rg.name
  network_interface_ids = [
    azurerm_network_interface.nac_scheduler_nic_public.id
  ]
  size = "Standard_D2s_v3"

  os_disk {
    name                 = "NACScheduler_Disk-${random_id.unique_sg_id.dec}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = var.nac_scheduler_name
  admin_username                  = "ubuntu"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "ubuntu"
    public_key = file("${var.pem_key_file}")
  }
}

resource "null_resource" "Install_Packages" {
  provisioner "remote-exec" {
    inline = [
      "echo '@@@@@@@@@@@@@@@@@@ STARTED - Install Packages @@@@@@@@@@@@@@@@@@'",
      "sudo apt update",
      "sudo apt upgrade -y",
      "sudo apt install curl bash ca-certificates git openssl wget vim zip unzip dos2unix -y",
      "sudo apt update",
      "echo '****************** Installing Terraform ******************'",
      "sudo wget https://releases.hashicorp.com/terraform/1.1.9/terraform_1.1.9_linux_amd64.zip",
      "sudo unzip *.zip",
      "sudo mv terraform /usr/local/bin/",
      "terraform -v",
      "which terraform",
      "sudo apt install jq -y",
      "echo '****************** Installing Python ******************'",
      "sudo apt install python3 -y",
      "sudo apt install python3-testresources -y",
      "sudo apt install python3-pip -y",
      "sudo pip3 install boto3",
      "echo '******************  Installing AZURE CLI ******************'",
      "curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash",
      "sudo apt-get update",
      "echo '@@@@@@@@@@@@@@@@@@ FINISHED - Install Packages @@@@@@@@@@@@@@@@@@'"
    ]

    connection {
      type        = "ssh"
      host        = azurerm_linux_virtual_machine.NACScheduler.public_ip_address
      user        = "ubuntu"
      private_key = file("${var.az_key}")
    }
  }

  depends_on = [
    azurerm_linux_virtual_machine.NACScheduler,
    azurerm_network_security_rule.NACSchedulerSecurityGroupRule
  ]
}