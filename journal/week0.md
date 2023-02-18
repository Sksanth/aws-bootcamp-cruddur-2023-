# Week 0 — Billing and Architecture

## Required Homework

### Cruddur Logical Diagram in Lucid Charts

Recreated the logical diagram by following the instructions in the [video](https://www.youtube.com/watch?v=K6FDrI_tz0k&t=1780s). **For the gomomento serverless cache image - googled the gomomento logo, downloaded it on my machine and used it in my diagram.**

[My Logical Diagram link](https://lucid.app/lucidchart/7eb71554-fde8-40a9-a96b-2ff9aec21956/edit?viewport_loc=-362%2C-47%2C2560%2C1216%2C0_0&invitationId=inv_9c127fbf-69f0-49d9-a520-71c000120b5b)
![Cruddur Logical Diagram](https://user-images.githubusercontent.com/102387885/219828531-48829150-d31f-43dc-b9d0-3a8e6f770847.jpg)

### Napkin Design

![NapkinDesign](https://user-images.githubusercontent.com/102387885/219828646-e92271fc-32c1-4997-a501-8b405d773402.jpg)

### Generating AWS Credentials

Created Admin User 

![iam user](https://user-images.githubusercontent.com/102387885/219828904-57eccdbb-6330-4bb7-aff5-7b60feea3cc1.jpg)

### CloudShell
Used a browser based shell - CloudShell to securely interact with AWS resources

![cloudshell](https://user-images.githubusercontent.com/102387885/219828651-450bf3a7-672b-4b94-b1be-eb2306ab3df5.png)

### Installing AWS CLI
Followed the [AWS CLI Installation](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) document to install the AWS on the Gitpod 

```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```
Configured the AWS CLI by following the instructions in the [How to set environment varibales](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html#envvars-set) document to set the environment variables
```
export AWS_ACCESS_KEY_ID="*********"
export AWS_SECRET_ACCESS_KEY="*************"
export AWS_DEFAULT_REGION="us-east-1"
```

Copied all the env vars to gitpod with the following commands to automate the process when the Gitpod launches the workspace
```
gp env AWS_ACCESS_KEY_ID="*********"
gp env AWS_SECRET_ACCESS_KEY="************"
gp env AWS_DEFAULT_REGION="us-east-1"
```

To automate the AWS CLI installation created a [gitpod.yml](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/week0/.gitpod.yml) file on the Gitpod.
I manualy typed the yaml file and the gitpod returned the **too many command lines** error while launching the new workspace. Little research helped me to fix the problem by placing the **|** in the **init command** line to break the multiple commands.


### Billing Alarm 
Created the CloudWatch Alarm and Budget using both the console and CLI

![alarm](https://user-images.githubusercontent.com/102387885/219828660-4e4b7477-6015-42c4-b947-f45081831549.png)
Created [aws cloudwatch put-metric alarm](https://aws.amazon.com/premiumsupport/knowledge-center/cloudwatch-estimatedcharges-alarm/)
 
```
aws cloudwatch put-metric-alarm --cli-input-json file://aws/json/alarm_config.json
```

![budget](https://user-images.githubusercontent.com/102387885/219828669-1166208a-6424-4bd2-8348-2f3966bd992e.png)

Followed the [Budget](https://docs.aws.amazon.com/cli/latest/reference/budgets/create-budget.html#examples) document to **create-budget** and **contents of budget.json** and **notifications-with-subscribers.json** on Gitpod
```
aws budgets create-budget \
    --account-id ********5666 \
    --budget file://aws/json/budget.json \
    --notifications-with-subscribers file://aws/json/budget-notifications-with-subscribers.json
```

Created [SNS Topic](https://docs.aws.amazon.com/cli/latest/reference/sns/subscribe.html) using CLI  

```
aws sns create-topic --name billing-alarm

aws sns subscribe \
    --topic-arn arn:aws:sns:us-east-1:********5666:billing-alarm \
    --protocol email \
    --notification-endpoint sas*****@gmail.com
 ```   
 ![snstopics](https://user-images.githubusercontent.com/102387885/219832868-e94fea0c-9649-4385-bb94-43a807aefe0a.png)



### Files in the codebase

[alarm_config.json](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/week0/aws/json/alarm_config.json)
[budget-notifications-with-subscribers.json](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/week0/aws/json/budget-notifications-with-subscribers.json)
[budget.json](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/week0/aws/json/budget.json)

Crteated a Cost allocation tag

![costallocationtag](https://user-images.githubusercontent.com/102387885/219830757-12e10647-aab6-4466-8a1b-f11d9f3c1f0c.png)


## Homework Challenges

### Destroyed root account credentials, set MFA and IAM role

Added MFA to the root user account and created an IAM role - tester
![mfa](https://user-images.githubusercontent.com/102387885/219828677-71e60217-e14c-42a5-9bc5-b718cb41c152.jpg)

![tester_role](https://user-images.githubusercontent.com/102387885/219828891-fcc1aef6-bc03-4e2b-813a-82e929f8912a.png)

### EventBridge
Used Amazon EventBridge to monitor status changes and receive health events. And set the rule to send the events to the SNS topic

![EventBridgeRule](https://user-images.githubusercontent.com/102387885/219828687-979e9fb1-5545-45ba-a53e-734e0b624a5a.jpg)

### Support Ticket

Requested to increase the running on-demand EC2 service by opening a ticket. The requested service quota was 10 but the applied quota value is 32.
![serviceQuotaRequest](https://user-images.githubusercontent.com/102387885/219828701-94f31456-4281-42b9-ad24-edabc664d8c2.jpg)

![increasedquota](https://user-images.githubusercontent.com/102387885/219828707-1a8b4e1f-4bb6-4810-9563-67212d0a4428.png)



