# Centralizing Terraform Execution with Pipelines and Remote State

In our `Level-2` use case, we moved our Terraform code to Git, enabling us to leverage a reliable version control system. However, users continued to execute Terraform commands from their local machines.

In `Level-3` we are introducing 2 new elements to enhance the automation framework. 
  1. **Remote Terraform state**. 
      - By default, Terraform stores its state locally in a file named terraform.tfstate. When working in a team, using a local file complicates Terraform usage because each user must ensure they have the latest state data before running Terraform, and must avoid simultaneous runs by others.
      - With remote state, Terraform writes the state data to a remote data store, which can then be shared among all team members. This ensures consistency and prevents conflicts.
      - Terraform supports various remote state backends, including HCP Terraform, HashiCorp Consul, GitLab, Amazon S3, Azure Blob Storage, Google Cloud Storage, Alibaba Cloud OSS, and more. For our use case, we will use GitLab as the remote data store for the terraform.tfstate file.
  2. **Pipelines**. 
      - Instead of executing Terraform commands on each user's machine, we will implement a CI/CD pipeline within the GitLab repository. This pipeline will trigger automatically with every commit to the repository, centralizing and streamlining the deployment process.
      - The pipeline will execute the necessary Terraform commands, along with any additional scripts or commands required for the deployment. This approach ensures consistency, reduces human error, and enhances the overall automation of our infrastructure management.


![level-3](../images/level-3.png)


# Table of Contexts

- [Use case workflow](#use-case-workflow)
- [Code Explanation](#code-explanation)
  - [Remote State](#remote-state)
  - [Pipeline](#pipeline)
- [Demo with UDF](#demo-with-udf)
- [Demo on your local environment](#demo-on-your-local-environment)


## Use case workflow
The workflow for this use case is as follows:
  1. The Terraform code is stored on a Git platform (GitLab on-prem or cloud).
  1. Users clone the repository to their local machines. (Terraform is NOT required) 
  1. Users create or make changes to the Terraform files and commit these changes back to the Git repository with appropriate commit messages.
  1. GitLab triggers a pipeline that runs the Terraform commands automatically.

**Benefits:**
  - All benefits of `Level-2` use case
  - **Centralized Execution**: Terraform commands run from a centralized location, eliminating the need for local installations on each user's machine.
  - **Log and Output History**: A comprehensive history of all Terraform logs and outputs is maintained alongside the Git commits, providing an audit trail and facilitating troubleshooting.
  - **Auditability**: Changes are documented through Terraform’s execution plans and logs, providing an audit trail for compliance and troubleshooting purposes.
  


## Code Explanation
In the following section, we  provide a deeper explanation of how **remote state** is configured as well as details on the **pipeline** configuration.

### *Remote State*
Remote state in Terraform refers to the practice of storing the state file, which contains the current state of your infrastructure, in a remote and shared location. This allows multiple team members to work on the same Terraform configuration without the risk of state file conflicts. By default, Terraform stores the state locally in a file named terraform.tfstate, but when working in a team, this local storage can lead to issues with consistency and concurrency. Remote state solves these problems by providing a single source of truth that can be accessed and updated by all team members.
We will be using GitLab to store the remote state, but there are many other options for you to consider. Terraform supports storing state in HCP Terraform, HashiCorp Consul, Amazon S3, Azure Blob Storage, Google Cloud Storage, and many more.

By using GitLab, you can:

- Version your Terraform state files.
- Encrypt the state file both in transit and at rest.
- Lock and unlock states.
- Remotely execute terraform plan and terraform apply commands.


**Configuring Remote State for HTTP Backend in GitLab**.

Below you can find the configuration we are using on our pipeline in order to have access to the remote state.

```tf
PROJECT_ID="<gitlab-project-id>"
TF_USERNAME="<gitlab-username>"
TF_PASSWORD="<gitlab-personal-access-token>"
TF_ADDRESS="https://gitlab.com/api/v4/projects/${PROJECT_ID}/terraform/state/old-state-name"

terraform init \
  -backend-config=address=${TF_ADDRESS} \
  -backend-config=lock_address=${TF_ADDRESS}/lock \
  -backend-config=unlock_address=${TF_ADDRESS}/lock \
  -backend-config=username=${TF_USERNAME} \
  -backend-config=password=${TF_PASSWORD} \
  -backend-config=lock_method=POST \
  -backend-config=unlock_method=DELETE \
  -backend-config=retry_wait_min=5
```

### *Pipeline*
In this section we provide an overview of the pipeline configuration and how it works. We will be breaking up the pipeline, but you can find the entire pipeline <a href="https://github.com/f5devcentral/bigip-automation/blob/main/level-3/.gitlab-ci.yml"> here </a>

#### Workflow
The pipeline is triggered based on specific conditions:

- It will not trigger if the commit message ends with `-draft`.
- It will always trigger for `merge request` events.
- It will trigger for commits to the `main` branch.

```yml
workflow:  
    rules:
      - if: $CI_COMMIT_MESSAGE =~ /-draft$/
        when: never     
      - if: $CI_PIPELINE_SOURCE == "merge_request_event"
        when: always
      - if: $CI_COMMIT_BRANCH == "main"
        when: always
      - when: never
```
#### Variables
The pipeline defines several variables:

**TF_DIR**: Directory containing Terraform files.
**STATE_NAME**: Name of the Terraform state used in the terraform init command.
**ADDRESS**: URL for the remote Terraform state in GitLab.
**TF_USERNAME**: Terraform username, provided via environment variable.

```yml
variables:
  TF_DIR: ${CI_PROJECT_DIR}
  STATE_NAME: "tf_state_lvl_2"
  ADDRESS: "https://git.f5k8s.net/api/v4/projects/${CI_PROJECT_ID}/terraform/state/${STATE_NAME}"
  TF_USERNAME: $tf_user
```
#### Stages & Image
The pipeline consists of three stages but you can change them according to your requirements:

- Validation
- Plan
- Apply

The Docker image used was `skenderidis/ansible-runner:terraform` but you can change it to any image that support Terraform.

```yml
# Stages of the pipeline
stages:
  - validation
  - plan
  - apply

# Image which will use in each stage
image:
  name: skenderidis/ansible-runner:terraform
  entrypoint: [""]
```


#### Validation Stage
Typically the validation stage is customer specific in order to verify the configuration based on their requirements, so in this demo we have left it without any configuration.
```yml
verify:
  stage: validation
  script:
    - echo "ok"
  only:
    - main
```

#### Plan Stage

This stage involves:

- Initializing Terraform with the remote state backend.
- Creating a plan to identify changes (create, update, delete).
- Saving the tfplan as an artifact to be used by the **apply** stage
- (optional) Saving detailed information about these changes that terraform will perform as artifacts (tf_details folder).
- (optional) Saving the JSON declarations as artifacts (as3 folder)

Plan stage and will only run during `main` branch commits and merge requests

```yml
plan:
  stage: plan
  script:
    # Initialize variables and get terraform version for troubleshooting
    - terraform --version
    - export GITLAB_ACCESS_TOKEN=$tf_access_token
    - echo $GITLAB_ACCESS_TOKEN
    - cd ${TF_DIR}            # To get inside the working directory
    # To initiate terraform backend / gitlab managed terraform state
    - |
      terraform init \
      -backend-config=address=${ADDRESS} \
      -backend-config=lock_address=${ADDRESS}/lock \
      -backend-config=unlock_address=${ADDRESS}/lock \
      -backend-config=username=${TF_USERNAME} \
      -backend-config=password=${GITLAB_ACCESS_TOKEN} \
      -backend-config=lock_method=POST \
      -backend-config=unlock_method=DELETE \
      -backend-config=retry_wait_min=5

    - terraform plan -parallelism=1 -refresh=false -out=tfplan
    
    ##########      OPTIONAL      #########
    # create a folder to be saved as an artifact at the end of the stage
    - mkdir tf_details
    # save changes (create/update/delete) as artifact.
    - terraform show -no-color -json tfplan | jq -r '.resource_changes[] | select(.change.actions[0]=="update")' > tf_details/update.json
    - terraform show -no-color -json tfplan | jq -r '.resource_changes[] | select(.change.actions[0]=="create")' > tf_details/create.json
    - terraform show -no-color -json tfplan | jq -r '.resource_changes[] | select(.change.actions[0]=="delete")' > tf_details/delete.json

    ##########      OPTIONAL      #########
    # create a folder to be saved as an artifact at the end of the stage
    - mkdir as3
    # Save the updated AS3 for applications that will be updated
    - terraform show -no-color -json tfplan | jq -r '.resource_changes[] | select(.change.actions[0]=="update") | select(.change.after.as3_json and .module_address and .change.after.tenant_name) | "\(.module_address) \(.change.after.tenant_name) \(.change.after.as3_json)"' | while IFS=' ' read -r module_address tenant_name as3_json; do   module_address=$(echo "$module_address" | sed 's/^module.//'); file_name="as3/${tenant_name}_${module_address}-(updated).json";  echo "$as3_json" | jq . > "$file_name"; done
    # Save the new AS3 for applications that will be created
    - terraform show -no-color -json tfplan | jq -r '.resource_changes[] | select(.change.actions[0]=="create") | select(.change.after.as3_json and .module_address and .change.after.tenant_name) | "\(.module_address) \(.change.after.tenant_name) \(.change.after.as3_json)"' | while IFS=' ' read -r module_address tenant_name as3_json; do   module_address=$(echo "$module_address" | sed 's/^module.//'); file_name="as3/${tenant_name}_${module_address}-(created).json";  echo "$as3_json" | jq . > "$file_name"; done
    # Save the AS3 for applications that will be deleted
    - terraform show -no-color -json tfplan | jq -r '.resource_changes[] | select(.change.actions[0]=="delete") | select(.change.before.as3_json and .module_address and .change.before.tenant_name) | "\(.module_address) \(.change.before.tenant_name) \(.change.before.as3_json)"' | while IFS=' ' read -r module_address tenant_name as3_json; do   module_address=$(echo "$module_address" | sed 's/^module.//'); file_name="as3/${tenant_name}_${module_address}-(deleted).json";  echo "$as3_json" | jq . > "$file_name"; done

    #verify the files (artifacts) created
    - ls -l as3
    - ls -l tf_details

  artifacts:
    paths:
      - tfplan
      - tf_details
      - as3
  only:
    - merge_requests
    - main

```

#### Apply Stage
This stage applies the changes based on the Terraform plan generated in the previous stage and will only run during `main` branch commits 


```yml
# To apply the TF plan for any changes on the BIGIP Virtual Servers
apply:
  stage: apply
  script:
    # Initialize variables and get terraform version for troubleshooting
    - terraform --version
    - export GITLAB_ACCESS_TOKEN=$tf_access_token
    - echo $GITLAB_ACCESS_TOKEN
    - cd ${TF_DIR}            # To get inside the working directory
    # To initiate terraform backend / gitlab managed terraform state
    - |
      terraform init \
      -backend-config=address=${ADDRESS} \
      -backend-config=lock_address=${ADDRESS}/lock \
      -backend-config=unlock_address=${ADDRESS}/lock \
      -backend-config=username=${TF_USERNAME} \
      -backend-config=password=${GITLAB_ACCESS_TOKEN} \
      -backend-config=lock_method=POST \
      -backend-config=unlock_method=DELETE \
      -backend-config=retry_wait_min=5    

    # Apply the changes
    - terraform apply -parallelism=1 "tfplan"

  dependencies:              
    - plan

  only:
    - main
```

## Demo with UDF

- Deploy the **Oltra** UDF Deployment
- Use the terminal on **VS Code** to run the commands. **VS Code** is under the `bigip-01` on the `Access` drop-down menu.  Click <a href="https://raw.githubusercontent.com/f5devcentral/bigip-automation/main/images/vscode.png"> here </a> to see how.


### Step 1. Clone Terraform repository

Open the `VS Code` terminal and clone `tf-level-3` from the internally hosted GitLab.
```
git clone https://root:Ingresslab123@git.f5k8s.net/bigip/tf-level-3.git
```


### Step 2. Go to Terrafrom directory

Change the working directory to `tf-level-3`
```
cd tf-level-3
```

### Step 3. Create a new configuration
Create the configuration to publish a new application and save the file as `app3.tf`.

```cmd
cat <<EOF > app3.tf
module "app3" {
    source              = "./modules/as3_http"
    name                = "app3"
    virtualIP           = "10.1.10.44"
    serverAddresses     = ["10.1.20.21"]
    servicePort         = 30880
    partition           = "prod"
    providers = {
      bigip = bigip.dmz
    }    
}
EOF
```

### Step 4. Commit the changes to Git
Add you details on Git so that any changes you make will include your name. This will make it easier in the future to identify who made the change.

```cmd
git config user.name "John Doe"
git config user.email "j.doe@f5.com"
```

Run the following commands that will push the changes made on the configuration files back to the origin Git repository
```cmd
git add .
git commit -m "Adding application app03"
git push
```

### Step 5. Login to Git to review the pipeline output.

Access the web interface **GitLab** that is under the `bigip-01` on the `Access` drop-down menu. Click <a href="https://raw.githubusercontent.com/f5devcentral/bigip-automation/main/images/gitlab.png"> here </a> to see how.

Log on to GitLab using the root credentials (**root**/**Ingresslab123**) and select the repository `bigip / tf_level_3`. 

<p align="center">
  <img src="../images/repo-lvl3.gif" style="width:80%">
</p>


Go to `Pipelines` and review the execution of the lastest pipeline. You should be able to see all the executed pipelines along with commit message as the title for each pipeline.

<p align="center">
  <img src="../images/pipelines-lvl3.png" style="width:60%">
</p>


Navigate through the different stages to review the logs and the artifacts that have been saved during the pipeline.

<p align="center">
  <img src="../images/pipelines-lvl3.gif" style="width:80%">
</p>


## Demo on your local environment

### Prerequisites
- Terraform must be installed on your local machine that you will be running the demo. The demo has been tested with Terraform v1.8.1
- BIGIP running version v15 (or higher)
- Installed AS3 version on BIGIP should be 3.50 (or higher)
- GitLab account

> [!NOTE]
> The instructions provided for this demo will work on macOS and Linux users. However, for Windows users, keep in mind that modifications might be needed before running the code. 

### Step 1. Create a repository on GitLab.com

Create a new repository on GitLab and clone it to your local machine.
```
git clone https://gitlab.com/<account>/<repo-name>
```

Clone this repository, so that we can copy the required files to your **new** repo on GitLab.
```
git clone https://github.com/f5devcentral/bigip-automation
cp -R bigip-automation/level-1/modules/*  <repo-name>/
cp bigip-automation/level-1/providers.tf <repo-name>/
```

Commit and push the changes back to GitLab.

```
cd <repo-name>
git add .
git commit -m "Initial files"
git push origin
```

> [!Note]
> You should be asked for username and password when you push the repository. 


### Step 2. Create a GitLab Runner
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

### Step 3. Register your GitLab Runner





Create a file called `.gitlab-ci.yml` in git's root directory that will contain the pipeline you want to run. 

```cmd
cat <<EOF > app2.tf
module "app2" {
    source              = "./modules/as3_http"
    name                = "app2"
    virtualIP           = "10.1.10.42"
    serverAddresses     = ["10.1.20.21"]
    servicePort         = 30880
    partition           = "prod"
    providers = {
      bigip = bigip.dmz
    }    
}
EOF
```

stages:
  - build
  - test

job_build:
  stage: build
  script:
    - echo "Building the project"

job_test:
  stage: test
  script:
    - echo "Running tests"