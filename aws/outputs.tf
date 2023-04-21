output "instance_private_ip_addresses" {
  value = {
    for instance in aws_instance.instances :
    instance.id => {
      "private_ip" = instance.private_ip,
      # "public_ip"  = instance.public_ip
    }
  }
}

output "instance_private_ip_addresses_list" {
  value = [
    for instance in aws_instance.instances :
    instance.private_ip
  ]
}

output "ssh_private_key" {
  value     = tls_private_key.ssh_key.private_key_pem
  sensitive = true
}
