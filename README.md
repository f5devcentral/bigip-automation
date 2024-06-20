# Automating BIGIP with Per-App AS3 and Terraform

In the modern era of IT, automation and infrastructure as code (IaC) have become pivotal in streamlining operations and enhancing the agility of organizations. Terraform, an open-source IaC tool, allows administrators to define and provision infrastructure using a high-level configuration language. When combined with F5 Per App AS3, a declarative configuration API for BIG-IP, the result is a powerful solution for managing application services more efficiently and consistently.

For F5 administrators, leveraging Terraform with AS3 can drastically reduce the time and effort required to deploy and manage application services. Automation not only minimizes human errors but also ensures that configurations are consistent across different environments. This enables organizations to respond quickly to changing business needs, scale their operations seamlessly, and maintain a high level of operational efficiency.

In this repository, we will explore four use cases, each being the evolution of the previous, demonstrating how customers can build  their own automation framework. Each use case offers a different level of automation and also provides additional benefits, such as  code version control, code reviews, and many more. This way, customers can choose the one that best fits their knowledge and experience with these tools. Whether you are new to automation or already skilled in IaC practices, these examples will help you make your deployment processes easier and more efficient.

Building an Automation Framework (Stages/Levels)

- [Level 1 - Per App AS3 with Terraform](level-1/README.md)
- [Level 2 - Introducing GIT](#level-2.md)
- [Level 3 - Using Pipelines](#technologies-used)
- [Level 4 - Collaborating with Merge Requests](#technologies-used)
- [Level 5 - Self Service Deployments](#technologies-used)


## Technologies used

To create this automation use-case, we leverage the following 4 technologies:

- **AS3**. AS3 provides a declarative interface, enabling the management of application-specific configurations on a BIG-IP system. By providing a JSON declaration rather than a series of imperative commands, AS3 ensures precise configuration orchestration. We utilize the latest Per-App AS3 feature to optimize configuration granularity. You can find more information on [https://clouddocs.f5.com/products/extensions/f5-appsvcs-extension/latest/](https://clouddocs.f5.com/products/extensions/f5-appsvcs-extension/latest/)

- **F5 BIG-IP Terraform Provider**. The F5 BIG-IP Terraform Provider helps you manage and provision your BIG-IP configurations in Terraform through the use of AS3/DO integration.You can find more information on [https://registry.terraform.io/providers/F5Networks/bigip/latest/docs](https://registry.terraform.io/providers/F5Networks/bigip/latest/docs)


- **Git**. Git serves as the backbone of our GitOps approach, acting as the repository for storing desired configurations. It not only serves as the source of truth for AS3 configurations but also provides an audit trail of all changes made throughout the application lifecycle and enables collaboration and code reviews through the use merge requests.

- **CI/CD**. A Continuous Integration and Continuous Deployment (CI/CD) tool is crucial in automating the changes that have been identified in configuration files throughout the application lifecycle. Not only it can orchestrate the deployment of AS3 declarations with Terraform, but also integrate with 3rd party 
ersion of YAML configurations into AS3 declarations using Jinja2 templates, and subsequent deployment of changes to the BIG-IP repositories. Additionally, CI/CD orchestrates the deployment of AS3 declarations to BIG-IP and other automation workflows, ensuring a seamless and efficient process.

By combining these components into a cohesive automation framework, organizations can achieve greater agility, scalability, and reliability in managing their F5 BIG-IP deployments. This approach empowers teams to focus on innovation and value delivery, while automation handles the repetitive and error-prone tasks associated with infrastructure configuration and deployment.



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


### Best Practices when used with BIGIP TMOS

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
