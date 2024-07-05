# Utilizing Git for Robust Version Control

Storing configuration as code in Git provides numerous benefits, making it an essential tool for automation use-cases. Git's version control capabilities allow automation owners to track every change made to the codebase, making it easy to identify who made specific changes, when they were made, and why. This detailed history simplifies the process of reverting to previous versions if a problem arises, ensuring that no work is lost and that errors can be quickly corrected. Additionally, Git's commit logs provide a comprehensive audit trail, documenting the entire evolution of the automation project. This audit trail is crucial for debugging, understanding the evolution process, and maintaining accountability within the team. By using Git, we can ensure that the code is well-documented and easily navigable, which enhances overall project transparency and efficiency.

In our `Level-2` automation use-case, integrating Git will allow us to have a reliable version control system and a comprehensive audit trail, enabling us to track every change made to our codebase, quickly revert to previous versions when needed, and maintain clear documentation of our project's evolution.

![level-2](../images/level-2.png)


# Table of Contexts
- [Use case workflow](#use-case-workflow)
- [Demo with UDF](#demo-with-udf)
- [Demo on your local environment](#demo-on-your-local-environment)  


## Use case workflow
The workflow for this use-case is as follows:
  - The Terraform code is stored on a Git platform (either GitLab on-premises or cloud).
  - Users clone the repository to their local machines, which have Terraform installed.
  - Users create or make changes to the Terraform files 
  - Users can execute **terraform plan** and **terraform apply** locally as described in the Level-1 use case to preview and apply changes before committing them to Git.
  - Users commit the changes back to the Git repository with appropriate commit messages.

Benefits: 
  - All benefits of `Level-1` use case
  - **Track Changes**: Track all changes made to the code, providing a clear history of modifications.
  - **Version Control**: Easily revert back to previous versions of the code if necessary.
  - **Documentation**: Document changes through commit messages, ensuring transparency and ease of understanding.


> [!IMPORTANT]
> This use-case doesn't support mutliple people/teams working on the same project as that would require to have the Terraform state in a shared locations with the ability to be locked while teams are implementing changes. This requirement is cover by our `Level-4` use-case.


## Demo with UDF

### Prerequisites
- Deploy the **Oltra** UDF Deployment. Once provisioned, use the terminal on **VS Code** to run the commands in this demo. You can find **VS Code** under the `bigip-01` on the `Access` drop-down menu.  Click <a href="https://raw.githubusercontent.com/f5devcentral/bigip-automation/main/images/vscode.png"> here </a> to see how.


### Step 1. Clone Terraform repository

Provision **Oltra** UDF Deployment and open the `VS Code` terminal.

Clone `tf-level-2` from the internally hosted GitLab.
```
git clone https://root:Ingresslab123@git.f5k8s.net/automation/tf-level-2.git
```

>[!NOTE]
> We are including the username/password for Git during the cloning process so that we don't have to input the credentials when we push the changes back to the origin server.


### Step 2. Go to Terrafrom directory

Change the working directory to `tf-level-2`
```
cd tf-level-2
```

Take some time to review all the TF files in the repo. Check the `.gitignore` file that tells Git which files (or patterns) it should ignore when committing your work back to the origin repository. You will notice that among other files, files with name `terraform.tfstate` is also ignored. There are a few reasons why not to store your .`tfstate` files in Git:

- You are likely to forget to commit and push your changes after running terraform apply, so your teammates will have out-of-date .tfstate files. 
- Without locking on the state files, if two team members run Terraform at the same time on the same .tfstate files, you may overwrite each other's changes. 

> [!NOTE]
> You can solve both problems by using `remote state`, which will push/pull/lock the .tfstate files automatically every time you run terraform apply and will store the state to a remote location like (S3 bucket, Azure blob, GitLab managed terraform state and many more (more info on https://developer.hashicorp.com/terraform/language/settings/backends/configuration). We will cover this on `Level-3`


### Step 3. Create a new configuration
Create the configuration to publish the new application and save it as a file called `app2.tf`.

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

### Step 4. Run Terraform commands
Similar to `Level-1` use-case we will run all the necessary terraform commands to deploy our configuration.

```cmd
terraform init
terraform plan -parallelism=1 -refresh=false -out=tfplan
terraform apply -parallelism=1 tfplan
```

### Step 5. Commit the changes to Git
Add you details on Git so that any changes you make will include your name. This will make it easier in the future to identify who made the change.

```cmd
git config user.name "John Doe"
git config user.email "j.doe@f5.com"
```

Run the following commands that will push the changes made on the configuration files back to the origin Git repository
```cmd
git add .
git commit -m "Adding application app02"
git push
```


### Step 6. Change the configuration

Edit the `app2.tf` file and change the IP Address configured for this service (10.1.120.42 -> 10.1.120.43).
Re-run the **terrafrom** commands to plan and apply the changes.

```cmd
terraform plan -parallelism=1 -refresh=false -out=tfplan
terraform apply -parallelism=1 tfplan
```


### Step 7. Commit the changes to Git
Run the following commands that will push the changes made on the configuration files back to the origin Git repository
```cmd
git add .
git commit -m "Modifying the IP Address for app02 to 10.1.10.43"
git push
```


### Step 7. Login to Git to review the changes.

Access the web interface **GitLab** that is under the `bigip-01` on the `Access` drop-down menu. Click <a href="https://raw.githubusercontent.com/f5devcentral/bigip-automation/main/images/gitlab.png"> here </a> to see how.

Log on to GitLab using the root credentials (**root**/**Ingresslab123**) and select the repository `bigip / tf_level_2`. 

<p align="center">
  <img src="../images/repo-lvl2.png" style="width:75%">
</p>


Open `app2.tf` file and select the **Blame** button to see the history of changes for each line of a file. You should be able to see information such as: 
- **Author**: The name of the person who last modified each line.
- **Commit Message**: The commit message associated with the change to each line.
- **Date/Time**: The date/time when the change was made.

<p align="center">
  <img src="../images/blame-lvl2.png" style="width:75%">
</p>


Alternatively you can select the **History** button to see the evolution of the specific file along along with the commit information.

<p align="center">
  <img src="../images/history-lvl2.png" style="width:75%">
</p>

> [!TIP]
> Navigate through the different links/buttons/pages to familiarize yourself with the different capabilties.



## Demo on your local environment

### Prerequisites
- Terraform must be installed on your local machine that you will be running the demo. The demo has been tested with Terraform v1.8.1
- BIGIP running version v15 (or higher)
- Installed AS3 version on BIGIP should be 3.50 (or higher)
- GitLab.com account

> [!NOTE]
> The instructions provided for this demo will work on macOS and Linux users. However, for Windows users, keep in mind that modifications might be needed before running the code. 

### Step 1. Create a repository on GitLab.com

Create a new repository on GitLab and clone it to your local machine.
```
git clone https://gitlab.com/<account>/<repo-name>
cd <repo-name>
```

<p align="center">
  <img src="../images/create-project-lvl2.png" style="width:75%">
</p>


Create the necessary files to your **new** repo on GitLab.
```
mkdir modules
mkdir modules/as3_http
curl -s https://raw.githubusercontent.com/f5devcentral/bigip-automation/main/files/modules/as3_http/as3.tpl -o modules/as3_http/as3.tpl
curl -s https://raw.githubusercontent.com/f5devcentral/bigip-automation/main/files/modules/as3_http/main.tf -o modules/as3_http/main.tf
curl -s https://raw.githubusercontent.com/f5devcentral/bigip-automation/main/files/modules/as3_http/variables.tf -o modules/as3_http/variables.tf
curl -s https://raw.githubusercontent.com/f5devcentral/bigip-automation/main/files/.gitignore -o .gitignore
curl -s https://raw.githubusercontent.com/f5devcentral/bigip-automation/main/files/providers.tf -o providers.tf

```

Edit a file called `providers.tf`. Please change the values of `address`, `username` and `password` according to your environment.

Commit and push the changes back to GitLab.
```
git add .
git commit -m "Initial files"
git push origin
```

> [!Note]
> You should be asked for username and password when you push the repository back to GitLab. 


### Step 2. Create a new configuration
Create the configuration to publish a new application and save it as a file called `app2.tf`.

Please change the values of `virtualIP`, `serverAddresses` and `servicePort` according to your environment.

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

### Step 3. Run Terraform commands
Run all the necessary terraform commands to deploy our configuration.

```cmd
terraform init
terraform plan -parallelism=1 -refresh=false -out=tfplan
terraform apply -parallelism=1 tfplan
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
git commit -m "Adding application app02"
git push
```

### Step 5. Change the configuration

Edit the `app2.tf` file and change the IP Address configured for this service (10.1.10.42 -> 10.1.10.43).

Re-run the **terrafrom** commands to plan and apply the changes.

```cmd
terraform plan -parallelism=1 -refresh=false -out=tfplan
terraform apply -parallelism=1 tfplan
```


### Step 6. Commit the changes to Git
Run the following commands that will push the changes made on the configuration files back to the origin Git repository
```cmd
git add .
git commit -m "Modifying the IP Address for app02 to 10.1.10.43"
git push
```

### Step 7. Login to Git to review the changes.

Log on to **GitLab.com** and go to the repository you have created.

<p align="center">
  <img src="../images/repo-lvl2.png" style="width:75%">
</p>


Open `app2.tf` file and select the **Blame** button to see the history of changes for each line of a file. You should be able to see information such as: 
- **Author**: The name of the person who last modified each line.
- **Commit Message**: The commit message associated with the change to each line.
- **Date and Time**: The date and time when the change was made.

<p align="center">
  <img src="../images/blame-lvl2-gitlab.png" style="width:75%">
</p>


Alternatively you can select the **History** button to see the evolution of the specific file along along with the commit information.

<p align="center">
  <img src="../images/history-lvl2-gitlab.png" style="width:75%">
</p>

> [!TIP]
> Navigate through the different links/buttons/pages to familiarize yourself with the different capabilties.
