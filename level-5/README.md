# Empowering Customers to Create Their Own Configurations

In `Level-5`, we enhance the automation framework to enable customers or teams to create their own configurations for the BIG-IP platform. In this scenario, each customer/team manages their own Git repository, where they can make changes and commit configurations. The pipeline will then convert the configuration to **Per-App AS3** and push the changes to a downstream repository on a specific branch, allowing BIG-IP admins to review and approve the merge requests.

![level-5](../images/level-5.png)


# Table of Contexts

- [Use case workflow](#use-case-workflow)
- [Code Explanation](#code-explanation)
  - [Pipeline](#pipeline)
- [Demo with UDF](#demo-with-udf)
- [Demo on your local environment](#demo-on-your-local-environment)

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
    - Once approved, the changes are merged into the customer's branch and be deployed to the BIG-IP platform with the use of Terraform and AS3

## Code Explanation

### User configuration files (YAML)
To enhance usability, users only need to define the parameters of the service they intend to publish and save them in a YAML file format. YAML was selected for its user-friendly interface, which is both intuitive and familiar to DevOps users. Alternatively, customers may opt to utilize a ServiceNow ticket or a REST-API/web form, enabling their users to input the required information seamlessly. An example of the YAML parameters is shown below 

```yml
# Filename app01.yml
---
name: app01
partition: prod
location: dmz
comments: This is a new web server for testing
type: http
virtual_server:
  ip: 10.1.10.152
  port: 80
members:
  - ip: 10.1.20.21
    port: 30880
```

### Converting YAML to AS3 and TF configuration
Once the user defines the configuration they want to apply in the YAML file, this needs to be converted to:
- Per-App **AS3** JSON declaration 
- Terraform **bigip_as3** resource

To streamline the conversion of YAML to AS3 and TF, we leverage JINJA2 templates. These templates dynamically incorporate input from YAML file(s) as variables, facilitating the generation of the final AS3 JSON and TF config files. This seamless integration occurs within the CI/CD pipeline framework and is orchestrated through an Ansible playbook for efficiency and the resulting AS3/TF configurations are being stored in the downstream (BIG-IP) repository. 

<p align="center">
  <img src="../images/templates.png" style="width:85%">
</p>

Below you can find the ansible playbook that we are using to achieve the transformation. The ansible **templates** and **playbook** can be found on the folders `Jinja2` and `Ansible`.  
```yml
---
- name: Create Per-App AS3 configurations
  hosts: localhost
  gather_facts: no

  tasks:
    - name: Create AS3 JSON
      ansible.builtin.template:
        src: templates/http.j2
        dest: temp_as3

    - name: Pretty Print AS3
      shell: jq . temp_as3 > as3/{{name}}.json

    - name: Create TF config file
      ansible.builtin.template:
        src: templates/tf.j2
        dest: tf/{{name}}.tf
        
```

### User Repositories and pipeline
Each customer creates their configuration files in YAML format on their repository. When a new file is added, modified, or deleted, the pipeline is triggered, proceeding through the following stages:

  - **Template Conversion**: This is the first stage that utilizes JINJA2 templates to translate the YAML files into corresponding AS3 declarations and TF configuration. The resultant output is stored in two distinct directories, **tf** and **as3**, and passed on to the next stage as an artifact.
  - **GIT**: In this second and final stage, the pipeline pushes the files residing in the as3 and tf directories to the upstream repository that is the source of truth for BIG-IP configuration.

The pipeline configuration for the User reposistories can be found under the `Pipelines` folder.


### BIGIP Repositories and pipeline
The BIG-IP repositories serve as repositories for AS3 declaration and TF files generated from the YAML specifications. They act as the definitive source of truth for configuring **F5 BIG-IP** and facilitate version-controlled management. While our example employs a single BIG-IP, the use-case can be adapted utilizing the `providers.tf` to have multiple BIGIP devices.

Each customer is assigned 2 branches on **BIGIP** repository. The first branch is named after the customer's repository and it is the primary branch while the second branch is a temporary branch that each customers will push their changes for their upstream repository. 

Within the BIG-IP repository, we've implemented a pipeline very similar to  `Level-4`. The pipeline configuration for the BIGIP reposistories can be found under the `Pipelines` folder.

The pipeline configuration for the bigip repos can be found on the following [**file**](https://github.com/f5emea/oltra/use-cases/automation/bigip/pipelines/bigip-pipeline.yml)


## Demo with UDF

### Step 1. Review the repositories
Access the web interface **GitLab** that is under the `bigip-01` on the `Access` drop-down menu. Click <a href="https://raw.githubusercontent.com/f5devcentral/bigip-automation/main/images/gitlab.png"> here </a> to see how.

Log on to GitLab using the root credentials (**root**/**Ingresslab123**) and review the 4 repositories that will be used in the use case.

- `customer-a` and `customer-b` are the two repos that are used to save the highlevel VirtualServer configuration in a YAML format.
- `bigip` is the repository that holds all the AS3 JSON files that serve as the source of truth for the BIG-IP. For simplicity, the configuration for each customer is stored on a separate branch 
- `automation_files` is the repo that holds all the pipelines, Ansible playbooks and JINJA2 templates

<p align="center">
  <img src="../images/step-1-lvl-5.gif.gif" style="width:75%">
</p>

### Step 2. Create the YAML file with the required key value pairs

We will create a new file on `customer-a` repository called **`app01.yaml`** and the file will contain the following configuration

```yaml
name: app01
partition: prod
location: dmz
type: http
virtual_server:
  ip: 10.1.10.152
  port: 80
pool_members:
  - ip: 10.10.10.11
    port: 80
  - ip: 10.10.10.12
    port: 80
```

<p align="center">
  <img src="../images/step-2-lvl-5.gif" style="width:75%">
</p>

### Step 3. Review the pipeline stages on `customer-a` repository

Select "Pipelines" on the left side of the GitLab page and review the pipeline that was just executed from your latest commit

<p align="center">
  <img src="../images/step-3-lvl-5.gif" style="width:75%">
</p>


### Step 4. Review the Merge Request on BIGIP repo

Go to the BIGIP repository and and select the Merge Requests (MR). You should see a MR from `customer-a`. Open the MR and Navigate through the different tabs/pages going through the **Pipeline**, **Commits** and **Changes**.

<p align="center">
  <img src="../images/step-4-lvl-5.gif" style="width:75%">
</p>

> Notice that there is a new **Temporary** Branch that has been created for the change, called `customer-a-draft`. This should be deleted when the MR is approved.


### Step 5. Approve the Merge Request

Once you have reviewed the MR, you should then approve the Merge Request. Once approved, the changes should be pushed to the **Branch** that holds the configuration for `customer-a` and the **Final** pipeline should start. 

<p align="center">
  <img src="../images/step-5-lvl-5.png" style="width:75%">
</p>


### Step 6. Review Pipeline outcome

Once the MR is approved, the pipeline should run **Terraform plan/apply** in order to push the configuration to BIGIP. Please review the pipeline steps going through the logs and artifacts.

<p align="center">
  <img src="../images/step-6-lvl-5.gif" style="width:75%">
</p>



## Demo on your local environment

### Prerequisites
- BIGIP running version v15 (or higher)
- Installed AS3 (v3.50 or higher) on BIGIP 
- GitLab.com account
- Docker that will host GitLab-Runner

> [!NOTE]
> The instructions provided for this demo will work on macOS and Linux users. However, for Windows users, keep in mind that modifications might be needed before running the code. 

### Step 1. Fork the existing repositories

We have create 4 repositories that you need to fork
- **Customer A**       -> https://gitlab.com/f5emea/customer-a
- **Customer B**       -> https://gitlab.com/f5emea/customer-b
- **BIGIP**            -> https://gitlab.com/f5emea/bigip
- **Automation Files** -> https://gitlab.com/f5emea/automation-files


**Customer A and B** repositories will hold the YAML files that will contain the application configuration.
**BIGIP** repository will hold the AS3 and TF files that will be pushed by the **Customer A and B** pipeline. 
**Automation Files** repository contains the pipeline and templates that will be used during this demo.

Navigate to these repositories and press the **Fork** button on the top right corner. You should be prompted with the following page. Fill in the required information and press **Fork Project**. 

<p align="center">
  <img src="../images/fork.png" style="width:75%">
</p>


### Step 2. Update Pipeline files

Go to the `automation-files` repository that you forked and change the variables for **bigip-pipeline.yml** and **user-pipeline.yml**

```yml
variables:
  upstream_repo: "<< Add-your-own-bigip-repo --- for example --->  gitlab.com/f5emea/bigip.git>>"
  git_username: "<< Add-your-username >>"
  git_access_token: "<< Add-your-access-token >>"
  git_email: "Add-your-own email example@gmail.com"
  git_name: "John Doe"
```

### Step 3. Fork the existing repositories
Go to repositories and update the **CI/CD configuration file** location. You will find this, for each repo, under `Settings` --> `CI/CD` --> `General Pipelines`.

For Repos **Customer A and B** add the `user-pipeline.yml` file that is located at the **Automation-files** repo and for **BIGIP** and add the `bigip-pipeline.yml` file.

<p align="center">
  <img src="../images/ci-cd-location.png" style="width:75%">
</p>


### Step 4. Create a personal access token
> [!NOTE]
> You can use the same personal access token, that you created during `Level-3` Demo.

Follow the instruction below to create a personal access token. 

1. On the left sidebar, select your avatar.
1. Select Edit profile.
1. On the left sidebar, select Access Tokens.
1. Select Add new token.
1. Enter a name and expiry date for the token.
    - If you do not enter an expiry date, the expiry date is automatically set to 365 days later than the current date.
    - By default, this date can be a maximum of 365 days later than the current date.
1. Include the following scopes (api, read_api, read_repository, write_repository, read_registry, write_registry).
1. Select create personal access token.


<p align="center">
  <img src="../images/personal-access-token.png" style="width:75%">
</p>

> [!IMPORTANT]
> Copy your new personal access token and make sure you save it - you won't be able to access it again.


### Step 5. Create a GitLab Runner
> [!NOTE]
> You can skip this step if you have already created the GitLab runner during the `Level-3` Demo.

With GitLab you can use either privately-hosted or GitLab-hosted runners. For this demo, we recommend that you use a privately-hosted runners so that you don't have to expose F5's Management interface to the internet. 
In the following few steps we will show how to install and configure your own Gitlab runner in a docker environment. If you want to deploy it in a different environment or you can find more information regarding GitLab runners click <a href="https://docs.gitlab.com/ee/tutorials/create_register_first_runner/"> here </a>


Create the Docker volume:
```
docker volume create gitlab-runner-config
```

Start the GitLab Runner container using the volume we just created:
```
docker run -d --name gitlab-runner --restart always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v gitlab-runner-config:/etc/gitlab-runner \
    gitlab/gitlab-runner:latest
```

> [!NOTE]
> If the states during the pipleline are getting queued for more than 5-10 seconds then you can improve that by changing the concurrency to **5** in the `config.toml` file. If you are using Ubuntu you can find this file in the following folder `/var/lib/docker/volumes/gitlab-runner-config/_data/` 

### Step 6. Register your GitLab Runner
> [!NOTE]
> You can skip this step if you have already created the GitLab runner during the `Level-3` Demo. You just need to select the button `Enable for this project` that will be found on `Setttings`->`CI/CD`->`Runners`. This needs to be done on the **customer** and **bigip** repositories.

On the **customer** and **bigip** repositories click the button the `New project runner` that can be be found under `Setttings`->`CI/CD`->`Runners`.

<p align="center">
  <img src="../images/new-project-runner.png" style="width:75%">
</p>

On the following page, add a runner `description`, select the option `run untagged jobs` and press **Create runner**.

<p align="center">
  <img src="../images/new-project-runner-v2.png" style="width:75%">
</p>

In the next screen you will see the command that you need to run in order to register you gitlab-runner.

<p align="center">
  <img src="../images/register-runner.png" style="width:65%">
</p>

Use the following docker exec command to start the registration process. Make sure you add your own token to the command below.
```
docker exec -it gitlab-runner gitlab-runner register --url https://gitlab.com --token <add-the-token-you-got-from-gitlab>
```
You will be asked to fill in the following:

- Enter the GitLab instance URL (for example, https://gitlab.com/): **Leave Blank**
- Enter a description for the runner: **Add the Description for the runner**
- Enter an executor: custom, shell, ssh, parallels, docker-windows, docker-autoscaler, virtualbox, docker, docker+machine, kubernetes, instance: **Select docker**
- Enter the default Docker image (for example, ruby:2.7):

Once the registration is complete you should be able to see that the runner under the assigned project runners.

<p align="center">
  <img src="../images/project-runners.png" style="width:75%">
</p>

> [!IMPORTANT]
> Before moving to the next step, disable the **Instance runners** so that you don't use GitLab-hosted runners.



### Step 7. Create the YAML file with the required key value pairs

We will create a new file on `customer-a` repository called **`app01.yaml`** and the file will contain the following configuration

```yaml
name: app01
partition: prod
location: dmz
type: http
virtual_server:
  ip: 10.1.10.152
  port: 80
pool_members:
  - ip: 10.10.10.11
    port: 80
  - ip: 10.10.10.12
    port: 80
```

<p align="center">
  <img src="../images/step-2-lvl-5.gif" style="width:75%">
</p>

### Step 8. Review the pipeline stages on `customer-a` repository

Select "Pipelines" on the left side of the GitLab page and review the pipeline that was just executed from your latest commit

<p align="center">
  <img src="../images/step-3-lvl-5.gif" style="width:75%">
</p>


### Step 9. Review the Merge Request on BIGIP repo

Go to the BIGIP repository and and select the Merge Requests (MR). You should see a MR from `customer-a`. Open the MR and Navigate through the different tabs/pages going through the **Pipeline**, **Commits** and **Changes**.

<p align="center">
  <img src="../images/step-4-lvl-5.gif" style="width:75%">
</p>

> Notice that there is a new **Temporary** Branch that has been created for the change, called `customer-a-draft`. This should be deleted when the MR is approved.


### Step 10. Approve the Merge Request

Once you have reviewed the MR, you should then approve the Merge Request. Once approved, the changes should be pushed to the **Branch** that holds the configuration for `customer-a` and the **Final** pipeline should start. 

<p align="center">
  <img src="../images/step-5-lvl-5.png" style="width:75%">
</p>


### Step 11. Review Pipeline outcome

Once the MR is approved, the pipeline should run **Terraform plan/apply** in order to push the configuration to BIGIP. Please review the pipeline steps going through the logs and artifacts.

<p align="center">
  <img src="../images/step-6-lvl-5.gif" style="width:75%">
</p>

