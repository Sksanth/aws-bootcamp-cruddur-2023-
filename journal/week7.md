# Week 7 — Solving CORS with a Load Balancer and Custom Domain (Part 2/2)

## Technical Tasks

•	Create a Route53 hosted zone to manage our domain

•	Generate a public certificate via AWS Certificate Manager (ACM)

•	Create an Application Load Balancer (ALB)

•	Create ALB target group that points to our Fargate instances

•	Update our application to handle CORS
 
## Application Load Balancer
Create ALB and target groups via AWS console 

### Target Group
```backend``` - choose a target type: IP addresses, Target group name - ```cruddur-backend-flask-tg```, Protocol – HTTP:4567, default VPC, Health checks: /api/health-check

```frontend``` - choose a target type: IP addresses, Target group name - ```cruddur-frontend-react-js-tg```, Protocol – HTTP:3000, default VPC


![target group](https://user-images.githubusercontent.com/102387885/232957797-8238c23b-093a-4096-b03c-a44e104a3a2a.png)


### ALB Configuration

**Basic Configuration:** load balancer name ```cruddur-alb``` , internet facing, ipv4

**Network mapping:** default VPC, Subnets – us-east-1a, us-east-1b, us-east-1c

**Security groups:** create new security group – Security group name ```cruddur-alb-sg```, Inbound rules: http - anywhere, https – anywhere

**Listener:** 1) port - 4567, Default action – choose the ```cruddur backend-flask-tg```, 
              2) port-3000, ```cruddur-frontend-react-js-tg```
             

Update the security group ```cruddur-srv-sg``` inbound rules to gain access through the ALB for both frontend 3000 and backend 4567

![albListeners](https://user-images.githubusercontent.com/102387885/232958161-4c4f94fb-710f-448b-a6ee-b866b5c15f37.png)


## Route 53 Hosted Domain

I had a domain ```skscorp.net``` registered with Route 53 for another project but never used it so using it for Cruddur app. Followed [the document]( https://aws.amazon.com/getting-started/hands-on/get-a-domain/) for the domain creation and DNS configuration.


![hosted zone](https://user-images.githubusercontent.com/102387885/232957682-60a83575-883d-4554-88a8-9a09d700911b.png)

## Steps to Request Certificate
Go to the Certificate Manager, request a public certificate, enter the domain names ```skscorp.net``` and ```*.skscorp.net``` and request.

On the Validation page, expand both domains and choose Create record in Route 53 to automatically add the CNAME records for the domains, and then choose Create.

## DNS Configuration
### Create records to tell Route 53 to route traffic for the domain and subdomains. 
Go to EC2 -> load balancers -> cruddur-alb -> add listener -> Listener details (Protocol - HTTP :Port -80), Default actions(redirect to – https:443)

Add another listener -> Listener details (Protocol – HTTPS:Port-443) -> Default actions (forward to Target group(cruddur-frontend-react-js-tg) -> Default SSL/TLS certificate (From ACM -attached skcorp.net ACM certificate)

Under Listerners tab, choose HTTPS:443 listener -> select **manage rules** under Actions-> add rule (Host header – api.skscorp.net, Add action (Forward to – cruddur-backend-flask-tg)

Go to the Hosted zone again -> skscorp.net ->create record(one record without the Record name and another one with ```api```-> Record type(A – Route traffic to an IPv4 address and some AWS resources) -> Alias (value - route traffic to (Alias to Application & classic load balancer), choose region, choose load balancer) -> Routing policy(simple)

![curlsks](https://user-images.githubusercontent.com/102387885/232956885-befa98e2-87bd-46f0-a646-c3b67948c6a1.png)


![browsercurl](https://user-images.githubusercontent.com/102387885/232957012-641b2d70-bf43-4a63-ae51-2d8312ccebc7.png)

### Testing locally
```
./bin/ecr/login
./bin/backend/generate-env
./bin/frontend/generate-env
```

Do ```docker compose up```
Then 
```
./bin/db/setup
./bin/ddb/schema-load
./bin/ddb/seed
```

![works locally](https://user-images.githubusercontent.com/102387885/232956138-3f74e563-6e35-48a6-a5a7-83b053787187.png)

### Fix messaging in production
Update the ```backend-flask.json``` of task definition’s FRONTEND_URL and BACKEND_URL values with ```https://skscorp.net```, ``` https://api.skscorp.net``` as shown below
```
          {"name": "FRONTEND_URL", "value": "https://skscorp.net"},
          {"name": "BACKEND_URL", "value": "https://api.skscorp.net"},
```
Then re-register the task definition and update the service with the latest 
```
./bin/backend/register
./bin/backend/deploy

```
And also update the ```./bin/frontend/build``` file’s 
```
REACT_APP_BACKEND_URL="https://api.skscorp.net" \
```

```
./bin/frontend/build
./bin/frontend/push
./bin/frontend/register
./bin/frontend/deploy
```

Had issues creating messages due to error in the backend-flask env vars. Fixed it during the office hours


![logsinsight](https://user-images.githubusercontent.com/102387885/232957527-bb6351bc-5fa0-4cc0-85c5-d6c99ae64541.png)

![week7 done](https://user-images.githubusercontent.com/102387885/232956240-d9051fb3-376b-44a4-9519-8df025c7bee2.png)






