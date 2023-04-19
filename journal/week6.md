# Week 6 — Deploying Serverless Containers (Part 1/2)
## Technical Tasks
•	Create an Elastic Container Repository (ECR) 

•	Push our container images to ECR

•	Write an ECS Task Definition file for Fargate

•	Launch our Fargate services via CLI

•	Test that our services individually work

•	Play around with Fargate desired capacity

•	How to push new updates to your code update Fargate running tasks

Test that we have a Cross-origin Resource Sharing (CORS) issue

### To test the RDS connection
Create a file ```test``` under ```bin/db/``` and enter 
```
#!/usr/bin/env python3

import psycopg
import os
import sys

connection_url = os.getenv("PROD_CONNECTION_URL")

conn = None
try:
  print('attempting connection')
  conn = psycopg.connect(connection_url)
  print("Connection successful!")
except psycopg.Error as e:
  print("Unable to connect to the database:", e)
finally:
  conn.close()
```
Run the commands
 ```
chmod u+x bin/db/test
./bin/db/test
``` 
![1](https://user-images.githubusercontent.com/102387885/232808571-d6947e0c-2a0e-4e69-9e58-4852e119f96f.png)


### To health check against the backend Flask app

In the ```app.py``` file add the below contents
```
@app.route('/api/health-check')
def health_check():
  return {'success': True}, 200
```
create a file ```health-check``` under ``` backend-flask/bin``` and add
```
#!/usr/bin/env python3

import urllib.request

try:
  response = urllib.request.urlopen('http://localhost:4567/api/health-check')
  if response.getcode() == 200:
    print("[OK] Flask server is running")
    exit(0) # success
  else:
    print("[BAD] Flask server is not running")
    exit(1) # false
# This for some reason is not capturing the error....
#except ConnectionRefusedError as e:
# so we'll just catch on all even though this is a bad practice
except Exception as e:
  print(e)
  exit(1) # false
```
Run
```
chmod u+x bin/health-check
./bin/health-check
```
![step30](https://user-images.githubusercontent.com/102387885/232839166-2b8c5a69-371b-4987-9a70-ce3a6aba9ebe.png)
## CloudWatch log
Create a CloudWatch log group called ```cruddur``` with the retention policy
```
aws logs create-log-group --log-group-name "cruddur"
aws logs put-retention-policy --log-group-name "cruddur" --retention-in-days 1
```

## ECS & ECR 
Create ECS Cluster 
```aws ecs create-cluster \
--cluster-name cruddur \
--service-connect-defaults namespace=cruddur
```
### Gaining access to the ECS Fargate
To log into the container
```
aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com"
```
Later created a script called ```login``` under the ```bin/ecr``` folder
[login](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/bin/ecr/login)

![s17](https://user-images.githubusercontent.com/102387885/232838299-d89c5850-3587-43b7-8708-ecc130eb70bf.png)

Create 3 repos. 1 for base image, 1 for backend-flask and 1 for frontend-react-js  
#### For base image
```
aws ecr create-repository \
  --repository-name cruddur-python \
  --image-tag-mutability MUTABLE
```
![2](https://user-images.githubusercontent.com/102387885/232811151-90f1cc22-1c1b-49bb-b823-153d25ba47d9.png)

**Set URL**
```
export ECR_PYTHON_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/cruddur-python"

echo $ECR_PYTHON_URL

```
**Pull the image**
```
docker pull python:3.10-slim-buster
```
**Tag**
```
docker tag python:3.10-slim-buster $ECR_PYTHON_URL:3.10-slim-buster
```
**Push image**
```
docker push $ECR_PYTHON_URL:3.10-slim-buster
```
#### For backend-flask
Create a ```Dockerfile.prod``` file in the ```backend-flask```
```
FROM ********5666.dkr.ecr.us-east-1.amazonaws.com/cruddur-python:3.10-slim-buster

# [TODO] For debugging, don't leave these in
#RUN apt-get update -y
#RUN apt-get install iputils-ping -y
# -----

# Inside Container
# make a new folder inside container
WORKDIR /backend-flask

# Outside Container -> Inside Container
# this contains the libraries want to install to run the app
COPY requirements.txt requirements.txt

# Inside Container
# Install the python libraries used for the app
RUN pip3 install -r requirements.txt

# Outside Container -> Inside Container
# . means everything in the current directory
# first period . - /backend-flask (outside container)
# second period . /backend-flask (inside container)
COPY . .

EXPOSE ${PORT}

# CMD (Command)
# python3 -m flask run --host=0.0.0.0 --port=4567
CMD [ "python3", "-m" , "flask", "run", "--host=0.0.0.0", "--port=4567", "--no-debug","--no-debugger","--no-reload"]
```
**Create Repo**
```
aws ecr create-repository \
  --repository-name backend-flask \
  --image-tag-mutability MUTABLE
```
**Set URL**
```
export ECR_BACKEND_FLASK_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/backend-flask"

echo $ECR_BACKEND_FLASK_URL
```
**Build**
```
docker build -f "$BACKEND_FLASK_PATH/Dockerfile.prod" -t backend-flask-prod "$BACKEND_FLASK_PATH/."
```
**Tag**
```
docker tag backend-flask:latest $ECR_BACKEND_FLASK_URL:latest
```
**Push**
```
docker push $ECR_BACKEND_FLASK_URL:latest

```

#### For frontend-react-js
Create a ```Dockerfile.prod``` file in the ```frontend-react-js```
```
# Base Image ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
FROM node:16.18 AS build

ARG REACT_APP_BACKEND_URL
ARG REACT_APP_AWS_PROJECT_REGION
ARG REACT_APP_AWS_COGNITO_REGION
ARG REACT_APP_AWS_USER_POOLS_ID
ARG REACT_APP_CLIENT_ID

ENV REACT_APP_BACKEND_URL=$REACT_APP_BACKEND_URL
ENV REACT_APP_AWS_PROJECT_REGION=$REACT_APP_AWS_PROJECT_REGION
ENV REACT_APP_AWS_COGNITO_REGION=$REACT_APP_AWS_COGNITO_REGION
ENV REACT_APP_AWS_USER_POOLS_ID=$REACT_APP_AWS_USER_POOLS_ID
ENV REACT_APP_CLIENT_ID=$REACT_APP_CLIENT_ID

COPY . ./frontend-react-js
WORKDIR /frontend-react-js
RUN npm install
RUN npm run build

# New Base Image ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
FROM nginx:1.23.3-alpine

# --from build is coming from the Base Image
COPY --from=build /frontend-react-js/build /usr/share/nginx/html
COPY --from=build /frontend-react-js/nginx.conf /etc/nginx/nginx.conf

EXPOSE 3000
```

Create ```nginx.conf``` file 
```
# Set the worker processes
worker_processes 1;

# Set the events module
events {
  worker_connections 1024;
}

# Set the http module
http {
  # Set the MIME types
  include /etc/nginx/mime.types;
  default_type application/octet-stream;

  # Set the log format
  log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

  # Set the access log
  access_log  /var/log/nginx/access.log main;

  # Set the error log
  error_log /var/log/nginx/error.log;

  # Set the server section
  server {
    # Set the listen port
    listen 3000;

    # Set the root directory for the app
    root /usr/share/nginx/html;

    # Set the default file to serve
    index index.html;

    location / {
        # First attempt to serve request as file, then
        # as directory, then fall back to redirecting to index.html
        try_files $uri $uri/ $uri.html /index.html;
    }

    # Set the error page
    error_page  404 /404.html;
    location = /404.html {
      internal;
    }

    # Set the error page for 500 errors
    error_page  500 502 503 504  /50x.html;
    location = /50x.html {
      internal;
    }
  }
}
```
Run ```npm run build```

**Create Repo**
```
aws ecr create-repository \
  --repository-name frontend-react-js \
  --image-tag-mutability MUTABLE
```
**Set URL**
```
export ECR_FRONTEND_REACT_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/frontend-react-js"
echo $ECR_FRONTEND_REACT_URL
```
**Build**
```
docker build \
--build-arg REACT_APP_BACKEND_URL="https://4567-$GITPOD_WORKSPACE_ID.$GITPOD_WORKSPACE_CLUSTER_HOST" \
--build-arg REACT_APP_AWS_PROJECT_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_COGNITO_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_USER_POOLS_ID="$AWS_COGNITO_USER_POOL_ID" \
--build-arg REACT_APP_CLIENT_ID="$AWS_USER_POOL_CLIENT_ID" \
-t frontend-react-js \
-f Dockerfile.prod \
.
```
**Tag**
```
docker tag frontend-react-js:latest $ECR_FRONTEND_REACT_URL:latest
```
**Push**
```
docker push $ECR_FRONTEND_REACT_URL:latest
```
#### To run and test
```
docker run --rm -p 4567:4567 -it backend-flask
docker run --rm -p 3000:3000 -it frontend-react-js
```
![repos](https://user-images.githubusercontent.com/102387885/232831535-def3cd2a-2e06-4e05-8cc5-bc6be08dd998.png)

## Create Execution role and Task role
Create policies under ```aws``` folder 

```service-execution-policy.json```
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:GetAuthorizationToken",
                "logs:PutLogEvents",
                "ecr:BatchCheckLayerAvailability"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameters",
                "ssm:GetParameter"
            ],
            "Resource": "arn:aws:ssm:us-east-1:********5666:parameter/cruddur/backend-flask/*"
        }
    ]
} 
```
And ```service-assume-role-execution-policy.json```
```
{
  "Version":"2012-10-17",
  "Statement":[{
      "Action":["sts:AssumeRole"],
      "Effect":"Allow",
      "Principal":{
        "Service":["ecs-tasks.amazonaws.com"]
    }}]
}
```
Create Execution role
```
aws iam create-role \    
--role-name CruddurServiceExecutionRole \   
--assume-role-policy-document file://aws/policies/service-assume-role-execution-policy.json 
```
```
aws iam put-role-policy \
  --policy-name CruddurServiceExecutionPolicy \
  --role-name CruddurServiceExecutionRole \
  --policy-document file://aws/policies/service-execution-policy.json
"
```
```
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/CloudWatchFullAccess --role-name CruddurServiceExecutionRole

aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy --role-name CruddurServiceExecutionRole
```
Create ```Task role```
```
aws iam create-role \
    --role-name CruddurTaskRole \
    --assume-role-policy-document "{
  \"Version\":\"2012-10-17\",
  \"Statement\":[{
    \"Action\":[\"sts:AssumeRole\"],
    \"Effect\":\"Allow\",
    \"Principal\":{
      \"Service\":[\"ecs-tasks.amazonaws.com\"]
    }
  }]
}"

aws iam put-role-policy \
  --policy-name SSMAccessPolicy \
  --role-name CruddurTaskRole \
  --policy-document "{
  \"Version\":\"2012-10-17\",
  \"Statement\":[{
    \"Action\":[
      \"ssmmessages:CreateControlChannel\",
      \"ssmmessages:CreateDataChannel\",
      \"ssmmessages:OpenControlChannel\",
      \"ssmmessages:OpenDataChannel\"
    ],
    \"Effect\":\"Allow\",
    \"Resource\":\"*\"
  }]
}
"

aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/CloudWatchFullAccess --role-name CruddurTaskRole
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess --role-name CruddurTaskRole
```

## Create Services
Create files to create services under ```aws/json``` folder
For the backend ``` service-backend-flask.json``` 
```
{
  "cluster": "cruddur",
  "launchType": "FARGATE",
  "desiredCount": 1,
  "enableECSManagedTags": true,
  "enableExecuteCommand": true,
  "loadBalancers": [
    {
        "targetGroupArn": "arn:aws:elasticloadbalancing:us-east-1:********5666:targetgroup/cruddur-backend-flash-tg/7d0384bc48a4a76c",
        "containerName": "backend-flask",
        "containerPort": 4567
    }
  ],
  "networkConfiguration": {
    "awsvpcConfiguration": {
      "assignPublicIp": "ENABLED",
      "securityGroups": [
        "sg-08866e758ebe7efa5"
      ],
      "subnets": [
        "subnet-0774cdf7167c4f88c",
        "subnet-0f2ecc5a9c4a5f462",
        "subnet-00dbd1b36c127ffb6"
      ]
    }
  },
  "serviceConnectConfiguration": {
    "enabled": true,
    "namespace": "cruddur",
    "services": [
      {
        "portName": "backend-flask",
        "discoveryName": "backend-flask",
        "clientAliases": [{"port": 4567}]
      }
    ] 
  },

  "propagateTags": "SERVICE",
  "serviceName": "backend-flask",
  "taskDefinition": "backend-flask"
}
```
For the frontend ``` service-frontend-react-js.json```
```
{
    "cluster": "cruddur",
    "launchType": "FARGATE",
    "desiredCount": 1,
    "enableECSManagedTags": true,
    "enableExecuteCommand": true,
    "loadBalancers": [
      {
          "targetGroupArn": "arn:aws:elasticloadbalancing:us-east-1:********5666:targetgroup/cruddur-frontend-react-js-tg/e3edae8aed993282",
          "containerName": "frontend-react-js",
          "containerPort": 3000
      }
    ],  
    "networkConfiguration": {
      "awsvpcConfiguration": {
        "assignPublicIp": "ENABLED",
        "securityGroups": [
           "sg-08866e758ebe7efa5"
        ],
        "subnets": [
          "subnet-0774cdf7167c4f88c",
          "subnet-0f2ecc5a9c4a5f462",
          "subnet-00dbd1b36c127ffb6"
        ]
      }
    },
    "propagateTags": "SERVICE",
    "serviceName": "frontend-react-js",
    "taskDefinition": "frontend-react-js",
    "serviceConnectConfiguration": {
      "enabled": true,
      "namespace": "cruddur",
      "services": [
        {
          "portName": "frontend-react-js",
          "discoveryName": "frontend-react-js",
          "clientAliases": [{"port": 3000}]
        }
      ]
    }
  }  
```
```
aws ecs create-service --cli-input-json file://aws/json/service-backend-flask.json
aws ecs create-service --cli-input-json file://aws/json/service-frontend-react-js.json
```
![services](https://user-images.githubusercontent.com/102387885/232835801-1255e857-4e25-4949-b3b8-67fe88722206.png)

## Task Definitions 
### Passing sensitive datas to Task Definitions 
```
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/AWS_ACCESS_KEY_ID" --value $AWS_ACCESS_KEY_ID
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/AWS_SECRET_ACCESS_KEY" --value $AWS_SECRET_ACCESS_KEY
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/CONNECTION_URL" --value $PROD_CONNECTION_URL
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/ROLLBAR_ACCESS_TOKEN" --value $ROLLBAR_ACCESS_TOKEN
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/OTEL_EXPORTER_OTLP_HEADERS" --value "x-honeycomb-team=$HONEYCOMB_API_KEY"
```
Create a new folder ```task-definitions``` under ```aws``` 
And files ```backend-flask.json```
```
{
    "family": "backend-flask",
    "executionRoleArn": "arn:aws:iam::********5666:role/CruddurServiceExecutionRole",
    "taskRoleArn": "arn:aws:iam::********5666:role/CruddurTaskRole",
    "networkMode": "awsvpc",
    "cpu": "256",
    "memory": "512",
    "requiresCompatibilities": [ 
      "FARGATE" 
    ],
    "containerDefinitions": [
      {
        "name": "xray",
        "image": "public.ecr.aws/xray/aws-xray-daemon" ,
        "essential": true,
        "user": "1337",
        "portMappings": [
          {
            "name": "xray",
            "containerPort": 2000,
            "protocol": "udp"
          }
        ]
      },
      {
        "name": "backend-flask",
        "image": "********5666.dkr.ecr.us-east-1.amazonaws.com/backend-flask",
        "essential": true,
        "healthCheck": {
          "command": [
            "CMD-SHELL",
            "python /backend-flask/bin/health-check"
          ],
          "interval": 30,
          "timeout": 5,
          "retries": 3,
          "startPeriod": 60
        },
        "portMappings": [
          {
            "name": "backend-flask",
            "containerPort": 4567,
            "protocol": "tcp", 
            "appProtocol": "http"
          }
        ],
        "logConfiguration": {
          "logDriver": "awslogs",
          "options": {
              "awslogs-group": "cruddur",
              "awslogs-region": "us-east-1",
              "awslogs-stream-prefix": "backend-flask"
          }
        },
        "environment": [
          {"name": "OTEL_SERVICE_NAME", "value": "backend-flask"},
          {"name": "OTEL_EXPORTER_OTLP_ENDPOINT", "value": "https://api.honeycomb.io"},
          {"name": "AWS_COGNITO_USER_POOL_ID", "value": "$AWS_COGNITO_USER_POOL_ID"},
          {"name": "AWS_COGNITO_USER_POOL_CLIENT_ID", "value": "$AWS_USER_POOL_CLIENT_ID"},
          {"name": "FRONTEND_URL", "value": "*"},
          {"name": "BACKEND_URL", "value": "*"},
          {"name": "AWS_DEFAULT_REGION", "value": "us-east-1"}
        ],
        "secrets": [
          {"name": "AWS_ACCESS_KEY_ID"    , "valueFrom": "arn:aws:ssm:us-east-1:********5666:parameter/cruddur/backend-flask/AWS_ACCESS_KEY_ID"},
          {"name": "AWS_SECRET_ACCESS_KEY", "valueFrom": "arn:aws:ssm:us-east-1:********5666:parameter/cruddur/backend-flask/AWS_SECRET_ACCESS_KEY"},
          {"name": "CONNECTION_URL"       , "valueFrom": "arn:aws:ssm:us-east-1:********5666:parameter/cruddur/backend-flask/CONNECTION_URL" },
          {"name": "ROLLBAR_ACCESS_TOKEN" , "valueFrom": "arn:aws:ssm:us-east-1:********5666:parameter/cruddur/backend-flask/ROLLBAR_ACCESS_TOKEN" },
          {"name": "OTEL_EXPORTER_OTLP_HEADERS" , "valueFrom": "arn:aws:ssm:us-east-1:********5666:parameter/cruddur/backend-flask/OTEL_EXPORTER_OTLP_HEADERS" }
        ]
      }
    ]
  }
 ```
And ```fronend-react-js.json```
```
{
    "family": "frontend-react-js",
    "executionRoleArn": "arn:aws:iam::********5666:role/CruddurServiceExecutionRole",
    "taskRoleArn": "arn:aws:iam::********5666:role/CruddurTaskRole",
    "networkMode": "awsvpc",
    "cpu": "256",
    "memory": "512",
    "requiresCompatibilities": [ 
      "FARGATE" 
    ],
    "containerDefinitions": [
      {
        "name": "xray",
        "image": "public.ecr.aws/xray/aws-xray-daemon" ,
        "essential": true,
        "user": "1337",
        "portMappings": [
          {
            "name": "xray",
            "containerPort": 2000,
            "protocol": "udp"
          }
        ]
      },
      {
        "name": "frontend-react-js",
        "image": "********5666.dkr.ecr.us-east-1.amazonaws.com/frontend-react-js",
        "essential": true,
        "healthCheck": {
          "command": [
            "CMD-SHELL",
            "curl -f http://localhost:3000 || exit 1"
          ],
          "interval": 30,
          "timeout": 5,
          "retries": 3
        },
        "portMappings": [
          {
            "name": "frontend-react-js",
            "containerPort": 3000,
            "protocol": "tcp", 
            "appProtocol": "http"
          }
        ],
  
        "logConfiguration": {
          "logDriver": "awslogs",
          "options": {
              "awslogs-group": "cruddur",
              "awslogs-region": "us-east-1",
              "awslogs-stream-prefix": "frontend-react-js"
          }
        }
      }
    ]
  }
  ```

### Register task-definitions
```
aws ecs register-task-definition --cli-input-json file://aws/task-definitions/backend-flask.json
aws ecs register-task-definition --cli-input-json file://aws/task-definitions/frontend-react-js.json
```
![tasks](https://user-images.githubusercontent.com/102387885/232835995-2ea9f989-c22f-4b59-a05c-03e3086e27f6.png)

#### Restructured the bash scripts
Created bash scripts later to **build, tag, register and push** images.

Created two folders inside the ```bin``` dir named
``` backend ```
[generate-env](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/bin/backend/generate-env%20),
[build](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/bin/backend/build),
[register](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/bin/backend/register),
[push](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/bin/backend/push),
[deploy](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/bin/backend/deploy),
[connect](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/bin/backend/connect),
[run](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/bin/backend/run)

```frontend```
[generate-env](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/bin/frontend/generate-env%20),
[build](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/bin/frontend/build),
[register](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/bin/frontend/register),
[push](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/bin/frontend/push),
[deploy](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/bin/frontend/deploy),
[connect](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/bin/frontend/connect),
[run](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/bin/frontend/run)


## Defaults
```
export DEFAULT_VPC_ID=$(aws ec2 describe-vpcs \
--filters "Name=isDefault, Values=true" \
--query "Vpcs[0].VpcId" \
--output text)
echo $DEFAULT_VPC_ID
```
```
export DEFAULT_SUBNET_IDS=$(aws ec2 describe-subnets  \
 --filters Name=vpc-id,Values=$DEFAULT_VPC_ID \
 --query 'Subnets[*].SubnetId' \
 --output json | jq -r 'join(",")')
echo $DEFAULT_SUBNET_IDS
```
## Security Group
Create security group
```
export CRUD_SERVICE_SG=$(aws ec2 create-security-group \
  --group-name "crud-srv-sg" \
  --description "Security group for Cruddur services on ECS" \
  --vpc-id $DEFAULT_VPC_ID \
  --query "GroupId" --output text)
echo $CRUD_SERVICE_SG
```
```
aws ec2 authorize-security-group-ingress \
  --group-id $CRUD_SERVICE_SG \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0
```

```
export CRUD_SERVICE_SG=$(aws ec2 describe-security-groups \
  --filters Name=group-name,Values=crud-srv-sg \
  --query 'SecurityGroups[*].GroupId' \
  --output text)
```
Update RDS security group to allow access for the CRUD_SERVICE_SG
```
aws ec2 authorize-security-group-ingress \
  --group-id $DB_SG_ID \
  --protocol tcp \
  --port 5432 \
  --source-group $CRUD_SERVICE_SG \
  --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=BACKENDFLASK}]'
```


## Connection via Session Manager (Fargate)
Install for Ubuntu (added these to the ```gitpod.yml``` file)
```
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"

sudo dpkg -i session-manager-plugin.deb
```
To verify its working
```
session-manager-plugin
```
Connect to ECS container
```
aws ecs execute-command  \
--region $AWS_DEFAULT_REGION \
--cluster cruddur \
--task dceb2ebdc11c49caadd64e6521c6b0c7 \
--container backend-flask \
--command "/bin/bash" \
--interactive
```
![ecs-connectCmd](https://user-images.githubusercontent.com/102387885/232842218-2581c421-2245-4675-91ab-d596038d53bd.png)

## Files in the codebase

[test](https://github.com/omenking/aws-bootcamp-cruddur-2023/blob/week-6-again/bin/db/test)

[health-check](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/backend-flask/bin/health-check)

[service-assume-role-execution-policy.json](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/aws/policies/service-assume-role-execution-policy.json)

[service-execution-policy.json](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/aws/policies/service-execution-policy.json)

### Part 2/2 
Continuation to [Week 7](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/journal/week7.md)
