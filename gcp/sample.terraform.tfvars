project = ""
region  = ""
# region  = "asia-south1"
# zone    = "asia-south1-c"

# key pair
credentials     = ""
ssh_private_key = ""
ssh_public_key  = ""
ssh_user        = ""

vpc    = ""
subnet = ""

bastion_on              = ""
bastion                 = ""
bastion_ssh_private_key = ""

instances     = 1
instance_type = "n2-standard-4"
image_type    = "almalinux8"
disks         = 1
disk_type     = "pd-ssd"
disk_size     = 10

identifier = "ybaeon"
tags       = ["yba-dev"]
