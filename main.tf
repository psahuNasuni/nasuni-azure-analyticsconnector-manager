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

    https = {
      name                       = "HTTPS"
      description                = "HTTPS Rule"
      priority                   = 320
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      source_port_ranges         = ["0-65535"]
      destination_port_ranges    = ["443"]
    }

  }
}

resource "random_id" "unique_sg_id" {
  byte_length = 2
}

data "azuread_service_principal" "user" {
  application_id = var.sp_application_id
}

data "azurerm_resource_group" "nac_scheduler_rg" {
  name = var.edgeappliance_resource_group
}

data "azurerm_subnet" "azure_subnet_name" {
  name                 = var.user_subnet_name
  virtual_network_name = var.user_vnet_name
  resource_group_name  = var.networking_resource_group
}

data "tls_public_key" "private_key_pem" {
  private_key_pem = file("${var.pem_key_path}")
}


resource "azurerm_public_ip" "nac_scheduler_public_ip" {
  count               = var.use_private_ip == "Y" ? 0 : 1
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
  count               = var.use_private_ip != "Y" ? 1 : 0
  name                = "${var.network_interface_name}-${random_id.unique_sg_id.dec}"
  location            = data.azurerm_resource_group.nac_scheduler_rg.location
  resource_group_name = data.azurerm_resource_group.nac_scheduler_rg.name

  ip_configuration {
    name                          = "NACScheduler_nic_ip"
    subnet_id                     = data.azurerm_subnet.azure_subnet_name.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.nac_scheduler_public_ip[count.index].id
  }
}

resource "azurerm_network_interface" "nac_scheduler_nic_private" {
  count               = var.use_private_ip != "Y" ? 0 : 1
  name                = "${var.network_interface_name}-${random_id.unique_sg_id.dec}"
  location            = data.azurerm_resource_group.nac_scheduler_rg.location
  resource_group_name = data.azurerm_resource_group.nac_scheduler_rg.name

  ip_configuration {
    name                          = "NACScheduler_nic_ip"
    subnet_id                     = data.azurerm_subnet.azure_subnet_name.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "nac_scheduler_nisg_association" {
  network_interface_id      = var.use_private_ip != "Y" ? azurerm_network_interface.nac_scheduler_nic_public[0].id : azurerm_network_interface.nac_scheduler_nic_private[0].id
  network_security_group_id = azurerm_network_security_group.NACSchedulerSecurityGroup.id
}

resource "azurerm_linux_virtual_machine" "NACScheduler" {
  name                = var.nac_scheduler_name
  location            = data.azurerm_resource_group.nac_scheduler_rg.location
  resource_group_name = data.azurerm_resource_group.nac_scheduler_rg.name
  network_interface_ids = [
    var.use_private_ip != "Y" ? azurerm_network_interface.nac_scheduler_nic_public[0].id : azurerm_network_interface.nac_scheduler_nic_private[0].id
  ]
  size = "Standard_DS3_v2"

  os_disk {
    name                 = "NACScheduler_Disk-${random_id.unique_sg_id.dec}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  computer_name                   = var.nac_scheduler_name
  admin_username                  = "ubuntu"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "ubuntu"
    public_key = data.tls_public_key.private_key_pem.public_key_openssh
  }
}

resource "null_resource" "Install_Packages" {
  provisioner "remote-exec" {
    inline = [
      "echo '@@@@@@@@@@@@@@@@@@ STARTED - Install Packages @@@@@@@@@@@@@@@@@@'",
      "sudo apt update",
      "sudo apt upgrade -y",
      "sudo apt install curl bash ca-certificates git openssl wget vim -y",
      "sudo apt update -y",
      "sudo apt install dos2unix -y",
      "sudo apt update -y",
      "sudo apt install zip -y",
      "sudo apt update -y",
      "sudo apt install unzip -y",
      "echo '****************** Installing Terraform ******************'",
      "curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -",
      "sudo apt-add-repository \"deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main\"",
      "sudo apt update",
      "sudo apt install terraform",
      "terraform -v",
      "which terraform",
      "sudo apt install jq -y",
      "echo '****************** Installing Python ******************'",
      "sudo apt install python3 -y",
      "sudo apt install python3-testresources -y",
      "sudo apt install python3-pip -y",
      "sudo pip3 install boto3",
      "sudo pip3 install sortedcontainers",
      "sudo pip3 install --upgrade pip",
      "sudo pip3 install --upgrade setuptools",
      "sudo pip3 install --default-timeout=100 future",
      "echo '******************  Installing AZURE CLI ******************'",
      "curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash",
      "sudo apt-get update",
      "az login --service-principal --tenant ${data.azuread_service_principal.user.application_tenant_id} --username ${var.sp_application_id} --password ${var.sp_secret}",
      "echo '***************** Installing azcopy ************************'",
      "wget -O azcopy_v10.tar.gz https://aka.ms/downloadazcopy-v10-linux",
      "tar -zxf azcopy_v10.tar.gz --strip-components=1 --wildcards */azcopy",
      "sudo mv azcopy /usr/local/bin/azcopy",
      "azcopy --version",
      "echo '@@@@@@@@@@@@@@@@@@ FINISHED - Install Packages @@@@@@@@@@@@@@@@@@'"
    ]

    connection {
      type        = "ssh"
      host        = var.use_private_ip != "Y" ? azurerm_linux_virtual_machine.NACScheduler.public_ip_address : azurerm_linux_virtual_machine.NACScheduler.private_ip_address
      user        = "ubuntu"
      private_key = file("${var.pem_key_path}")
    }
  }

  depends_on = [
    azurerm_linux_virtual_machine.NACScheduler,
    azurerm_network_security_rule.NACSchedulerSecurityGroupRule
  ]
}

resource "null_resource" "Deploy_Web_UI" {
  provisioner "remote-exec" {
    inline = [
      "echo '@@@@@@@@@@@@@@@@@@@@@ STARTED  - Deployment of SearchUI Web Site @@@@@@@@@@@@@@@@@@@@@@@'",
      "export ARM_CLIENT_ID='${var.sp_application_id}'",
      "export ARM_CLIENT_SECRET='${var.sp_secret}'",
      "export ARM_TENANT_ID='${data.azuread_service_principal.user.application_tenant_id}'",
      "export ARM_SUBSCRIPTION_ID='${var.subscription_id}'",
      "sudo apt install dos2unix -y",
      "git clone -b ${var.git_branch} https://github.com/${var.github_organization}/${var.git_repo_ui}.git",
      "sudo chmod 755 ${var.git_repo_ui}/ -R",
      "cd ${var.git_repo_ui}",
      "pwd",
      "UI_TFVARS_FILE=ui_tfvars.tfvars",
      "rm -rf $UI_TFVARS_FILE",
      "echo 'acs_admin_app_config_name=\"'\"${var.acs_admin_app_config_name}\"'\"' >>$UI_TFVARS_FILE",
      "echo 'nac_scheduler_name=\"'\"${azurerm_linux_virtual_machine.NACScheduler.name}\"'\"' >>$UI_TFVARS_FILE",
      "echo 'acs_resource_group=\"'\"${var.acs_resource_group}\"'\"' >>$UI_TFVARS_FILE",
      "echo 'networking_resource_group=\"'\"${var.networking_resource_group}\"'\"' >>$UI_TFVARS_FILE",
      "echo 'user_vnet_name=\"'\"${var.user_vnet_name}\"'\"' >>$UI_TFVARS_FILE",
      "echo 'user_subnet_name=\"'\"${var.user_subnet_name}\"'\"' >>$UI_TFVARS_FILE",
      "echo 'use_private_ip=\"'\"${var.use_private_ip}\"'\"' >>$UI_TFVARS_FILE",
      "echo 'search_outbound_subnet=[\"${var.search_outbound_subnet}\"]' >>$UI_TFVARS_FILE",
      "echo 'INFO ::: Installing Python Dependencies'",
      "COMMAND='pip3 install  --target=./SearchFunction/.python_packages/lib/site-packages  -r ./SearchFunction/requirements.txt'",
      "$COMMAND",
      "terraform init",
      "terraform apply -var-file=$UI_TFVARS_FILE -auto-approve",
      "echo '@@@@@@@@@@@@@@@@@@@@@ FINISHED - Deployment of SearchUI Web Site @@@@@@@@@@@@@@@@@@@@@@@'"
    ]
  }

  connection {
    type        = "ssh"
    host        = var.use_private_ip != "Y" ? azurerm_linux_virtual_machine.NACScheduler.public_ip_address : azurerm_linux_virtual_machine.NACScheduler.private_ip_address
    user        = "ubuntu"
    private_key = file("${var.pem_key_path}")
  }

  depends_on = [
    azurerm_linux_virtual_machine.NACScheduler,
    azurerm_network_security_rule.NACSchedulerSecurityGroupRule,
    null_resource.Install_Packages
  ]
}

resource "null_resource" "NACScheduler_IP" {
  provisioner "local-exec" {
    command = var.use_private_ip != "Y" ? "echo ${azurerm_linux_virtual_machine.NACScheduler.public_ip_address} > NACScheduler_IP.txt" : "echo ${azurerm_linux_virtual_machine.NACScheduler.private_ip_address} > NACScheduler_IP.txt"
  }
  depends_on = [azurerm_linux_virtual_machine.NACScheduler]
}

output "NACScheduler_IP" {
  value = var.use_private_ip != "Y" ? "ssh -i ${var.pem_key_path} ubuntu@${azurerm_linux_virtual_machine.NACScheduler.public_ip_address}" : "ssh -i ${var.pem_key_path} ubuntu@${azurerm_linux_virtual_machine.NACScheduler.private_ip_address}"
}
