# Level-4  Including branches and Merge Requests on the Automation Framework

In all previous scenarios (levels) there was priomarily a single user that was using the automation framework to deploy services on BIGIP platforms. In `Level-4` we are going to show how can a team of BIGIP Admins/Users can create an automation platform that they can collaborate effectively. To achieve that we are introducing **Branches** and **Merge Requests** to the automation framework. 
 - **Git Branches**. 
 - **Merge Requests**. 


![git-f5](images/git-f5.png)


# Table of Contexts

- [Use-case details](#code-explanation)
- [Demo](#Demo)


## Use-case details
The workflow for this use-case is as follows:
- The Terraform code is stored on a Git platform (GitLab on-prem or cloud).
- User clones the repo to their local machine that have Terraform installed.
- User will make changes on the Terraform files 
- User doesn't have access to the `main` branch so they will commit their changes to another branch in Git.
- User will create a merge request from the `working branch` to `main`.
- Git will trigger a pipeline that will run `terraform plan` that will allow the Admin to easily review the planned changes.
- User with Admin rights on the repository will `Approve` the `merge request` so that the changes are pushed into the main branch
- Git will trigger the pipeline that will run the Terraform commands and deploy the changes
 

Benefits: 
  - Users can make changes without impacting the main branch.
  - Multiple team members can work together without their changes conflicting with each other.
  - Code Review takes place during the merge review, where the Admin user can review not only the code changes but also the `terraform plan` changes.


## Demo on UDF

#### Prerequisites
- Deploy the **Oltra** Deployment on UDf
- Use the terminal on **VS Code** to run the commands. **VS Code** is under the `bigip-01` on the `Access` drop-down menu.

### Step 1. Clone Terraform repository

Go to VS Code command line and clone `tf-level-4` from the internally hosted GitLab. 

```cmd
git clone https://udf:Ingresslab123@git.f5k8s.net/bigip/tf-level-4.git
```
> [!NOTE]
> This time we are cloning the repo with a different user credentials

### Step 2. Go to Terrafrom directory and create a branch

Change the working directory to `tf-level-2`. As the user `UDF` doesnt have privilleges to write to the main branch, the work done will have to be committed to a `branch`. The following command will create a new branch called `demo` if it doesn't already exists.

```cmd
cd tf-level-4
git fetch origin && (git checkout demo || git checkout -b demo)

```

### Step 3. Create a new configuration
Create the configuration to publish a new application and save the file as `app4.tf`.

```cmd
cat <<EOF > app4.tf
module "app4" {
    source              = "./modules/as3_http"
    name                = "app4"
    virtualIP           = "10.1.10.41"
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
git push origin demo
```


### Step 5. Login to Git to review the Merge Request.

Open the Gitlab webp  **VS Code** is under the `bigip-01` on the `Access` drop-down menu.


