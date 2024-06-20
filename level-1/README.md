# Automating BIGIP configuration with Terraform and Per-App AS3

In this use-case, we'll explore how to automate the configuration of F5 application services using F5's Per Application AS3 and Terraform and templates. We have created 2 Terraform modules, each corresponding to a specific AS3 configuration (http and https). When these modules are invoked from the main module, they automate the creation of application configurations on the F5 device. This approach simplifies the deployment process and makes it easier to manage and scale applications.

![terraform-f5](images/terraform-f5.png)

# Table of Contexts

- [Code Explanation](#code-explanation)
  - [AS3_HTTP Module](#as3_http-module)
  - [AS3_HTTPS Module](#as3_https-module)
  - [Main Module](#main-module)
- [Demo](#Demo)

## Code Explanation
In the following section, we  provide a detailed explanation of the code that forms the foundation of this automation framework. The code is split into 2 levels. The first level is the TF modules that we create to templatize AS3 declarations and deploy the AS3 resources. For simplicity, we will call these **AS3_Modules**. The second level is the Main modules that is used to call the `AS3_Modules` in order to create the AS3 resources.
```
.
├── modules
│   ├── as3_http
│   │   ├── as3.tpl
│   │   ├── main.tf
│   │   └── variables.tf
│   └── as3_https
│       ├── as3.tpl
│       ├── main.tf
│       └── variables.tf
├── app1.tf     <---- Per App 
├── app2.tf
├── app3.tf
├── providers.tf
```

### *AS3_Modules*
The primary reason for the `AS3_Modules` is to templatize AS3 declarations and deploy the AS3 resources. Each module will have a separate name under the `modules` directory and will contain 3 files. These files are `as3.tpl`, `main.tf`, `variables.tf`
Here is an overview of the files and their roles:

**as3.tpl**

The as3.tpl file is an AS3 Per-App template used to define the Application. This template performs the following tasks:

 - Defines an AS3 declaration for an Application.
 - Uses variables for tenant, application name, virtual address, service port, and pool members, allowing for flexible and reusable config

```tf
{
  "${name}": {
    "class": "Application",
    "service": {
      "class": "Service_HTTP",
      "virtualAddresses": [
        "${virtualIP}"
      ],
      ${virtualPort == 0 ? "\"virtualPort\": 80," : "\"virtualPort\": ${virtualPort},"}
      "pool": "pool_${name}"
    },
    "pool_${name}": {
      "class": "Pool",
      "members": [
        {
          "servicePort": ${servicePort},
          "shareNodes": true,
          "serverAddresses": ${jsonencode(serverAddresses)}
        }
      ]
    }
  }
}
```

**variables.tf**

The variables.tf defines the variables that will be used by the `as3.tpl` on this module. The use of variables, allows us to assign default values that the `as3.tpl` can later use.

```tf
###########   AS3 Variables   ############
variable partition	{
  description = "Partition that the AS3 will be deployed to"
  type        = string
}
variable name	{
  description = "Name of the Virtual Server"
  type        = string
}
variable virtualIP	{
  description = "IP for Virtual Server"
  type        = string
}
variable virtualPort  {
  description = "Port for Virtual Server"
  type        = number  
  default     = 0
}
variable serverAddresses  {
  description = "List of IPs for Pool Members"
  type        = list(string)
}
variable servicePort  {
  description = "Port of the Pool Members"
  type        = number
}

```

**main.tf**

The **main.tf** file contains the Terraform configuration that creates the HTTP VirtualServer. Below is a detailed breakdown of its contents:
- The first block defines the version of the F5 BIG-IP provider that will be used. It is important to use the version `1.22.2` or later
- The second block uses the **f5bigip_as3** resource to deploy the AS3 Application. The `as3_json` parameter is populated by a template file (as3.tpl), which is passed variables like tenant, application name, service port, pool members and other variables.
- The third block outputs the response from the F5 device after deploying the configuration.

```tf
terraform {
  required_providers {
    bigip = {
      source = "F5Networks/bigip"
      version = "1.22.2"
    }
  }
}

resource "bigip_as3" "as3" {
  tenant_name= var.partition
  tenant_filter= var.partition
  ignore_metadata = true
  as3_json = templatefile("${path.module}/as3.tpl", {
    name            = var.name
    virtualIP       = var.virtualIP
    virtualPort     = var.virtualPort
    serverAddresses = var.serverAddresses
    servicePort     = var.servicePort
  })
}

output "as3" {
  value = bigip_as3.as3
}
```

### *Main Module*
The main module orchestrates the deployment of the VirtualServer configurations on the F5 device by invoking the respective modules. For each VirtualServer you want to create, you will need to create a separate `appX.tf` file (or append the relevant configuration on the existing file). Additionally, the main module includes the `providers.tf` file that defines multiple F5 BIG-IP providers, each corresponding to a single BIGIP device. 


**appX.tf**

```tf
module "appX" {
    source              = "./modules/as3_http"
    name                = "appX"
    virtualIP           = "10.1.120.112"
    virtualPort         = 80
    serverAddresses     = ["10.1.20.10", "10.1.20.11"]
    servicePort         = 80
    partition            = "test1"
    providers = {
      bigip = bigip.dmz
    }    
}
```

This configuration does the following:

 - Invokes the AS3 module with the relevant variables to deploy an HTTP application.
 - Defines the providers that will deploy this service.



**providers.tf**

```tf
terraform {
  required_providers {
    bigip = {
      source = "F5Networks/bigip"
      version = "1.22.2"
    }
  }
}

provider "bigip" {
    address = "10.1.10.215"
    username = "admin"
    password = "passwordXYZ"
    alias=  "dmz"
}

provider "bigip" {
    address = "10.1.20.112"
    username = "admin"
    password = "passwordXYZ"
    alias=  "azure"
}

provider "bigip" {
    address = "10.1.50.98"
    username = "admin"
    password = "passwordXYZ"
    alias=  "aws"
}
```

The `providers.tf` file defines the F5 BIG-IP providers, allowing you to manage multiple F5 devices using provider aliases. This enables you to deploy configurations to different devices by specifying the appropriate provider alias.

## Demo

### Prerequisites
To run the following demo you need to have Terraform installed in your environment.

- AS3 version on BIG-IP should be > v3.50
- Terraform version should be > 0.13

### Step 1. Clone the Repo

Clone the repository and change the working directory to `level-1`
```
git clone https://github.com/f5devcentral/bigip-automation
cd bigip-automation/level-1
```

### Step 2. Change the provider details
Edit the file `provider.tf` with the IP Address, Username and Password of your BIGIP device. 

### Step 3. Terraform init
Initialize Terraform on the working directory, to download the necessary provider plugins (BIGIP) and setup the modules/backend for storing your infrastructure's state

```cmd
terraform init
```

### Step 4. Terraform plan

Run the **terraform plan** command to create a plan consisting of a set of changes that will make your resources match your configuration. 

```cmd
terraform plan -parallelism=1 -refresh=false -out=tfplan
```

> [!NOTE]
> Review the actions Terraform would take to modify your infrastructure before moving to the next step.

> [!TIP]
> By using the `out` flag with terraform plan, the plan was saved into a file called `tfpan` that will be used by **terraform apply** command.


### Step 5. Terraform apply

Run the **terraform apply** command to deploy the changes identified from the `plan` stage.

```cmd
terraform apply -parallelism=1 tfplan
```

Review the output from the `apply` command.


### Step 6. (Optional) Change the configuration

Edit the `app1.tf` file and change the IP Address configured for this service. 
Re-run **terrafrom plan** command to create the plan and review the suggested changes.

```cmd
terraform plan -parallelism=1 -refresh=false -out=tfplan
```

The output of the above command should be similar to the following

```tf
Terraform will perform the following actions:

  # module.app1.bigip_as3.as3 will be updated in-place
  ~ resource "bigip_as3" "as3" {
      ~ as3_json         = jsonencode(
          ~ {
              ~ path_app1     = {
                  ~ app1      = {
                      ~ virtualAddresses = [
                          ~ "10.1.120.82" -> "10.1.120.50",
                        ]
                        # (3 unchanged attributes hidden)
                    }
                    # (2 unchanged attributes hidden)
                }
                # (1 unchanged attribute hidden)
            }
        )
        id               = "uat1"
        # (7 unchanged attributes hidden)
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```

To deploy the suggested changes run the following command.

```cmd
terraform apply -parallelism=1 "tfplan"
```


### Step 7. Deleting the configuration
Deleting of the apps deployed can take place with 2 methods. One method would be to delete the file and re-run `terraform plan` and `terraform apply` and demontrasted before.

Alternatively you can run the destroy command to delete all configuration.

```cmd
terraform destroy -parallelism=1 -refresh=false
```