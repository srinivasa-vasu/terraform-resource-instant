output "instance_private_ip_addresses" {
  value = {
    for instance in azurerm_linux_virtual_machine.instances :
    instance.id => {
      "private_ip" = instance.private_ip_address,
      # "public_ip"  = instance.public_ip
    }
  }
}

output "instance_private_ip_addresses_list" {
  value = [
    for instance in azurerm_linux_virtual_machine.instances :
    instance.private_ip_address
  ]
}

