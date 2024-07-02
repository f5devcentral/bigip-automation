# Enhancing Team Collaboration with Branches and Merge Requests

In all previous scenarios (levels) there was primarily a single user that was using the automation framework to deploy services on BIGIP platforms. In `Level-4` we are going to show how can a team of BIGIP Admins/Users can create a platform that they can collaborate effectively and automate the deployment of services. To achieve that we are introducing **Branches** and **Merge Requests** to the automation framework. 
  1. **Git Branches**. 
      - Branches allow multiple users to work on different task or changes simultaneously without interfering with the main code.
      - Each team member can create a separate branch from the main branch for their specific tasks, ensuring that changes do not affect the production environment.
      - For example, a user might create a branch named `app50.tf` to work on a new load balancing configuration.
  2. **Merge Requests**. 
      - Merge Requests (MRs) facilitate code review and integration, ensuring that changes are systematically reviewed and tested before being merged into the main branch.
      - Once a user completes their changes in a branch, they open a Merge Request to merge their branch into the main branch. Other team members can review the MR, provide feedback, and approve the changes.
      - The CI/CD pipeline can run automatically when a Merge Request is created, ensuring that all tests pass and the changes do not introduce any errors before merging.

![level-4](../images/level-4.png)


# Table of Contexts

- [Use case workflow](#use-case-workflow)
- [Code Explanation](#code-explanation)
  - [Pipeline](#pipeline)
- [Demo with UDF](#demo-with-udf)


## Use case workflow
The workflow for this use-case is as follows:
  1. The Terraform code is stored on a Git platform (GitLab on-prem or cloud).
  1. Users clone the repository to their local machines. (Terraform is NOT required) 
  1. Users doesn't have access to the `main` branch so they create a new branch from the main branch for their task.
  1. Users make changes in the branch and commits them.
  1. Upon completion, the team member opens a `Merge Request` to merge their branch into the `main` branch.
  1. The CI/CD pipeline automatically runs tests and validations on the Merge Request.
  1. Other team members (*Admins*) review the Merge Request, provide feedback, and approve the changes.
  1. Once approved, the changes are merged into the main branch, and the pipeline deploys the updates.

**Benefits:**
  - **Collaboration**: Branches and Merge Requests enable multiple users to work collaboratively on different parts of the project without conflicts.
  - **Code Quality**: Merge Requests facilitate peer reviews, improving code quality through feedback and collaboration.
  - **Automated Testing**: The CI/CD pipeline automatically tests changes in Merge Requests, reducing the likelihood of errors in the main branch.
  - **Controlled Deployment**: Changes are only merged into the main branch after passing reviews and tests, ensuring a stable and reliable codebase.


## Code Explanation
In the following section, we  provide a deeper explanation of the **pipeline** configuration.


### *Pipeline*

The only difference between this pipeline and the one in `Level-3` is that this pipeline run 1 of the 3 stages during the Merge Request (MR). This stage is `plan`, so that the reviewer can easier see what will the changes be before accepting the MR. 

You can find the entire pipeline <a href="https://raw.githubusercontent.com/f5devcentral/bigip-automation/main/level-4/.gitlab-ci.yml"> here </a>


## Demo with UDF

#### Prerequisites
- Deploy the **Oltra** UDF Deployment
- Use the terminal on **VS Code** to run the commands. **VS Code** is under the `bigip-01` on the `Access` drop-down menu.  Click <a href="https://raw.githubusercontent.com/f5devcentral/bigip-automation/main/images/vscode.png"> here </a> to see how.*

### Step 1. Clone Terraform repository

Go to VS Code command line and clone `tf-level-4` from the internally hosted GitLab. 

```cmd
git clone https://udf:Ingresslab123@git.f5k8s.net/bigip/tf-level-4.git
```

> [!NOTE]
> This time we are cloning the repo with a different user credentials, so that this user doesn't have access to the `main` branch

### Step 2. Go to Terrafrom directory and create a branch

Change the working directory to `tf-level-4`. As the user `UDF` doesn't have privilleges to write to the main branch, the work done will have to be committed to a `branch`. The following command will create a new branch called `app50` if it doesn't already exists and switch to the new branch.

```cmd
cd tf-level-4
git fetch origin && (git checkout app50 || git checkout -b app50)
```

### Step 3. Create a new configuration
Create the configuration to publish a new application and save the file as `app50.tf`.

```cmd
cat <<EOF > app50.tf
module "app50" {
    source              = "./modules/as3_http"
    name                = "app50"
    virtualIP           = "10.1.10.45"
    serverAddresses     = ["10.1.20.21"]
    servicePort         = 30880
    partition           = "prod"
    providers = {
      bigip = bigip.dmz
    }    
}
EOF
```

### Step 4. Commit Changes to Git and create Merge Request

Add you details on Git so that any changes you make will include your name. This will make it easier in the future to identify who made the change.

```cmd
git config user.name "John Doe"
git config user.email "j.doe@f5.com"
```

Run the following commands that will push the changes made on the configuration files back to the origin Git repository and create a merge request.

```cmd
git add .
git commit -m "Adding application app50"
git push -u origin HEAD \
  -o merge_request.create \
  -o merge_request.title="New Merge Request $(git branch --show-current)" \
  -o merge_request.description="This MR was create to deploy app50" \
  -o merge_request.target=main \
  -o merge_request.remove_source_branch \
  -o merge_request.squash
```

### Step 5. Login to Git to review the Merge Request.

Access the web interface **GitLab** that is under the `bigip-01` on the `Access` drop-down menu. Click <a href="https://raw.githubusercontent.com/f5devcentral/bigip-automation/main/images/gitlab.png"> here </a> to see how.

Log on to GitLab using the root credentials (**root**/**Ingresslab123**) and select the repository `bigip / tf_level_4`. 

<p align="center">
  <img src="../images/repo-lvl4.png" style="width:75%">
</p>

Go to the Merge Requests page to review the suggested changes. Once you review the changes and the pipeline results, approve the MR and click `merge`

<p align="center">
  <img src="../images/merge-lvl4.gif" style="width:75%">
</p>

Check that the changes **`app50.tf`** are now pushed to the main repository and branch **app50** has been removed.  
<p align="center">
  <img src="../images/repo-lvl4-1.png" style="width:75%">
</p>


### Step 6. Review the pipeline output.
Go to `Pipelines` and review the execution of the pipeline that run on `main` branch. You should be able to see all the executed pipelines along with commit message as the title for each pipeline. 

Select the pipeline that with the title **Merge branch 'app50' into main**.

<p align="center">
  <img src="../images/pipelines-lvl4.gif" style="width:75%">
</p>

Click on each stage to see the logs but also the artifacts that the pipeline is creating.


> [!NOTE]
> Notice that the pipeline that runs on Merge Request is different than the pipeline that runs on the `main` branch.





## Demo on your local environment

### Prerequisites
- Terraform must be installed on your local machine that you will be running the demo. The demo has been tested with Terraform v1.8.1
- BIGIP running version v15 (or higher)
- Installed AS3 version on BIGIP should be 3.50 (or higher)
- GitLab account
- Docker that would host GitLab-Runner

> [!NOTE]
> The instructions provided for this demo will work on macOS and Linux users. However, for Windows users, keep in mind that modifications might be needed before running the code. 

### Step 1. Create a repository on GitLab.com

Create a new repository on GitLab and clone it to your local machine.
```
git clone https://gitlab.com/<account>/<repo-name>
cd <repo-name>
```

Use this repository to copy the module files to your **new** repo on GitLab.
```
mkdir modules
mkdir modules/as3_http
curl -s https://raw.githubusercontent.com/f5devcentral/bigip-automation/main/files/modules/as3_http/as3.tpl -o modules/as3_http/as3.tpl
curl -s https://raw.githubusercontent.com/f5devcentral/bigip-automation/main/files/modules/as3_http/main.tf -o modules/as3_http/main.tf
curl -s https://raw.githubusercontent.com/f5devcentral/bigip-automation/main/files/modules/as3_http/variables.tf -o modules/as3_http/variables.tf
curl -s https://raw.githubusercontent.com/f5devcentral/bigip-automation/main/files/.gitignore -o .gitignore
curl -s https://raw.githubusercontent.com/f5devcentral/bigip-automation/main/files/providers-lvl3-4.tf -o providers.tf
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

### Step 2. Create a personal access token
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
1. Select the desired scopes.
1. Select create personal access token.

Copy your new personal access token and make sure you save it - you won't be able to access it again.


### Step 3. Create a GitLab Runner
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

### Step 4. Register your GitLab Runner

Log on to **GitLab.com** and go to the repository you have created.
Go to `Setttings`->`CI/CD`->`Runners` and under project runners copy the `registration token` as shown on the picture below.

<p align="center">
  <img src="../images/token-lvl3.png" style="width:75%">
</p>

> [!IMPORTANT]
> Before registering the runner, disable **Instance runners** so that you don't use GitLab-hosted runners.

Use the following docker exec command to start the registration process:
```
docker exec -it gitlab-runner gitlab-runner register
```
You will be asked to fill in the following:

- Enter the GitLab instance URL (for example, https://gitlab.com/):
- Enter the registration token:
- Enter a description for the runner:
- Enter tags for the runner (comma-separated): *** Leave Blank ***
- Enter optional maintenance note for the runner:
- Enter an executor: custom, shell, ssh, parallels, docker-windows, docker-autoscaler, virtualbox, docker, docker+machine, kubernetes, instance: *** Select docker ***
- Enter the default Docker image (for example, ruby:2.7):

### Step 5. Create the pipeline

Copy the `.gitlab-ci.yml` from the **bigip-automation** repository file to the root directory of your repository.

```cmd
curl -s https://raw.githubusercontent.com/f5devcentral/bigip-automation/main/level-4/.gitlab-ci.yml -o .gitlab-ci.yml
```
Edit the `.gitlab-ci.yml` and change the GIT_USERNAME to your GitLab username and GIT_PASSWORD to your personal access token


Commit and push the changes back to GitLab. We are adding the word "ignore" on the commit message to avoid triggering the pipeline 
```
git add .
git commit -m "Creating Pipeline - ignore -"
git push origin
```

### Step 6. Create a new configuration
Create the configuration to publish a new application and save the file as `app3.tf`.

```cmd
cat <<EOF > app50.tf
module "app50" {
    source              = "./modules/as3_http"
    name                = "app50"
    virtualIP           = "10.1.10.45"
    serverAddresses     = ["10.1.20.21"]
    servicePort         = 30880
    partition           = "prod"
    providers = {
      bigip = bigip.dmz
    }    
}
EOF
```

Run the following commands that will push the changes made on the configuration files back to the origin Git repository and create a merge request.

```cmd
git add .
git commit -m "Adding application app50"
git push -u origin HEAD \
  -o merge_request.create \
  -o merge_request.title="New Merge Request $(git branch --show-current)" \
  -o merge_request.description="This MR was create to deploy app50" \
  -o merge_request.target=main \
  -o merge_request.remove_source_branch \
  -o merge_request.squash
```

### Step 5. Login to Git to review the Merge Request.

Log on to **GitLab.com** and go to the repository you have created.
<p align="center">
  <img src="../images/repo-lvl4.png" style="width:75%">
</p>

Go to the Merge Requests page to review the suggested changes. Once you review the changes and the pipeline results, approve the MR and click `merge`

<p align="center">
  <img src="../images/merge-lvl4.gif" style="width:75%">
</p>

Check that the changes **`app50.tf`** are now pushed to the main repository and branch **app50** has been removed.  
<p align="center">
  <img src="../images/repo-lvl4-1.png" style="width:75%">
</p>


