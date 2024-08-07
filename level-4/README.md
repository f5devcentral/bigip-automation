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
- [Demo](#demo)


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

The only difference between this pipeline and the one in `Level-3` is that this pipeline run 1 of the 2 stages during the Merge Request (MR). This stage is `plan`, so that the reviewer can easier see what will the changes be before accepting the MR. 

You can find the entire pipeline <a href="https://raw.githubusercontent.com/f5devcentral/bigip-automation/main/files/.gitlab-ci-lvl4.yml"> here </a>

## Demo
> [!IMPORTANT]
> To run this Demo on the UDF environment, switch to the `UDF` branch

### Prerequisites
- BIGIP running version v15 (or higher)
- Installed AS3 (v3.50 or higher) on BIGIP 
- GitLab.com account
- Docker that will run GitLab-Runner

> [!NOTE]
> The instructions provided for this demo will work on macOS and Linux users. However, for Windows users, keep in mind that modifications might be needed before running the code. 

### Step 1. Create a repository on GitLab.com

Create a new repository on GitLab and clone it to your local machine.
```
git clone https://gitlab.com/<account>/level-4
cd level-4
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
1. Include the following scopes (api, read_api, read_repository, write_repository, read_registry, write_registry).
1. Select create personal access token.


<p align="center">
  <img src="../images/personal-access-token.png" style="width:75%">
</p>

> [!IMPORTANT]
> Copy your new personal access token and make sure you save it - you won't be able to access it again.


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


Click the button the `New project runner` that can be be found under `Setttings`->`CI/CD`->`Runners`.

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


### Step 5. Create the pipeline

Copy the `.gitlab-ci.yml` from the **bigip-automation** repository file to the root directory of your repository.

```cmd
curl -s https://raw.githubusercontent.com/f5devcentral/bigip-automation/main/files/.gitlab-ci-lvl4.yml -o .gitlab-ci.yml
```
Edit the `.gitlab-ci.yml` and change the **GIT_USERNAME** to your GitLab username and **GITLAB_ACCESS_TOKEN** to your personal access token


Commit and push the changes back to GitLab. We are adding the word "ignore" on the commit message to avoid triggering the pipeline 
```
git add .
git commit -m "Creating Pipeline - ignore -"
git push origin
```

### Step 6. Create a branch

We will apply the new configuration to a branch instead of commiting the changes directly to `main`. The following command will create a new branch called `app50` if it doesn't already exists and switch to the new branch.

```cmd
git fetch origin && (git checkout app50 || git checkout -b app50)
```

### Step 7. Create new configuration
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

### Step 8. Login to Git to review the Merge Request.

Log on to **GitLab.com** and go to the repository you have created.

<p align="center">
  <img src="../images/repo-lvl4-gitlab.png" style="width:75%">
</p>

Go to the Merge Requests page to review the suggested changes. Once you review the changes and the pipeline results, approve the MR and click `merge`

<p align="center">
  <img src="../images/merge-gitlab.gif" style="width:75%">
</p>

Check that the changes **`app50.tf`** are now pushed to the main repository and branch **app50** has been removed.  
<p align="center">
  <img src="../images/repo-lvl4-gitlab-2.png" style="width:75%">
</p>


### Step 9. Review the pipeline output.
Go to `Pipelines` and review the execution of the pipeline that run on `main` branch. You should be able to see all the executed pipelines along with commit message as the title for each pipeline. 

Select the pipeline that with the title **Merge branch 'app50' into main**.

<p align="center">
  <img src="../images/pipelines-lvl4-gitlab.gif" style="width:75%">
</p>

Click on each stage to see the logs but also the artifacts that the pipeline is creating.


> [!NOTE]
> Notice that the pipeline that runs on Merge Request is different than the pipeline that runs on the `main` branch.

