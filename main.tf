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

resource "azurerm_resource_group" "nac_scheduler_rs" {
  name     = var.nac_scheduler_resource_group_name
  location = var.nac_scheduler_resource_group_location
}

data "azurerm_virtual_network" "provided_vnet" {
  name                = var.azurerm_virtual_network_name
  resource_group_name = var.vnet_rs_group_name
}

data "azurerm_subnet" "provided_subnet" {
  name                 = var.subnet_available
  virtual_network_name = data.azurerm_virtual_network.provided_vnet.name
  resource_group_name  = var.vnet_rs_group_name
}

# resource "azurerm_virtual_network" "nac_scheduler_vnet" {
#   count               = var.vnet_available == "Y" ? 0 : 1
#   name                = "${var.azurerm_virtual_network_name}${random_id.unique_sg_id.dec}"
#   address_space       = ["10.0.0.0/16"]
#   location            = azurerm_resource_group.nac_scheduler_rs.location
#   resource_group_name = azurerm_resource_group.nac_scheduler_rs.name

#   depends_on = [azurerm_resource_group.nac_scheduler_rs]
# }

# resource "azurerm_subnet" "nac_scheduler_subnet" {
#   count               = var.vnet_available == "Y" ? 0 : 1
#   name                 = var.azurerm_subnet_name
#   resource_group_name  = azurerm_resource_group.nac_scheduler_rs.name
#   virtual_network_name = azurerm_virtual_network.nac_scheduler_vnet[count.index].name
#   address_prefixes     = ["10.0.1.0/24"]
# }

resource "azurerm_public_ip" "nac_scheduler_public_ip" {
  count               = var.use_private_ip == "Y" ? 0 : 1
  name                = var.azurerm_public_ip_name
  location            = azurerm_resource_group.nac_scheduler_rs.location
  resource_group_name = azurerm_resource_group.nac_scheduler_rs.name
  allocation_method   = "Dynamic"

  depends_on = [azurerm_resource_group.nac_scheduler_rs]
}

resource "azurerm_network_security_group" "nac_scheduler_nsg" {
  name                = var.azurerm_network_security_group_name
  location            = azurerm_resource_group.nac_scheduler_rs.location
  resource_group_name = azurerm_resource_group.nac_scheduler_rs.name

  depends_on = [azurerm_resource_group.nac_scheduler_rs]
}

resource "azurerm_network_security_rule" "nac_scheduler_nsg_rule" {
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
  resource_group_name         = azurerm_resource_group.nac_scheduler_rs.name
  network_security_group_name = azurerm_network_security_group.nac_scheduler_nsg.name

  depends_on = [azurerm_network_security_group.nac_scheduler_nsg]
}

resource "azurerm_network_interface" "nac_scheduler_nic_public" {
  count               = var.use_private_ip != "Y" ? 1 : 0
  name                = var.azurerm_network_interface_name
  location            = azurerm_resource_group.nac_scheduler_rs.location
  resource_group_name = azurerm_resource_group.nac_scheduler_rs.name

  ip_configuration {
    name                          = var.ip_configuration_name
    subnet_id                     = data.azurerm_subnet.provided_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.nac_scheduler_public_ip[count.index].id
  }
}

resource "azurerm_network_interface" "nac_scheduler_nic_private" {
  count               = var.use_private_ip != "Y" ? 0 : 1
  name                = var.azurerm_network_interface_name
  location            = azurerm_resource_group.nac_scheduler_rs.location
  resource_group_name = azurerm_resource_group.nac_scheduler_rs.name

  ip_configuration {
    name                          = var.ip_configuration_name
    subnet_id                     = data.azurerm_subnet.provided_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "nac_scheduler_nisg_association" {
  network_interface_id      = var.use_private_ip != "Y" ? azurerm_network_interface.nac_scheduler_nic_public[0].id : azurerm_network_interface.nac_scheduler_nic_private[0].id
  network_security_group_id = azurerm_network_security_group.nac_scheduler_nsg.id
}

resource "azurerm_linux_virtual_machine" "nac_scheduler_vm" {
  name                  = var.azurerm_linux_virtual_machine_name
  location              = azurerm_resource_group.nac_scheduler_rs.location
  resource_group_name   = azurerm_resource_group.nac_scheduler_rs.name
  network_interface_ids = [
    var.use_private_ip != "Y" ? azurerm_network_interface.nac_scheduler_nic_public[0].id : azurerm_network_interface.nac_scheduler_nic_private[0].id
  ]
  size                  = "Standard_D2s_v3"

  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = var.azurerm_linux_virtual_machine_name
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("${var.pem_key_file}")
  }
}

# resource "null_resource" "Install_Packages" {
#   provisioner "remote-exec" {
#     inline = [
#       "echo '@@@@@@@@@@@@@@@@@@ STARTED - Install Packages @@@@@@@@@@@@@@@@@@'",
#       "sudo apt update",
#       "sudo apt upgrade -y",
#       "sudo apt install curl bash ca-certificates git openssl wget vim zip unzip dos2unix -y",
#       "sudo apt update",
#       "echo '****************** Installing Terraform ******************'",
#       "sudo wget https://releases.hashicorp.com/terraform/1.1.9/terraform_1.1.9_linux_amd64.zip",
#       "sudo unzip *.zip",
#       "sudo mv terraform /usr/local/bin/",
#       "terraform -v",
#       "which terraform",
#       "sudo apt install jq -y",
#       "echo '****************** Installing Python ******************'",
#       "sudo apt install python3 -y",
#       "sudo apt install python3-testresources -y",
#       "sudo apt install python3-pip -y",
#       "sudo pip3 install boto3",
#       "echo '******************  Installing AZURE CLI ******************'",
#       "curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash",
#       "sudo apt-get update",
#       "echo '@@@@@@@@@@@@@@@@@@ FINISHED - Install Packages @@@@@@@@@@@@@@@@@@'"
#     ]

#     connection {
#       type        = "ssh"
#       host        = var.use_private_ip !="Y" ? azurerm_linux_virtual_machine.nac_scheduler_vm.public_ip_address : azurerm_linux_virtual_machine.nac_scheduler_vm.private_ip_address_allocation
#       user        = "azureuser"
#       private_key = file("${var.az_key_name}")
#     }
#   }

#   depends_on = [
#     azurerm_linux_virtual_machine.nac_scheduler_vm,
#     azurerm_network_security_rule.nac_scheduler_nsg_rule
#   ]
# }