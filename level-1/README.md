# Per-App AS3 and Terraform 

In this use-case, we'll explore how to automate the configuration of F5 application services using F5's **Per-App AS3** and **Terraform**. We have templetized the AS3 JSON files using Terraform's `templatefile` function and along with the TF `bigip_as3` resource, these templates are encapsulated within a custom module. This module can be invoked from the root directory (`root module`) by supplying necessary variables, such as IP Address, Pool Members, SSL certificates, etc. This streamlined approach enhances the deployment process, making it more manageable and scalable for applications configured through Terraform and AS3.

![level-1](../images/level-1.png)

# Table of Contexts

- [Code Explanation](#code-explanation)
  - [AS3_Modules](#as3_modules)
  - [Root Module](#root-module)
- [Use case workflow](#use-case-workflow)
- [Demo](#demo)

## Use case workflow
The workflow for this use-case is as follows:
  - Users create a new Terraform file configuration (`appX.tf`) with the appropriate application variables.
  - Users execute **terraform plan** and **terraform apply** commands localy. 

Benefits: 
  - **Ease of use**: All application varialbes are stored in a simple `tf` file. User just add/modifies/removes `tf` files to change the configuration on BIGIP
  - **Automation**: Automating the creation and management of application services on BIG-IP reduces the manual workload and speeds up the deployment process.
  - **Consistency**: Terraform ensures that the configuration is applied consistently every time, reducing the risk of manual errors.
  - **Scalability**: Terraform’s modular approach allows you to manage complex infrastructure by breaking it down into manageable components.


## Code Explanation
In the following section, we  provide a detailed explanation of the code that forms the foundation of this automation framework. The code is divided into 2 parts. The first part are the custom modules that we create to templatize AS3 declarations and deploy the AS3 resources. For simplicity, we will refer to these as **AS3_Modules**. In our example, we demonstrate the creation of a single module; however, you can expand this to include multiple modules as needed. The second part is the `root module`, which is used to invoke the `AS3_Modules` and manage the creation of the AS3 resources.

The structure of the directory for Terraform looks as follows
```
.
├── modules
│   ├── as3_http         <=== Custom module called as3_http
│   │   ├── as3.tpl
│   │   ├── main.tf
│   │   └── variables.tf
|                        <=== Start of Root module
├── app1.tf              <--- **TF file that calls as3_http module and defines resources for app1 **
├── app2.tf              <--- **TF file that calls as3_http module and defines resources for app2 **
├── app3.tf              <--- **TF file that calls as3_http module and defines resources for app3 **
├── providers.tf      
```

### *AS3_Modules*
The primary reason for the `AS3_Modules` is to templatize AS3 declarations and deploy the AS3 resources. Each module will have a separate name under the `modules` directory and will contain 3 files. These files are `as3.tpl`, `main.tf`, `variables.tf`
Here is an overview of the files and their roles:

#### as3.tpl

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

#### variables.tf

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

#### main.tf

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

### *Root Module*
The main module orchestrates the deployment of the VirtualServer configurations on the F5 device by invoking the respective modules. For each VirtualServer you want to create, you will need to create a separate `appX.tf` file (or append the relevant configuration on the existing file). Additionally, the main module includes the `providers.tf` file that defines multiple F5 BIG-IP providers, each corresponding to a single BIGIP device. 


#### appX.tf
This configuration does the following:
 - Invokes the AS3 module with the relevant variables to deploy an HTTP application.
 - Defines the providers that will deploy this service.

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

#### providers.tf
The `providers.tf` file defines the F5 BIG-IP providers, allowing you to manage multiple F5 devices using provider aliases. This enables you to deploy configurations to different devices by specifying the appropriate provider alias.

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
    address = "207.1.20.112"
    username = "admin"
    password = "passwordXYZ"
    alias=  "azure"
}
```

## Demo with UDF
> [!IMPORTANT]
> To run this Demo on your local environment, switch to the `Main` branch

### Prerequisites
- Deploy the **Oltra** UDF Deployment. Once provisioned, use the terminal on **VS Code** to run the commands in this demo. You can find **VS Code** under the `bigip-01` on the `Access` drop-down menu.  Click <a href="https://raw.githubusercontent.com/f5devcentral/bigip-automation/main/images/vscode.png"> here </a> to see how.


### Step 1. Clone Terraform repository

Provision **Oltra** UDF Deployment and open the `VS Code` terminal.

Clone `tf-level-1` from the internally hosted GitLab and change the working directory to `tf-level-1` 
```
git clone https://root:Ingresslab123@git.f5k8s.net/automation/tf-level-1.git
cd tf-level-1
```

>[!NOTE]
> We are including the username/password for Git during the cloning process so that we don't have to input the credentials when we push the changes back to the origin server.


### Step 2. Review the provider details
Open and review the following files to get a better understanding on how the configuration is structured.
 - **provider.tf** on the root directory
 - **as3.tpl** under the directory `modules`->`as3_http` 
 - **main.tf** under `modules`->`as3_http` 
 - **variables.tf** under `modules`->`as3_http` 


### Step 3. Create a new configuration
Create the configuration to publish the new application and save it as a file called `app1.tf`.

```cmd
cat <<EOF > app1.tf
module "app1" {
    source              = "./modules/as3_http"
    name                = "app1"
    virtualIP           = "10.1.10.41"
    serverAddresses     = ["10.1.20.21"]
    servicePort         = 30880
    partition           = "prod"
    providers = {
      bigip = bigip.dmz
    }    
}
EOF
```

### Step 4. Terraform init
Initialize Terraform on the working directory, to download the necessary provider plugins (BIGIP) and setup the modules and backend for storing your infrastructure's state

```cmd
terraform init
```

### Step 5. Terraform plan

Run the **terraform plan** command to create a plan consisting of a set of changes that will make your resources match your configuration. 

```cmd
terraform plan -parallelism=1 -refresh=false -out=tfplan
```

> [!NOTE]
> Review the actions Terraform would take to modify your infrastructure before moving to the next step.


### Step 6. Terraform apply

Run the **terraform apply** command to deploy the changes identified from the `plan` stage.

```cmd
terraform apply -parallelism=1 tfplan
```

### Step 7. Change the configuration

Edit the `app1.tf` file and change the IP Address configured for this service (10.1.120.40 -> 10.1.120.41)
Re-run **terrafrom plan** command to create the plan and review the suggested changes.

```cmd
terraform plan -parallelism=1 -refresh=false -out=tfplan
```

To deploy the suggested changes run the following command.

```cmd
terraform apply -parallelism=1 "tfplan"
```


### Step 8. Delete the configuration
Deleting of the apps deployed can take place with 2 methods. One method would be to delete the file `app1.tf` and re-run `terraform plan` `terraform apply` commands as demontrasted before or alternatively you can run the `terraform destroy` command to delete all TF configuration.

In our case, we will delete the `app1.tf` file.

```cmd
rm app1.tf
terraform plan -parallelism=1 -refresh=false -out=tfplan
```

To deploy the suggested changes run the following command.

```cmd
terraform apply -parallelism=1 "tfplan"
```
