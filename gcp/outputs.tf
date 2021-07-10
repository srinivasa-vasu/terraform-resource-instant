output "instance_private_ip_addresses" {
  value = {
    for instance in google_compute_instance.instances :
    instance.id => {
      "private_ip" = instance.network_interface.0.network_ip,
      "public_ip"  = instance.network_interface.0.access_config.0.nat_ip
    }
  }
}

output "instance_private_ip_addresses_list" {
  value = [
    for instance in google_compute_instance.instances :
    instance.network_interface.0.network_ip
  ]
}

