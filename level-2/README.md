# Level-2  Adding Version Control to the Automation Framework

Storing configuration as code in Git provides numerous benefits, making it an essential tool for automation use-cases. Git's version control capabilities allow automation owners to track every change made to the codebase, making it easy to identify who made specific changes, when they were made, and why. This detailed history simplifies the process of reverting to previous versions if a problem arises, ensuring that no work is lost and that errors can be quickly corrected. Additionally, Git's commit logs provide a comprehensive audit trail, documenting the entire evolution of the automation project. This audit trail is crucial for debugging, understanding the evolution process, and maintaining accountability within the team. By using Git, we can ensure that the code is well-documented and easily navigable, which enhances overall project transparency and efficiency.


In our `Level-2` automation use-case, integrating Git will allow us to have a reliable version control system and a comprehensive audit trail, enabling us to track every change made to our codebase, quickly revert to previous versions when needed, and maintain clear documentation of our project's evolution.

![git-f5](images/git-f5.png)


# Table of Contexts

- [Use-case details](#use-case-details)
- [Demo with UDF](#demo-with-udf)
- [Demo with GitLab](#demo-with-gitlab)


## Use-case details
The workflow for this use-case is as follows:
- The Terraform code is stored on a Git platform (GitLab on-prem or cloud).
- User clones the repo to their local machine that have Terraform installed.
- User creates or makes changes on the Terraform files and commits them back to Git with the appropriate commit message.
- User executes localy **terraform plan** and **terraform apply** as described on `Level-1` use-case. 


Benefits: 
  - All benefits of `Level-1`
  - Track all changes made to the code
  - Easily revert back to previous versions
  - Document changes

> [!IMPORTANT]
> This use-case doesn't support mutliple people/teams working on the same project as that would require to have the Terraform state in a shared locations with the ability to be locked while teams are implementing changes. This requirement is cover by our `Level-4` use-case.


## Demo on UDF

#### Prerequisites
- Deploy the **Oltra** Deployment on UDf

### Step 1. Clone Terraform repository

Use the terminal on **VS Code** to run the commands. **VS Code** can be accessed under the `bigip-01` on the `Access` drop-down menu.

Go to VS Code command line and clone `tf-level-2` from the internally hosted GitLab.
```
git clone https://git.f5k8s.net/bigip/tf-level-2.git
```
Take some time to review all the TF files in the repo. Check the `.gitignore` file that tells Git which files (or patterns) it should ignore when committing your work back to the origin repository. You will notice that the `tfstate` files are ignored. There are a few reasons why not to store your .tfstate files in Git:

- You are likely to forget to commit and push your changes after running terraform apply, so your teammates will have out-of-date .tfstate files. 
- Without locking on the state files, if two team members run Terraform at the same time on the same .tfstate files, you may overwrite each other's changes. 

> [!NOTE]
> You can solve both problems by using `remote state`, which will push/pull/lock the .tfstate files automatically every time you run terraform apply and will store the state to a remote location like (S3 bucket, Azure blob, GitLab managed terraform state and many more (more info on https://developer.hashicorp.com/terraform/language/settings/backends/configuration).


### Step 2. Go to Terrafrom directory

Change the working directory to `tf-level-2`
```
cd tf-level-2
```

### Step 3. Run Terraform commands
Similar to `Level-1` use-case we will run all the necessary terraform commands to deploy our 

```cmd
terraform init
terraform plan -parallelism=1 -refresh=false -out=tfplan
terraform apply -parallelism=1 tfplan
```

### Step 6. Commit Changes to Git repository
Add you details on Git so that any changes you make will include your name. This will make it easier in the future to identify who made the change.

```cmd
git config user.name "FirstName LastName"
git config user.email "abc@example.com"
```

Run the following commands that will push the changes made on the configuration files back to the origin Git repository

```cmd
git add .
git commit -m "Adding application web01"
git push
```

>[!IMPORTANT]
> You will be asked to input the username/password for GitLab. The credentials are : **admin / Ingresslab123**


### Step 6. Change the configuration

Edit the `app5.tf` file and change the IP Address configured for this service. 
Re-run **terrafrom** commands to plan and apply the changes.

```cmd
terraform plan -parallelism=1 -refresh=false -out=tfplan
terraform apply -parallelism=1 tfplan
```


### Step 7. Login to Git to review the changes.

Open the Gitlab webp  **VS Code** is under the `bigip-01` on the `Access` drop-down menu.

Go to repository tf-level-2.
Open file app1.tf


Select Blame to see changes.
GIF

Select History to see the evolution of the policy.

GIF

