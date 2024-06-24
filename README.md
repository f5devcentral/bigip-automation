# Automating BIGIP with Per-App AS3 and Terraform

In the modern era of IT, automation and infrastructure as code (IaC) have become very important in streamlining operations and enhancing the agility of organizations. Terraform, an open-source IaC tool, allows administrators to define and provision infrastructure using a high-level configuration language. When combined with F5 Per App AS3, a declarative configuration API for BIG-IP, the result is a powerful solution for managing application services more efficiently and consistently.

For F5 administrators, leveraging Terraform with AS3 can drastically reduce the time and effort required to deploy and manage application services. Automation not only minimizes human errors but also ensures that configurations are consistent across different environments. This enables organizations to respond quickly to changing business needs, scale their operations seamlessly, and maintain a high level of operational efficiency.

In this repository, we will explore five use cases, each being the evolution of the previous, demonstrating how customers can build  their own automation framework. Each use case offers a different level of automation and also provides additional benefits, such as audit trail, code reviews, and many more. This way, customers can choose what best fits their knowledge and experience with these tools. Whether you are new to automation or already skilled in IaC practices, these examples will help you make your F5 application deployment processes easier and more efficient.

Building an Automation Framework (Stages/Levels)

- [Level 1 - Per App AS3 with Terraform](level-1/README.md)
- [Level 2 - Introducing GIT](level-2/README.md)
- [Level 3 - Using Pipelines](level-3/README.md)
- [Level 4 - Collaborating with Merge Requests](level-4/README.md)
- [Level 5 - Self Service Deployments](level-5/README.md)


## Table of Contexts

- [Introduction](#automating-bigip-with-per-app-as3-and-terraform)
- [Technologies used](#technologies-used)
- [Deploying Services with Terraform](#deploying-services-with-terraform)
  - [Adding new services](#adding-new-services)
  - [Modifying services](#modifying-services)
- [Best Practices](#best-practices-for-bigip-tmos)


## Technologies used

Based on the use-case (level) you choose, there could be up to four technologies that are used to build the automation framework. These are:

- **AS3**. AS3 provides a declarative interface, enabling the management of application-specific configurations on a BIG-IP system. By providing a JSON declaration rather than a series of imperative commands, AS3 ensures precise configuration orchestration. We utilize the latest Per-App AS3 feature to optimize configuration granularity. You can find more information on [https://clouddocs.f5.com/products/extensions/f5-appsvcs-extension/latest/](https://clouddocs.f5.com/products/extensions/f5-appsvcs-extension/latest/)

- **F5 BIG-IP Terraform Provider**. The F5 BIG-IP Terraform Provider helps you manage and provision your BIG-IP configurations in Terraform through the use of AS3/DO integration.You can find more information on [https://registry.terraform.io/providers/F5Networks/bigip/latest/docs](https://registry.terraform.io/providers/F5Networks/bigip/latest/docs)


- **Git**. Git serves as the backbone of our GitOps approach, acting as the repository for storing desired configurations. It not only serves as the source of truth for AS3 configurations but also provides an audit trail of all changes made throughout the application lifecycle and enables collaboration and code reviews through the use merge requests.

- **CI/CD**. A Continuous Integration and Continuous Deployment (CI/CD) tool is crucial in automating the changes that have been identified in configuration files throughout the application lifecycle. Not only it can orchestrate the deployment of AS3 declarations with Terraform, but also integrate with 3rd party 
ersion of YAML configurations into AS3 declarations using Jinja2 templates, and subsequent deployment of changes to the BIG-IP repositories. Additionally, CI/CD orchestrates the deployment of AS3 declarations to BIG-IP and other automation workflows, ensuring a seamless and efficient process.

By combining these components into a cohesive automation framework, organizations can achieve greater agility, scalability, and reliability in managing their F5 BIG-IP deployments. This approach empowers teams to focus on innovation and value delivery, while automation handles the repetitive and error-prone tasks associated with infrastructure configuration and deployment.


## Deploying Services with Terraform
When using Terraform, before applying any changes to your infrastructure, it is crucial to understand what modifications Terraform will make. By running and examining the output of **terraform plan**, you can verify that the planned changes match your intentions. This step is crucial for ensuring that your updates are applied correctly and that no unintended modifications occur. It provides a clear and detailed preview of the infrastructure changes, enhancing your control over the deployment process.

### Adding new services
When you create a new configuration and execute **terraform plan**, you will see an output similar to the one below, indicating that the `bigip_as3` resource of the module `appX` and the will be created. In this example, the plan indicates that the `bigip_as3` resource will be created along with the details of the application, including the pool members, port number, and virtual address. The `+` symbol denotes attributes that will be created.

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

### Modifying services
When you make modifications to your Terraform configuration, such as changing an IP address, running **terraform plan** will show you the exact changes that will be applied. This helps you understand the impact of your changes before they are executed.

For instance, if you update the virtual address for an application, the plan indicates that the `bigip_as3` resource will be updated in place. The as3_json section shows the change from the old IP address ***10.1.120.111*** to the new IP address ***10.1.120.112***. The `~` symbol denotes attributes that will be updated. Here's an example of the output you should see:

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

### Deleting services
When you remove configuration from the Terraform directory, running **terraform plan** will show you the exact resources/attributes that will be removed. The `-` symbol denotes attributes that will be deleted. Here's an example of the output you should see:


```tf
Terraform will perform the following actions:

  # module.app1.bigip_as3.as3 will be destroyed
  - resource "bigip_as3" "as3" {
      - application_list = "path_app1" -> null
      - as3_json         = jsonencode(
            {
              - path_app1     = {
                  - app1      = {
                      - class            = "Service_HTTP"
                      - pool             = "pool_app1"
                      - virtualAddresses = [
                          - "10.1.120.82",
                        ]
                      - virtualPort      = 80
                    }
                  - class     = "Application"
                  - pool_app1 = {
                      - class   = "Pool"
                      - members = [
                          - {
                              - serverAddresses = [
                                  - "10.1.20.10",
                                  - "10.1.20.11",
                                ]
                              - servicePort     = 80
                              - shareNodes      = true
                            },
                        ]
                    }
                }
              - schemaVersion = "3.50.1"
            }
        ) -> null
      - id               = "uat1" -> null
      - ignore_metadata  = false -> null
      - per_app_mode     = true -> null
      - task_id          = "b3eafcf8-fddd-4380-b153-5e4c72ca178c" -> null
      - tenant_filter    = "uat1" -> null
      - tenant_list      = "uat1" -> null
      - tenant_name      = "uat1" -> null
    }

Plan: 0 to add, 0 to change, 1 to destroy.
```



### Best Practices (for BIGIP TMOS)

When running **`terraform plan`** on BIGIP TMOS it is suggested to use some additional parameters of the **plan**. These are:

- **`-refresh=false`**: The `-refresh=false` option is used to prevent Terraform from updating the state file with the latest information from the infrastructure provider before running the plan and uses the existing state information instead. The reason behind this, is because refreshing the state can be time-consuming, especially in large infrastructures and disabling the refresh can speed up the plan execution significantly.

- **`-parallelism=1`**: Ensures that operations are executed sequentially. The reason for using this additional parameter is because AS3 on BIGIP Classic can handle 1 concurrent operations at any point in time and setting `parallelism` to 1 ensures that Terraform processes operations sequentially. Additionally running AS3 operations one at a time makes it easier to identify and debug issues, as the order of operations is clear and predictable.

- **`-out=tfplan`**: Saves the plan output to a file named `tfplan`, which can be used later with `terraform apply`. By providing this plan file, you instruct Terraform to apply the exact set of changes that were outlined in the plan. This ensures that the changes applied are consistent with what was reviewed during the planning stage, avoiding any surprises or unintended modifications.

```cmd
terraform plan -parallelism=1 -refresh=false -out=tfplan
```

When running **`terraform apply`** it is suggested to use the following parameters:
- **`-parallelism=1`**

- **`-out=tfplan`**

```cmd
terraform apply -parallelism=1 "tfplan"
```
