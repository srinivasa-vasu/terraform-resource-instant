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

