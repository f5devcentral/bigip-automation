# Level-3  Introducing Pipelines and Remote tfState to the Automation Framework

In our `Level-2` automation use-case, we move our Terraform code to Git that allow us to have a reliable version control system, but the user continued to execute the Terraform commands from their own machine. 
In `Level-3` we are introducing 2 new elements to the automation framework. 
 - **Remote Terraform state**. By default, Terraform stores state locally in a file named terraform.tfstate. When working with Terraform in a team, use of a local file makes Terraform usage complicated because each user must make sure they always have the latest state data before running Terraform and make sure that nobody else runs Terraform at the same time. With remote state, Terraform writes the state data to a remote data store, which can then be shared between all members of a team. Terraform supports storing state in HCP Terraform, HashiCorp Consul, GitLab, Amazon S3, Azure Blob Storage, Google Cloud Storage, Alibaba Cloud OSS, and more. We will be using GitLab as the remote data store for tfstate.
 - **Pipelines**. Instead of executing the Terraform at each user's machine, we can have a pipeline assigned to the GitLab repository that will execute every time there is a commit to the repository, therefore centralizing the deployment process. This pipeline can execute the Terraform commands along with any other script/command.


![git-f5](images/git-f5.png)


# Table of Contexts

- [Use-case details](#code-explanation)
- [Demo](#Demo)
- [Features Explanation](#Demo)


## Use-case details
The workflow for this use-case is as follows:
- The Terraform code is stored on a Git platform (GitLab on-prem or cloud).
- User clones the repo to their local machine that have Terraform installed.
- User will make changes on the Terraform files and commit the changes back to Git
- Git will trigger the pipeline that will run the Terraform commands

Benefits: 
  - Terraform runs from a centralized location to install it locally
  - History of all Terraform logs/outputs is kept alognside with the Git commits


## Demo on UDF

#### Prerequisites
- Deploy the **Oltra** Deployment on UDf

### Step 1. Clone Terraform repository

Use the terminal on **VS Code** to run the commands. **VS Code** can be accessed under the `bigip-01` on the `Access` drop-down menu.

Go to VS Code command line and clone `tf-level-3` from the internally hosted GitLab.

```
git clone https://git.f5k8s.net/bigip/tf-level-3.git
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
    virtualIP           = "10.1.10.40"
    serverAddresses     = ["10.1.20.10", "10.1.20.11"]
    servicePort         = 80
    partition           = "uat1"
    providers = {
      bigip = bigip.dmz
    }    
}
EOF
```

### Step 4. Commit Changes to Git repository

Add you details on Git so that any changes you make will include your name. This will make it easier in the future to identify who made the change.

```cmd
git config user.name "FirstName LastName"
git config user.email "abc@example.com"
```

Run the following commands that will push the changes made on the configuration files back to the origin Git repository

```cmd
git add .
git commit -m "Adding application app2"
git push
```

### Step 5. Login to Git to review the pipeline output.

Open the Gitlab webp  **VS Code** is under the `bigip-01` on the `Access` drop-down menu.

Go to repository tf-level-2.
Open file app1.tf


Select Blame to see changes.
GIF

Select History to see the evolution of the policy.

GIF

