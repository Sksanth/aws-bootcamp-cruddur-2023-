# Week 8 — Serverless Image Processing
## Summary:
•	Create CDK stack<br>
•	Create S3 bucket to store assets<br>
•	Serve assets behind CloudFront<br>
•	Process images using a JavaScript lambda running sharp<br>
•	Implement lambda layers<br>
•	Use S3 event notifications to trigger processing images<br>
•	Implement HTTP API Gateway using a lambda authorizer<br>
•	Implement a ruby function to generate a resigned URL<br>
•	Upload assets to a bucket client side using a resigned URL<br>

## Create CDK stack

Before deploying AWS CDK, bootstrap the environment (AWS account and Region) 
```
cdk bootstrap "aws://$AWS_ACCOUNT_ID/$AWS_DEFAULT_REGION"
```
Create a dir ``` thumbing-serverless-cdk ``` in the root level and install CDK globally
```
mkdir thumbing-serverless-cdk
cd thumbing-serverless-cdk

npm install aws-cdk -g
```
Intialize a new project within the folder
```
cdk init app --language typescript
```
![w8FstStep](https://user-images.githubusercontent.com/102387885/236957602-e93f25a3-20f3-4153-8701-4513505b12eb.jpg)

### Synth and Deploy
Convert stack(s) into CloudFormation template 
```
cdk synth
```
Deploy the template into the account 
```
 cdk deploy
```
![thumbingserverlesscdkstacksuccess](https://user-images.githubusercontent.com/102387885/236958510-59d193d7-e1e8-4a22-b0d6-e303109adf43.jpg)

### Load Environment Variables

Create ```.env.example``` file 
```
UPLOADS_BUCKET_NAME="cruddur-uploaded-avatars"
ASSETS_BUCKET_NAME="assets.<domain_name>"
THUMBING_S3_FOLDER_OUTPUT="avatars"
THUMBING_WEBHOOK_URL="https://api.<domain_name>/webhooks/avatar"
THUMBING_TOPIC_NAME="cruddur-assets"
THUMBING_FUNCTION_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/lambdas/process-images" 
```
and run 
``` 
cp .env.example .env 
npm i dotenv
```
```
export DOMAIN_NAME=<domain_name>
gp env DOMAIN_NAME=<domain_name>
export UPLOADS_BUCKET_NAME=cruddur-uploaded-avatars
gp env UPLOADS_BUCKET_NAME=cruddur-uploaded-avatars
```
### S3 bucket 
Create a S3 bucket ```assets.<domain_name> ``` manually to store assets.<br>
Add codes to the [thumbing-serverless-cdk-stack.ts](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/thumbing-serverless-cdk/lib/thumbing-serverless-cdk-stack.ts) file to create S3 bucket, bucket policies, Lambda function, SNS topic, SNS Subscription and Event Notifications 

then run
``` 
cdk synth 
cdk deploy
```
![bucketProperties](https://user-images.githubusercontent.com/102387885/236959019-6467280a-90a8-4a94-ba5d-95c450b890db.jpg)

### Process images using Lambda

Create a folder ```process-images``` and files [index.js](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/aws/lambdas/process-images/index.js) , [test.js](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/aws/lambdas/process-images/test.js), [s3-image-processing.js](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/aws/lambdas/process-images/s3-image-processing.js), [example.json](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/aws/lambdas/process-images/example.json)

And run
```
cd aws/lambdas/process-images
npm init -y 
npm i sharp
npm i @aws-sdk/client-s3
```

Create ```avatar``` folder and scripts [build](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/bin/avatar/build), [upload](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/bin/avatar/upload) – to upload images into the bucket, for that you have to create a ```file``` folder inside the bin and load images. Here I have ```data.jpg```, [clear](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/bin/avatar/clear) – to remove the images from buckets
Run 
```
chmod u+x ./bin/avatar/<script_name>
./bin/avatar/<script_name>
```

## Update gitpod.yml file
```
- name: cdk
  before: |
    npm install aws-cdk -g
    cd thumbing-serverless-cdk
    npm i
```
```
bash bin/ecr/login
```
```
ruby $THEIA_WORKSPACE_ROOT/bin/frontend/generate-env\  
```
```
ruby $THEIA_WORKSPACE_ROOT/bin/backend/generate-env\  
```

## Serving avatars via CloudFront

Setup CloudFront distribution manually to serve assets from S3 bucket.

**Create a CloudFront distribution** <br>
•	```Origin domain (point to the S3 bucket):``` assets.<domain_name>.s3.us-east-1.amazonaws.com <br>
•	```Origin access:``` Origin access control settings(recommended)<br>
•	```Origin access control(“Create control setting”):``` choose the created access control <br>
•	Add the bucket policy to the assets bucket (CloudFront will provide the policy after creating the distribution)  <br>
•	```Viewer protocol policy:``` Redirect HTTP to HTTPS <br>
•	Cache key and origin request policy(recommended)- ```Cache policy:``` CachingOptimized(Recommended for S3),  ```Origin request policy(optional):``` CORS-CustomOrigin <br>
•	```Response headers policy:``` SimpleCORS <br>
•	```Alternate domain name:``` assets.<domain_name> <br>
•	```Custom SSL certificate:``` choose the domain name certificate ```NOTE:``` the certificate must be in the us-east-1. If you don’t have one for the us-east-1, request a new certificate for that region <br>
• ```Description:``` Serve Assets for Cruddur


### CloudFront distribution - Route 53 record 

Route 53 -> Hosted Zone -> Domain_name -> Create record -> Record name: assets -> turn on Alias -> Route traffic: Alias to CloudFront distribution -> choose CloudFront endpoint 


## Implement User profiles page, Migrations Backend Endpoint and Profile Form

Create a folder ```banners``` manually in the ```assets.<domain_name>``` bucket and upload ```banner.jpg```

To enable absolute import, create a file ``` jsconfig.json``` in the frontend 
```
{
  "compilerOptions": {
    "baseUrl": "src"
  },
  "include": ["src"]
}
```

In order to show *Profile avatar, display name, banner and bio*, have to update/create the files.

#### Create
*Backend files* -  [show.sql](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/backend-flask/db/sql/users/show.sql) , [update.sql](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/backend-flask/db/sql/users/update.sql), [update_profile.py](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/backend-flask/services/update_profile.py)
*Frontend files* - [EditProfileButton.js](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/frontend-react-js/src/components/EditProfileButton.js) and [EditProfileButton.css](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/frontend-react-js/src/components/EditProfileButton.css), [ProfileHeading.js](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/frontend-react-js/src/components/ProfileHeading.js) and [ProfileHeading.css](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/frontend-react-js/src/components/ProfileHeading.css), [ProfileForm.js](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/frontend-react-js/src/components/ProfileForm.js) and [ProfileForm.css](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/frontend-react-js/src/components/ProfileForm.css), [Popup.css](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/frontend-react-js/src/components/Popup.css)


#### Update 
*Backend files* - user_activities.py,app.py <br>
*Frontend files* - app.js UserFeedPage.js, HomeFeedPage.js, NotificationFeedPage.js, ReplyForm.css,  files 


create a new dir ```generate``` and file [migration](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/bin/generate/migration) inside the bin.

And also create an dir ```migrations``` in the ```backend-flask/db```and create an ```.keep``` empty file 

And run 
```
chmod u+x ./bin/generate/migration
./bin/generate/migration add_bio_column
```
After running the command, a python file [16826196872176304_add_bio_column.py](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/backend-flask/db/migrations/16826196872176304_add_bio_column.py) will be generated in ```backend-flask/db/migrations/``` dir.


Create files [migrate](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/bin/db/migrate) and [rollback](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/bin/db/rollback). Next ```chmod``` the files

Update the ```schema.sql``` ```db.py``` in the backend and update the ```bin/db/setup``` file with ``` python "$DB_PATH/migrate" ```  


## Implement avatar uploading

Generate a presigned URL to upload an image/object to the S3 bucket. 
Create a folder ```cruddur-upload-avatar``` in ```aws/lambdas/``` and a ruby file [function.rb](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/aws/lambdas/cruddur-upload-avatar/function.rb) 

Run
```
cd aws/lambdas/cruddur-upload-avatar
bundle init

``` 
it will create a [Gemfile](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/aws/lambdas/cruddur-upload-avatar/Gemfile)
And then run ``` bundle install ```, it will create ```Gemfile.lock``` file

Running ``` bundle exec ruby function.rb ```command will return the ```presigned url```


Create another folder ```lambda-authorizer``` and [index.js](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/aws/lambdas/lambda-authorizer/index.js) file 

Run ``` npm install aws-jwt-verify --save``` . It will add the packages.
Download the files and zip it. 

### Create Lambda function

#### *cruddur-upload-avatars*

And also Create a Lambda function manually in the console called ```CruddurAvatarUpload``` with ```Ruby 2.7```, ```function.rb``` file name and put the contents there.
Create an inline policy ``` PresignedURLavatarPolicy ```and attach it to the Lambda function.
Copy the policy contents and create a json file ``` s3-upload-avatar-presigned-url-policy.json``` in ``` aws/policies/``` and paste it there.
Rename the Handler to ```function.handler``` and add the env var ``` UPLOADS_BUCKET_NAME``` with value.

Add Ruby JWT Lambda layer to the and create ``` lambda-layers``` in the bin dir and file [ruby-jwt](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/bin/lambda-layers/ruby-jwt)

Add ```CORS policy``` to the bucket and create a folder ```s3``` under ```aws``` dir and file [cors.json](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/aws/s3/cors.json), update the file with the policy contents


#### *CruddurApiGatewayLambdaAuthorizer*

Create ``` CruddurApiGatewayLambdaAuthorizer ``` Lambda function and add the ```lambda-authorizer.zip``` file and add the env vars ```USER_POOL_ID``` and ```CLIENT_ID```

![bio update](https://user-images.githubusercontent.com/102387885/236971859-c59ebde1-dacb-4283-a502-17869cf1d61a.png)


### API Gateway

Go to the ```API Gateway``` -> create ```HTTP API``` -> Integration: Lambda -> us-east-1 -> Lambda function: CruddurAvatarUpload -> API name: api.<domain_name> -> Configure routes – 1. Method: POST -> Resource path : /avatars/key_upload with ``` CruddurAvatarUpload ``` integration, 2.Method: OPTIONS -> Resource path : /{proxy+}   -> create

![api gateway routes](https://user-images.githubusercontent.com/102387885/236966396-74dd209b-4ab6-4f7d-815f-ad14c0ca3d67.png)

Then create ```CruddurJWTAuthorizer``` with ``` CruddurApiGatewayLambdaAuthorizer ``` Lambda function and turn off the ```Authorizer aching``` and attach it to the POST route.

![Api gateway authorization](https://user-images.githubusercontent.com/102387885/236966405-65abdd6e-b009-4fb7-86f5-1e28fe8faf1c.png)
To render Avatar from CloudFront using cognito_user_uuid, create a file [ProfileAvatar.js](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/frontend-react-js/src/components/ProfileAvatar.js) 


![week 8 done but i uploaded the cognito user id jpg](https://user-images.githubusercontent.com/102387885/236954550-095dca2e-f0e2-494b-a3d9-ad95d759e470.png)
