# Week 10-11 — CloudFormation Part 1 and Part 2
## Summary:
Convert ClickOps infrastructure to CloudFormation and SAM templates

### Update 
To perform detailed validation on AWS CloudFormation templates, install **cfn-lint**. <br>
In the ```gitpod.yml``` file add  
```
- name: cfn
  before: |
    pip install cfn-lint
    cargo install cfn-guard
```
```
export CFN_BUCKET="your-cfn-artifacts"
gp env CFN_BUCKET="your-cfn-artifacts"
```
## CFN for Network Layer

Inside the ```aws``` dir, create ```cfn``` then ```networking``` folder into it and create files [template.yaml](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/aws/cfn/networking/template.yaml) and [config.toml](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/aws/cfn/networking/config.toml)

Also create a folder called ```cfn``` under the ```bin``` dir and a script [networking](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/bin/cfn/networking)  

Run the commands to create a CFN stack
```
chmod bin/cfn/networking
./bin/cfn/networking
```
```
pip install cfn-lint
cfn-lint /workspace/aws-bootcamp-cruddur-2023-/aws/cfn/networking/template.yaml
cargo install cfn-guard
```
![CrdNet in progress](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/assets/102387885/5de60bf5-6f16-40bf-837b-3af6e843cc57)

![CrdNet craeted1](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/assets/102387885/ebc25f1a-890e-45e8-a43c-0820a67fc90e)

## CFN for Cluster Layer
Install **cfn-toml** <br>
```gem install cfn-toml``` and update the ``` gitpod.yml``` file

Inside the ```aws/cfn``` dir, create a new folder ```cluster``` and files [template.yaml](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/aws/cfn/cluster/template.yaml) and [config.toml](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/aws/cfn/cluster/config.toml)

Create a new script [cluster](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/bin/cfn/cluster) under ```bin/cfn``` dir

Run
```
chmod u+x bin/cfn/cluster
./bin/cfn/cluster
```
![cmds to crdNet and crdCluster](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/assets/102387885/97335f69-8df1-4bff-a68a-f53e180d23ee)

![CrdCluster-success](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/assets/102387885/af56794d-4499-4f34-b10e-bd9b87402868)

## CFN for RDS

In the ```aws/cfn/``` create a new folder ```db``` and files [template.yaml](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/aws/cfn/db/template.yaml) and [config.toml](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/aws/cfn/db/config.toml)

```
export DB_PASSWORD="password"
gp env DB_PASSWORD="password"
```

Create a new script [db](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/bin/cfn/db) under ```bin/cfn``` dir

```
chmod u+x bin/cfn/db
./bin/cfn/db
```

![CrdDb success](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/assets/102387885/6deb24c1-464c-4d8a-a194-44f0a7f7ab7e)

**NOTE:** Update AWS System manger’s parameter store ```CONNECTION_URL``` value

## CFN for Fargate Service Layer (backend)
Update the ``` bin/backend/connect``` , ``` bin/backend/deploy``` with the new cluster name ```CrdClusterFargateCluster```
Create a script [create-service](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/bin/backend/create-service) inside the ```bin/backend``` dir
```
chmod bin/backend/create-service
./bin/backend/create-service
```
Update the ```aws/json/service-backend-flask.json``` with the **cluster name**, **TG arn of the backend flask** and **public subnet ids** (copy from **CrdNet** stack) then in the console edit the **inbound rules** of ```crud-srv-sg``` and run ```./bin/backend/deploy```

Change the ```backend TG``` health check port to ```4567``` from the default value ```80```

![backend TG health check port](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/assets/102387885/4f2be152-e19c-4cff-83e2-96fc5154df31)


In the ```aws/cfn/``` create a new folder ```service``` and files [template.yaml](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/aws/cfn/service/template.yaml) and [config.toml](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/aws/cfn/service/config.toml)

Create a new script [service](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/bin/cfn/service)
under ```bin/cfn``` dir

```
chmod u+x bin/cfn/service
./bin/cfn/service
```

![CrdSrvBackendFlask - success](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/assets/102387885/1bddd8b9-18f1-45b7-a0b0-8bddcc26d21a)

Update the ```Route 53``` record with new ALB - ```CrdClusterALB``` and do the ```api/health-check``` 

![skscorp api health check - true](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/assets/102387885/aba4eebc-84ae-4bc4-94f5-713e06d6fa83)

## SAM CFN for DynamoDB
Create a new folder ```ddb``` in the root level 
And ```function``` into it then create file [lambda_function.py](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/ddb/function/lambda_function.py)

Create files [template.yaml](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/ddb/template.yaml), [config.toml](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/ddb/config.toml)

And scripts [build](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/ddb/build), [package](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/ddb/package), [deploy](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/ddb/deploy) 

```
 chmod u+x ddb/[script_name]
 ./ddb/[script_name]
```

![ddb build](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/assets/102387885/40731e00-cddd-43b0-b606-51eb7afb44dc) 

![ddb package](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/assets/102387885/72dc5c17-ffde-4f1f-a463-53eae4f6cc3e)

![ddb-deploy cmd](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/assets/102387885/5d56ed32-264a-4f3f-a272-f899620e969a)

![CrdDdb success](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/assets/102387885/8d98cab3-31c2-4a27-a15f-ac6d9e931a06)

## CFN for CI/CD
Create "your_domain_name-codepipeline-cruddur-artifacts" bucket in the console

Create a new folder ```cicd``` inside ```aws/cfn``` dir and files [template.yaml](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/aws/cfn/cicd/template.yaml), [config.toml](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/aws/cfn/cicd/config.toml)

Then ```nested``` folder and file [codebuild.yaml](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/aws/cfn/cicd/nested/codebuild.yaml)<br>
Create an empty folder in the root called ```tmp``` to store ```packaged-template.yaml``` and add ```tmp/*``` in the ```gitignore``` file

![tmp folder packaged-template yaml file](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/assets/102387885/9bcef3b5-3cfb-4de5-8941-dbfc4e027abd)

Create ``` cicd ``` script in ```bin/cfn``` dir
```
chmod u+x bin/cfn/cicd-deploy 
./bin/cfn/cicd-deploy
``` 
![CrdCicd success](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/assets/102387885/9686855f-2520-4b7d-bd98-ba5f273e14ad)


In the console ```Update pending connection``` for the ```CrdCicd``` connection  


![cicd connection done](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/assets/102387885/035c5ca8-2e66-4233-897b-accdf0684e63)

## CFN Static Website Hosting Frontend
Delete the **naked domain name** in Route53

Create a new folder ```frontend``` in ```aws/cfn``` dir and files [template.yaml](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/aws/cfn/frontend/template.yaml), [config.toml](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/aws/cfn/frontend/config.toml)

Create a new script [frontend](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/bin/cfn/frontend) in ```bin/cfn``` dir
```
chmod u+x bin/cfn/frontend
./bin/cfn/frontend
```
![CrdFrontend success](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/assets/102387885/59aab314-510c-4a71-9a7d-367808037470)

## CFN Architecture Diagram
![CFN diagram (2)](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/assets/102387885/26f9878f-99b1-4ad1-8b05-43d6baa5e0a1)


