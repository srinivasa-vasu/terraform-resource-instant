# terraform-resource-instant

Terraform VM and disk provisioner for all 3 clouds (AWS, Google and Azure). This is used to provision instances and disks/instances on-demand. This requires a bastion host to connect to trigger the instances and disks creation.

## Initialization
* Clone this repo to the local workstation

```
$ git clone https://github.com/srinivasa-vasu/terraform-resource-instant.git
```

* Change directory to the cloned repo

```
$ cd terraform-resource-instant/{cloud_provider}
```

* Create `terraform.tfvars` file with the needed data populated (or update `sample.terraform.tfvars` file appropriately and rename it to `terraform.tfvars`)


## Usage

* Run terraform init to initialize the modules dependencies

```
$ terraform init
```

* Generate the terraform plan to understand the changes

```
$ terraform plan -out=plan
```

* Run the following to apply the changes

```
$ terraform apply plan
```

* Run the following the fetch the values from the terraform run

```
$ terraform output <output_variable>
```

* To destroy the provisioned resources,

```
$ terraform destroy
```

## Managed Resources

This terraform-module manages the following resources

- compute
- disks
- attach-disks
