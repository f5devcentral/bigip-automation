# Overview

This guide provides a step-by-step overview of how to interact with NetOrca as a Customer in declarative/GitOps mode.<br>
This setup requires property setup GitLab repository with CICD pipeline and NetOrca configuration.<br>
The GitOps approach allows for a more transparent and collaborative process. It also allows further protections and auditng when this is used in highly secure or regulated enterprise environments. 

Benefits of using GitOps mode:
- Merge Request process allows team to review changes before they are submitted
- All changes are versioned and visible in the GitLab repository
- Changes are easily auditable and trackable
- Repository serves as a single source of truth for all changes of a Team

Repository used in this example:
https://gitlab.com/netorca_public/bigip-automation/level-6/customer-a 


## Declarative / GitOps workflow

The customer (NetOrca Consumer) workflow is as follows:
- Create a declaration for the Service in their Git Repo
- Create a merge request, the CI/CD process will show any validation errors that require correction
- Merge that to main, the CI/CD process will push it to NetOrca
- On NetOrca view the change instances, when they are marked complete the config has been deployed to the infrastructure

![level-6-consumer](../../images/level6_consumer.gif)

### LOAD_BALANCER yaml format

```yaml
---
# Filename app01.yml

application1:
  services:
    LOAD_BALANCER:
      - name: load_balancer1
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




## Demo Walkthrough

### Step 1. Go to NetOrca Service Catalog, find a Service you want to request and get the example YAML definition.

> Service Catalogue is the place where you can find details for all the Services offered via NetOrca.
> There are 3 tabs in the Service Catalogue:
> - **README** - information about the Service provided by the Service Owner
> - **Schema** - detailed JsonSchema definition of the Service - you can look up the details for each property
> - **Example** - generator of yaml/json code for the Service

![step-1](../../images/level6_demo_customer_step1.gif)

### Step 2. Create service definition either by copying README example or using Submission Builder.

#### Step 2.1 Using README example

![step-2-1](../../images/level6_demo_customer_step2_1.gif)

#### Step 2.2 Using Submission Builder

![step-2-2](../../images/level6_demo_customer_step2_2.gif)


### Step 3; request it via your Customer A GitLab repository.

> - In this step you will create a new branch, modify the example, create a merge request and watch the pipeline to pass.
> - Your requests will be sent to NetOrca and validated against Service definition.


#### Step 3.1 Validation successful

> - Once the pipeline is green, this indicates that the request is valid and can be merged to main branch.

![step-2](../../images/level6_demo_customer_step3_1.gif)

#### Step 3.2. Validation failed

> - In case of validation failure, you will see the error message in the pipeline logs. This log will show you one or many validation errors that have occurred along with a description of the error. 
> - You will need to fix the request and update the merge request.

![step-2-1](../../images/level6_demo_customer_step3_2.gif)

### Step 4. Merge MR (Merge Request) into the main branch and watch the CI/CD pipeline to run.

> - After MR is merged, the Submission job will be triggered and changes will be pushed to NetOrca.
> - NetOrca will determine the type of change (CREATE/DELETE/MODIFY) for each Service Item and create a corresponding Change Instance. If a Service Item's yaml is unchanged NetOrca will not create any Change Instances (it is declarative)

#### Step 4.1. CREATE Change Instance
![step-3](../../images/level6_demo_customer_step4_1.gif)

#### Step 4.2. MODIFY Change Instance
![step-3-2](../../images/level6_demo_customer_step4_2.gif)

#### Step 4.3. DELETE Change Instance
![step-3-3](../../images/level6_demo_customer_step4_3.gif)

### Step 5. Check status of your requests live in NetOrca GUI.

> - At this stage, the responsibility for processing the customer request shifts to the Service Owner.
> - By default, the Change Instance will be in a PENDING state, awaiting approval from the Service Owner.
> - The APPROVED status indicates that the Service Owner has validated and approved the request.
> - The REJECTED status means that the Service Owner has rejected the request due to an issue.
> - The COMPLETED status indicates that the request has been successfully deployed on the BIG-IP system.

![step-4](../../images/level6_demo_customer_step5.gif)


### Step 6. Repeat to maintain you Service Item throughout it's lifecycle

This process supports modification and deletion by default. 

To perform a MODIFICATION: 
- Change the required field of any Service  Items yaml declaration. 
- Merge Request, check validation, then merge to main. 
- This will resubmit to NetOrca, which will determine the changes and create a MODIFY Change Instance for processing.

To perform a DELETE:
- Delete the particular Service Items yaml from the application file in your repository. 
- Merge request, check validation then merge to main. 
- This will submit to NetOrca which will create a DELETE Change Instance for that Service Item.
- This will be processed and the Service Item will go into the DECOMISSIONED state once that is completed. 
