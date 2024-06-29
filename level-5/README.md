# Empowering Customers to Create Their Own Configurations

In `Level-5`, we enhance the automation framework to enable customers or teams to create their own configurations for the BIG-IP platform. In this scenario, each customer/team manages their own Git repository, where they can make changes and commit configurations. The pipeline will then convert the configuration to **Per-App AS3** and push the changes to a downstream repository on a specific branch, allowing BIG-IP admins to review and approve the merge requests.

![level-5](../images/level-5.png)


# Table of Contexts


- [Use case workflow](#use-case-workflow)
- [Code Explanation](#code-explanation)
  - [Pipeline](#pipeline)
- [Demo with UDF](#demo-with-udf)

## Use case workflow
The workflow for this use-case is as follows:

- **Customer Repositories:**
    - Each customer/team has their own Git repository where they can manage their configurations.
    - Customers/teams create and modify YAML files that reflect the configuration that is needed.
    - When a customer commits a change to their repository, a CI/CD pipeline is triggered.
    - The pipeline converts the YAML file to an AS3 and Terraform configuration and pushes the changes to a downstream repository, specifically to a designated branch for that customer/team.
    - The pipeline will create a merge request on the downstream repository for that particular branch 
- **Downstream Repository:**
    - The downstream repository contains branches for each customer/team.
    - BIG-IP admins monitor the downstream repository for new merge requests.
    - Admins review the proposed changes, provide feedback if necessary, and approve the merge requests.
    - Once approved, the changes are merged into the main branch and deployed to the BIG-IP platform with the use of Terraform and AS3

## Code Explanation



# WORK IN PROGRESS



