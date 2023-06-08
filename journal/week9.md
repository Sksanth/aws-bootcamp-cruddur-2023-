# Week 9 — CI/CD with CodePipeline, CodeBuild and CodeDeploy

## Class Summary
•	Create a buildspec.yml file <br>
•	Configure CodeBuild Project <br>
•	Configure CodePipeline

Create ```buildspec.yml``` file under ```backend-flask``` - [buildspec.yml](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/backend-flask/buildspec.yml) <br>
Create a ```New branch``` called ```prod``` in GitHub <br>
Update the ```backend-flask/app.py``` health_check
```
 return {'success': True, "ver": 1}, 200
```

## Configure CodeBuild

Create build project in the console

![CB1](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/assets/102387885/e8d3ac31-af21-4f47-90e5-99478a410574)
![CB2](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/assets/102387885/876c65bb-a41e-4621-8dc7-c8a92e24cece)
![CB3](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/assets/102387885/2e1a43ae-3253-41b7-b078-0f928a968629)
![CB4](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/assets/102387885/4fa6294d-3eaa-4a55-bd2a-06ea7f4a36e1)
![CB5](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/assets/102387885/fba507ab-b94d-4c09-9dd2-23f1d8918436)

### Service role policy
Add an inline policy to the created service role ```codebuild-cruddur-backend-flask-bake-image-service-role``` - [ecr-codebuild-backend-role.json](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/aws/policies/ecr-codebuild-backend-role.json)


## Configure CodePipeline
Go to ```cruddur```, Edit and Add stage ```Stage name: bake``` the Add action group

### Build config
![build config](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/assets/102387885/b1eb0ab9-bf23-4809-8ca5-bfad3cacbf82)

### Deploy config

![deploy build](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/assets/102387885/e382bed2-8905-41a6-a243-6ca4bcd85273)

Save the changes and ```Release change```

![success](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/assets/102387885/037fce40-dad4-4ec9-a5b4-c5c47dfd7eb4)
