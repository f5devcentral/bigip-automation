# Automating BIGIP configuration with Terraform and Per-App AS3

In the modern era of IT, automation and infrastructure as code (IaC) have become pivotal in streamlining operations and enhancing the agility of organizations. Terraform, an open-source IaC tool, allows administrators to define and provision infrastructure using a high-level configuration language. When combined with F5 Networks' Application Services 3 (AS3), a declarative configuration API for BIG-IP, the result is a powerful solution for managing application services more efficiently and consistently.

For F5 administrators, leveraging Terraform with AS3 can drastically reduce the time and effort required to deploy and manage application services. Automation not only minimizes human errors but also ensures that configurations are consistent across different environments. This enables organizations to respond quickly to changing business needs, scale their operations seamlessly, and maintain a high level of operational efficiency.

In this article, we'll explore how to automate the configuration of F5 application services using Terraform and F5's AS3 Per-App templates. We have created multiple Terraform modules, each corresponding to a specific AS3 template. Currently for this example, we have created two modules for HTTP and HTTPS configurations. When these modules are invoked from the main module, they automate the creation of application configurations on the F5 device. This approach simplifies the deployment process and makes it easier to manage and scale applications.

![terraform-f5](https://github.com/skenderidis/bigip-automation/terraform-f5.png)

# Table of Contexts

- [Technologies used](#technologies-used)
- [Code Explanation](#code-explanation)
  - [AS3_HTTP Module](#as3_http-module)
  - [AS3_HTTPS Module](#as3_https-module)
  - [Main Module](#main-module)
- [Best Practicies](#best-practices)
  - [Deploying Services with Terraform](#deploying-services-with-terraform)
  - [Terraform Plan parameters](#terraform-plan-parameters)
  - [Terraform Apply parameters](#terraform-apply-parameters)
- [Demo](#Demo)

# Technologies used

To create this automation use-case, we leverage the following technologies:

- **AS3**. AS3 furnishes a declarative interface, enabling the management of application-specific configurations on a BIG-IP system. By providing a JSON declaration rather than a series of imperative commands, AS3 ensures precise configuration orchestration. We utilize the latest Per-App AS3 feature to optimize configuration granularity. You can find more information on [https://clouddocs.f5.com/products/extensions/f5-appsvcs-extension/latest/](https://clouddocs.f5.com/products/extensions/f5-appsvcs-extension/latest/)

- **F5 BIG-IP Terraform Provider**. The F5 BIG-IP Terraform Provider helps you manage and provision your BIG-IP configurations in Terraform through the use of AS3/DO integration.You can find more information on [https://registry.terraform.io/providers/F5Networks/bigip/latest/docs](https://registry.terraform.io/providers/F5Networks/bigip/latest/docs)


## Code Explanation
In the following section, we will provide a detailed explanation of the code that forms the foundation of this automation framework. This will help you understand how the various components work together to automate the configuration of F5 application services using Terraform and AS3 templates.

### *AS3_HTTP* Module
The HTTP module is designed to create an HTTP VirtualServer configuration on a BIGIP device using AS3 Per-App templates. The files for this module can be found under the directory ***`code->modules->as3_http`***.

Here is an overview of the files and their roles:

**main.tf**

The **main.tf** file contains the Terraform configuration that creates the HTTP VirtualServer. Below is a detailed breakdown of its contents:
- The first block defines the version of the F5 BIG-IP provider that will be used.
- The second block uses the **f5bigip_as3** resource to deploy the AS3 Application. The `as3_json` parameter is populated by a template file (as3.tpl), which is passed variables like tenant, application name, service port, pool members and other variables.
- The third block outputs the response from the F5 device after deploying the configuration.

```tf
terraform {
  required_providers {
    bigip = {
      source = "F5Networks/bigip"
      version = "1.22.0"
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

**as3.tpl**

The as3.tpl file is an AS3 template used to define the HTTP application. This template performs the following tasks:

 - Defines an AS3 declaration for an HTTP application.
 - Creates a tenant and an application within that tenant.
 - Configures an HTTP service with a virtual address and associates it with a pool of servers.
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

The variables.tf defines the variables that will be used by the `as3.tpl` on this module:

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

### *AS3_HTTPS* Module
The HTTPS module is designed to create an HTTPS Virtual Server configuration on a BIGIP device using AS3 Per-App templates. This module is exactly like the previous module (AS3_HTTP) but with a different template and variable that define the Client SSL Profile that is stored on Common Partition. The files for this module can be found under the directory ***`code->modules->as3_https`***.


### *Main* Module
The main module orchestrates the deployment of the HTTP and HTTPS VirtualServer configurations on the F5 device by invoking the respective modules. For each VirtualServer you want to create, you will need to create a separate `appX.tf` file (or append the relevant configuration on the existing file). Additionally, the main module includes the `providers.tf` file that defines multiple F5 BIG-IP providers, each corresponding to a single BIGIP device. 


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

#
resource "local_file" "output" {
  filename = "declarations/${module.appX.as3.tenant_name}/${module.appX.as3.application_list}.json"
  content  = module.appX.as3.as3_json
  depends_on = [module.appX]
}

resource "null_resource" "json_beautify" {
  provisioner "local-exec" {
    when    = create
    command = "jq . declarations/${module.appX.as3.tenant_name}/${module.appX.as3.application_list}.json > declarations/${module.appX.as3.tenant_name}/${module.appX.as3.application_list}.json"
  }
}

```

This configuration does the following:

 - Invokes the HTTP/S module with the relevant variables to deploy an HTTP application.
 - Defines the providers that will deploy this service.
 - Outputs the JSON AS3 to a folder.
 - Re-formats the JSON AS3 with `jq`.


**providers.tf**

```tf
terraform {
  required_providers {
    bigip = {
      source = "F5Networks/bigip"
      version = "1.22.0"
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




## Deploying Services with Terraform

When using Terraform, before applying any changes to your infrastructure, it is crucial to understand what modifications Terraform will make. Running **terraform plan** allows you to preview these changes without actually applying them. This step ensures that you are aware of all the resources that will be created, modified, or destroyed.

When you execute terraform plan, you will see an output similar to the following, indicating that the module `appX` and the `bigip_as3` resource will be created:

### Adding new services
In this example, the plan indicates that the bigip_as3 resource will be created with the specified configurations. You can see the details of the application, including the pool members, service configuration, and virtual address. The known after apply placeholders signify that certain values, such as id and task_id, will be determined only after the actual apply step.

```cmd
module.appX.bigip_as3.as3 will be created
  + resource "bigip_as3" "as3" {
      + application_list = (known after apply)
      + as3_json         = jsonencode(
            {
              + appX = {
                  + class     = "Application"
                  + pool_appX = {
                      + class   = "Pool"
                      + members = [
                          + {
                              + serverAddresses = [
                                  + "10.1.20.10",
                                  + "10.1.20.11",
                                ]
                              + servicePort     = 80
                              + shareNodes      = true
                            },
                        ]
                    }
                  + service   = {
                      + class            = "Service_HTTP"
                      + pool             = "pool_appX"
                      + virtualAddresses = [
                          + "10.1.120.111",
                        ]
                      + virtualPort      = 80
                    }
                }
            }
        )
      + id               = (known after apply)
      + ignore_metadata  = true
      + per_app_mode     = (known after apply)
      + task_id          = (known after apply)
      + tenant_filter    = "test1"
      + tenant_list      = (known after apply)
      + tenant_name      = "test1"
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

### Modifying existing services
When you make modifications to your Terraform configuration, such as changing an IP address, running terraform plan again will show you the exact changes that will be applied. This helps you understand the impact of your changes before they are executed.

For instance, if you update the virtual address for an application, the plan will indicate the specific modifications. In this example, the plan indicates that the bigip_as3 resource will be updated in place. The as3_json section shows the change from the old IP address 10.1.120.111 to the new IP address 10.1.120.112. The ~ symbol denotes attributes that will be updated. Here's an example of the output you should see:

```tf
module.app1.bigip_as3.as3 will be updated in-place
  ~ resource "bigip_as3" "as3" {
      ~ as3_json         = jsonencode(
          ~ {
              ~ app1 = {
                  ~ service   = {
                      ~ virtualAddresses = [
                          ~ "10.1.120.111" -> "10.1.120.112",
                        ]
                        # (3 unchanged attributes hidden)
                    }
                    # (2 unchanged attributes hidden)
                }
            }
        )
        id               = "test1"
        # (7 unchanged attributes hidden)
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```

By examining the output of terraform plan, you can verify that the planned changes match your intentions. This step is crucial for ensuring that your updates are applied correctly and that no unintended modifications occur. It provides a clear and detailed preview of the infrastructure changes, enhancing your control over the deployment process.


### Best Practices

When deploying a configuration with Terraform is it already recommended to run **`terraform plan`** first. The **terraform plan** command creates a plan consisting of a set of changes that will make your resources match your configuration. This lets you preview the actions Terraform would take to modify your infrastructure before applying them.

In our scenario it is suggested to use some additional parameters of the **plan** command and it should look like this:
```cmd
terraform plan -parallelism=1 -refresh=false -out=tfplan
```

The above command includes the following options on top of the regular terraform plan:
- **`-parallelism=1`**: Ensures that operations are executed sequentially, making the process single-threaded.
- **`-refresh=false`**: Prevents Terraform from refreshing the state, using the existing state information. 
- **`-out=tfplan`**: Saves the plan output to a file named `tfplan`, which can be used later with `terraform apply`.

When executing a Terraform plan, there are several options that can be used to control the behavior of the planning process. In this context, the options `-refresh=false` and `-parallelism=1` are used for specific reasons.

The **`-refresh=false`** option is used to prevent Terraform from updating the state file with the latest information from the infrastructure provider before running the plan. By default, Terraform refreshes the state to ensure it has the most up-to-date information about the resources it manages. However, there are situations where you might not want this behavior:
- **Performance Improvement**: Refreshing the state can be time-consuming, especially in large infrastructures. Disabling the refresh can speed up the plan execution.
- **Consistency**: In some cases, you might want to work with the current state as is, without considering any changes that might have occurred outside of Terraform. This ensures that the plan reflects only the changes defined in the configuration, without any external modifications.

The **`-parallelism=1`** option sets the maximum number of concurrent operations to one. By default, Terraform performs operations in parallel to speed up the process. However, there are scenarios where running operations in parallel is not desirable:

- **Single-Threaded Processes**: AS3 on BIGIP Classic cannot handle concurrent operations and the setting `parallelism` to one ensures that Terraform processes operations sequentially. This can prevent issues such as race conditions or API throttling.
- **Debugging**: Running operations one at a time makes it easier to identify and debug issues, as the order of operations is clear and predictable.


When running **`terraform apply`** with these options, the command looks like this:
```cmd
terraform plan -parallelism=1 -refresh=false -out=tfplan
```

This command performs the following actions:

-parallelism=1
Sequential Execution: Just like with the terraform plan command, the -parallelism=1 option ensures that the operations are executed sequentially, one at a time.
"tfplan"

Apply the Saved Plan: The "tfplan" argument specifies the plan file created by the previous terraform plan -out=tfplan command. By providing this plan file, you instruct Terraform to apply the exact set of changes that were outlined in the plan. This ensures that the changes applied are consistent with what was reviewed during the planning stage, avoiding any surprises or unintended modifications.


## Demo


