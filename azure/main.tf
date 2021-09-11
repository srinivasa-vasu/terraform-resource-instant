locals {
  disks_count = (var.disks * var.instances)
  ingress     = "${chomp(data.http.localip.body)}/32"
}

# Will be authecticated using `az` cli as it is based on user authentication instead of ServicePrinciple
# make sure `az login` is successful before running this
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

# Workstation public ip to allow access to. It identies the IP where this gets executed and adds it to the 
# firewall rule in the firewall block
data "http" "localip" {
  url = "http://ipv4.icanhazip.com"
}

data "azurerm_resource_group" "rg" {
  name = var.rg
}

data "azurerm_virtual_network" "vnet" {
  name                = var.vnet
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_subnet" "subnet" {
  name                 = var.subnet
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = data.azurerm_resource_group.rg.name
}

data "azurerm_public_ip" "bastion" {
  resource_group_name = data.azurerm_resource_group.rg.name
  name                = var.bastion
}

data "azurerm_network_security_group" "nsg" {
  name                = var.nsg
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_network_interface" "nic" {
  count               = var.instances
  name                = "${var.identifier}-n${format("%d", count.index + 1)}"
  location            = var.region
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  count                     = var.instances
  network_interface_id      = element(azurerm_network_interface.nic.*.id, count.index)
  network_security_group_id = data.azurerm_network_security_group.nsg.id
}

resource "azurerm_linux_virtual_machine" "instances" {
  count                 = var.instances
  name                  = "${var.identifier}-n${format("%d", count.index + 1)}"
  location              = var.region
  resource_group_name   = data.azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]
  size                  = var.instance_type
  admin_username        = var.ssh_user
  zone                  = var.zone

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_ssh_key {
    username   = var.ssh_user
    public_key = file(var.ssh_public_key)
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.5"
    version   = "latest"
  }
}

resource "null_resource" "format_attached_disks" {
  count = var.instances
  depends_on = [
    azurerm_virtual_machine_data_disk_attachment.attach_disks
  ]
  connection {
    bastion_host        = data.azurerm_public_ip.bastion.ip_address
    bastion_private_key = file(var.ssh_private_key)
    bastion_user        = var.bastion_ssh_user
    host                = azurerm_linux_virtual_machine.instances[count.index].private_ip_address
    type                = "ssh"
    user                = var.ssh_user
    private_key         = file(var.ssh_private_key)
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkfs -t xfs /dev/sdc",
      "sudo mkfs -t xfs /dev/sdb",
      "sudo mkdir -p /disks/ssd0",
      "sudo mkdir -p /disks/ssd1",
      "sudo mount /dev/sdc /disks/ssd0",
      "sudo mount /dev/sdb /disks/ssd1",
      "sudo cp /etc/fstab /etc/fstab.orig",
      "disk0_uuid=$(sudo blkid | grep -i \"/dev/sdc\" | awk '{print $2}' | tr -d '\"')",
      "disk1_uuid=$(sudo blkid | grep -i \"/dev/sdb\" | awk '{print $2}' | tr -d '\"')",
      "echo $disk0_uuid /disks/ssd0  xfs  defaults,nofail  0  2 | sudo tee -a /etc/fstab",
      "echo $disk1_uuid /disks/ssd1  xfs  defaults,nofail  0  2 | sudo tee -a /etc/fstab"
    ]
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "attach_disks" {
  managed_disk_id    = azurerm_managed_disk.disks[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.instances[floor(count.index / var.disks)].id
  count              = local.disks_count
  lun                = count.index
  caching            = "ReadWrite"
}

resource "azurerm_managed_disk" "disks" {
  count                = local.disks_count
  name                 = "${var.identifier}-n${format("%d", count.index + 1)}"
  location             = var.region
  resource_group_name  = data.azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "50"
  zones                = [var.zone]
}
