# Week X — Cleanup
## Sync tool for static website hosting
For the production build, create a new script ```static-build``` in the ```./bin/frontend``` dir 
```
chmod u+x ./bin/frontend/static-build
./bin/frontend/static-build
```
Now the build folder will be ready to be deployed. In order to serve the static content via CloudFront, download the build dir
```
cd frontend-react-js
zip -r build.zip build
```
And upload it to the root domain S3 bucket ```skscorp.net```

### AWS s3 Website sync

This is the tool to sync a folder from local developer environment to the s3 bucket  and then invalidate the CloudFront cache.

Create a ```Gemfile``` in the root that installs the gem:

```
source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'rake'
gem 'aws_s3_website_sync', tag: '1.0.1'
gem 'dotenv', groups: [:development, :test]
```

To install: ```bundle install```

Create a ```Rakefile```, it contains executable Ruby codes.

```
require 'aws_s3_website_sync'
require 'dotenv'

task :sync do
  puts "sync =="
  AwsS3WebsiteSync::Runner.run(
    aws_access_key_id:     ENV["AWS_ACCESS_KEY_ID"],
    aws_secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
    aws_default_region:    ENV["AWS_DEFAULT_REGION"],
    s3_bucket:             ENV["S3_BUCKET"],
    distribution_id:       ENV["CLOUDFRONT_DISTRUBTION_ID"],
    build_dir:             ENV["BUILD_DIR"],
    output_changset_path:  ENV["OUTPUT_CHANGESET_PATH"],
    auto_approve:          ENV["AUTO_APPROVE"],
    silent: "ignore,no_change",
    ignore_files: [
      'stylesheets/index',
      'android-chrome-192x192.png',
      'android-chrome-256x256.png',
      'apple-touch-icon-precomposed.png',
      'apple-touch-icon.png',
      'site.webmanifest',
      'error.html',
      'favicon-16x16.png',
      'favicon-32x32.png',
      'favicon.ico',
      'robots.txt',
      'safari-pinned-tab.svg'
    ]
  )
End
```

And run sync
```
bundle exec rake sync
```

Create ```sync.env.erb``` file in the ```erb``` dir
```
SYNC_S3_BUCKET=skscorp.net
SYNC_CLOUDFRONT_DISTRUBTION_ID=E3L9DUFT2X9TZ8
SYNC_BUILD_DIR=<%= ENV['THEIA_WORKSPACE_ROOT'] %>/frontend-react-js/build
SYNC_OUTPUT_CHANGESET_PATH=<%=  ENV['THEIA_WORKSPACE_ROOT'] %>/tmp
SYNC_AUTO_APPROVE=false
```

Create a ```tmp``` dir and file ```.keep```, if they aren’t already there and to keep the dir: run ```git add -f tmp/.keep```

Then update the ```./bin/frontend/generate-env`` file
```
template = File.read 'erb/sync.env.erb'
content = ERB.new(template).result(binding)
filename = "sync.env"
File.write(filename, content)
```
And run: ```./bin/frontend/generate-env``` to create the ```sync.env``` file

Create a ruby file called [sync](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/bin/frontend/sync) 

```
chmod u+x ./bin/frontend/sync
./bin/frontend/sync
```

### To run a Ruby Script using GitHub Actions - create a ```workflow``` file

Create a folder ```.github``` and ```workflows``` into it then [sync.yaml.example](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/github/workflows/sync.yaml.example) file

### CloudFormation template to configure the IdP:

update ```gitpod.yml``` -
```
 bundle update –bundler
```
 
Create a folder ``` sync``` in ```aws/cfn/``` and files [template.yaml](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/aws/cfn/sync/template.yaml), [config.toml](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/aws/cfn/sync/config.toml)

And create a script [sync](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/bin/cfn/sync) in ```bin/cfn/``` 

```
chmod u+x ./bin/cfn/sync
./bin/cfn/sync
```

Go to the CloudFormation in the console and **execute change set**

![CrdsyncRole success j](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/assets/102387885/7da4ea0c-14d6-40aa-841f-7f87cfba367b)


Create an **inline policy** called ```S3AccessForSync``` for ``` CrdSyncRole```
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:ListBucket",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::skscorp.net",
                "arn:aws:s3:::skscorp.net/*"
            ]
        }
    ]
}
```

## Reconnect Database and Post Confirmation Lambda
Create a new SG ```CognitoLambdaSG``` to attach with the ```cruddur-post-confirmation lambda``` function  

Go to the SG ```CrdDbRDSSG``` , edit the inbound rule -> add rule: PostgreSQL - CognitoLambdaSG - Description: COGNITOPOSTCONF then save

Edit the VPC configuration of ```cruddur-post-confirmation lambda``` function to add the created SG  ``` CognitoLambdaSG ``` (configuartion -> VPC -> edit -> choose CrdNet VPC -> 3 public subnets->  choose CognitoLambdaSG -> save)

Add inbound rule to the ```CrdDbRDSSG``` -> Type: Custom TCP, Source: My IP, Description: GITPOD

And update the gitpod env vars of ```DB_SG_ID``` and ```DB_SG_RULE_ID``` 

Then update the SG rule with the command
```
./bin/rds/update-sg-rule
```
Add the bio column to the ```cruddur-instane``` db by overriding the CONNECTION_URL with the PROD_CONNECTION_URL to migrate
```
CONNECTION_URL=$PROD_CONNECTION_URL ./bin/db/migrate
```
```
./bin/db/schema-load prod 

./bin/db/connect prod 
\d users; 
```
![migrate bio added j](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/assets/102387885/50dd5c06-74f2-4217-a639-9d48e702dda7)

Sign up to create a new Cruddur account and the new users are inserted into the table by the ```cruddur-post-confirmation lambda``` function


## CICD Pipeline and Create Activity
After all the changes committed, created a new pull request from ```main``` to branch ‘’’prod``` that trigger the CodePipeline
![codepipelinej](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/assets/102387885/0e78bb4c-4b9c-4efb-9064-929a8f91d295)

### Fixed the CORS issue to use the domain name and created activity
![activity worked j](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/assets/102387885/ff7ef138-cc8d-4062-aff8-e29e5af1f1ea)


## Refactor: JWT to use a decorator in Flask App, app.py, Flask Routes
### Decorator to handle JWT verification
```
from functools import wraps, partial
from flask import request, g
import os
from flask import current_app as app

def jwt_required(f=None, on_error=None):
    if f is None:
        return partial(jwt_required, on_error=on_error)

    @wraps(f)
    def decorated_function(*args, **kwargs):
        cognito_jwt_token = CognitoJwtToken(
            user_pool_id=os.getenv("AWS_COGNITO_USER_POOL_ID"), 
            user_pool_client_id=os.getenv("AWS_COGNITO_USER_POOL_CLIENT_ID"),
            region=os.getenv("AWS_DEFAULT_REGION")
        )
        access_token = extract_access_token(request.headers)
        try:
            claims = cognito_jwt_token.verify(access_token)
            # is this a bad idea using a global?
            g.cognito_user_id = claims['sub']  # storing the user_id in the global g object
        except TokenVerifyError as e:
            # unauthenticated request
            app.logger.debug(e)
            if on_error:
                return on_error(e)
            return {}, 401
        return f(*args, **kwargs)
    return decorated_function
```

### Refactor ```app.py``` into 
[cloudwatch.py](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/backend-flask/lib/cloudwatch.py)<br>
[cors.py](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/backend-flask/lib/cors.py)<br>
[helpers.py](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/backend-flask/lib/helpers.py)<br>
[honeycomb.py](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/backend-flask/lib/honeycomb.py)<br>
[rollbar.py](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/backend-flask/lib/rollbar.py)<br>
[xray.py](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/backend-flask/lib/xray.py)<br>

### Refactor the routes for ```Flask```
Create a folder ```routes``` in ```backend-flask``` and create files<br>
[activities.py](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/backend-flask/routes/activities.py)<br>
[general.py](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/backend-flask/routes/general.py)<br>
[messages.py](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/backend-flask/routes/messages.py)<br>
[users.py](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/backend-flask/routes/users.py)<br>


## Implement replies for posts
Create [reply.sql](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/backend-flask/db/sql/activities/reply.sql) file <br>
Update 
Docker compose up
```
./bin/db/setup
./bin/db/connect 
\d activities;
```
![foreslash d activities - query result j](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/assets/102387885/e0b43188-55e6-4ee8-ac79-f8dede0e7deb)

```
./bin/generate/migration reply_to_activity_uuid_to_string
```
Update the [reply_to_activity_uuid_to_string.py]( https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/backend-flask/db/migrations/16870243848137019_reply_to_activity_uuid_to_string.py)
```
    ALTER TABLE activities DROP COLUMN reply_to_activity_uuid;
    ALTER TABLE activities ADD COLUMN reply_to_activity_uuid uuid;
```

To alter the ```reply_to_activity_uuid``` to ```uuid```
```
./bin/db/migrate
```
### Production
```
CONNECTION_URL =$PROD_CONNECTION_URL ./bin/db/migrate
./bin/db/connect prod
\d activities;
```

![prod migration j](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/assets/102387885/c11d4e7c-91df-41d4-9adf-41c640d7a8b9)

### Improved Error Handling for the app
In ```frontend-react-js/src/components/``` create [FormErrors.js ](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/frontend-react-js/src/components/FormErrors.js), [FormErrors.css](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/frontend-react-js/src/components/FormErrors.css),  [FormErrorItem.js](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/frontend-react-js/src/components/FormErrorItem.js) files to handle the errors

And also create [request.js](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/frontend-react-js/src/lib/Requests.js)


## Activities show page
Create [ActivityShowPage.js](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/frontend-react-js/src/pages/ActivityShowPage.js) and [ActivityShowPage.css](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/frontend-react-js/src/pages/ActivityShowPage.css) files in the ```frontend-react-js/src/pages/```

And add the route to ```frontend-react-js/src/App.js``` file
```
  {
    path: "/@:handle/status/:activity_uuid",
    element: <ActivityShowPage />
  },
```

![prod reply testing j](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/assets/102387885/b3ef7cac-9cb6-475a-96c4-da8933056ba5)

![prod reply testing 1 j](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/assets/102387885/1d4ffcd7-90c3-4c78-9a92-dc66b8665389)

![activity page zomed out j](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/assets/102387885/132b2a3a-0439-42ce-b77c-42fe03260505)

## General Cleanup

Following the [Cleanup-part1](https://www.youtube.com/watch?v=E89RBvZ_BaY&list=PLBfufR7vyJJ7k25byhRXJldB5AiwgNnWv&index=123) and [Cleanup-part2](https://www.youtube.com/watch?v=53_3TmZ1hrs&list=PLBfufR7vyJJ7k25byhRXJldB5AiwgNnWv&index=124), modified frontend pages and components

### To access DynamoDB table
Create folder ``` machine-user ``` in ```aws/cfn/```  and files [config.toml](), [template.yaml]() and script [machineuser]() in ``` bin/cfn/```
```
chmod u+x ./bin/cfn/machineuser
./bin/cfn/machineuser
```
Go to the ```CrdMachineUser``` stack and ```execute change set``` 
![machineuser cfn stack j](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/assets/102387885/73c1e285-b617-4c52-96fb-33bf07d61f12)

Then create security credentials to the IAM user ```cruddur_machine_user``` and update the credentials to the AWS System Manager's ```parameter store``` in the console

Update the ``` backend-flask.env.erb ```
For development add the env var for DDB
``` 
DDB_MESSAGE_TABLE=cruddur-messages
```
For production: remove the AWS_ENDPOINT_URL and add
```
DDB_MESSAGE_TABLE=CrdDdb-DynamoDBTable-*******
```
After committing all the changes, create a new pull request from ```main``` to ```prod```. After successfully deployed
```
./bin/frontend/static-build
./bin/frontend/sync
```

![message group ddb prod j](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/assets/102387885/6e9cbdc9-c7a0-4cd9-8edc-d2e1f328fcd9)

