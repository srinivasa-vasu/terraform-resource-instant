locals {
  disks_count = (var.disks * var.instances)
  ingress     = "${chomp(data.http.localip.body)}/32"

  dev_ids = ["b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]

  disks_mounts = [for index in range(var.disks) : [
    "${var.disks_mount_points[0].device_name}${local.dev_ids[index]}", "${var.disks_mount_points[0].mount_point}${index}"
  ]]

  zones = [1, 2, 3]
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

data "template_file" "post_create" {
  template = file("../shared/scripts/instance_ops.tpl")

  vars = {
    disks = join(" ", [for disk in local.disks_mounts : join(",", disk)])
  }
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
  zone                  = var.zone != "" ? var.zone : local.zones[count.index]

  tags = var.labels

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.disk_type
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

resource "null_resource" "format_attached_disks_bastion_on" {
  count = var.bastion_on ? var.instances : 0
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
      data.template_file.post_create.rendered
    ]
  }
}

resource "null_resource" "format_attached_disks_bastion_off" {
  count = var.bastion_on ? 0 : var.instances
  depends_on = [
    azurerm_virtual_machine_data_disk_attachment.attach_disks
  ]
  connection {
    host        = azurerm_linux_virtual_machine.instances[count.index].private_ip_address
    type        = "ssh"
    user        = var.ssh_user
    private_key = file(var.ssh_private_key)
  }

  provisioner "remote-exec" {
    inline = [
      data.template_file.post_create.rendered
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
  storage_account_type = var.disk_type
  create_option        = "Empty"
  disk_size_gb         = var.disk_size
  zones                = [var.zone != "" ? var.zone : element(local.zones, floor(count.index / var.disks))]
  tags                 = var.labels
}
