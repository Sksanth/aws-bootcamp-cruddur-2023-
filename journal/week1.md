# Week 1 — App Containerization

## Required Homework

### Dockerizing the Backend

#### Creating a dockerfile

Created a dockerfile in the backend folder ``` backend-flask/Dockerfile ``` and it contains the following code
```
FROM python:3.10-slim-buster

WORKDIR /backend-flask

COPY requirements.txt requirements.txt
RUN pip3 install -r requirements.txt

COPY . .

ENV FLASK_ENV=development

EXPOSE ${PORT}
CMD [ "python3", "-m" , "flask", "run", "--host=0.0.0.0", "--port=4567"]
```
We have two environment variables in our backend called FRONTEND and BACKEND. Without these variables the link for port 4567 returned error. 
 
![Internal server error](https://user-images.githubusercontent.com/102387885/221339634-d11566af-4ad3-4624-adc8-a3552310c491.png)

#### Run Python
To set the environment variables, execute the below commands
```
cd backend-flask
export FRONTEND_URL="*"
export BACKEND_URL="*"
python3 -m flask run --host=0.0.0.0 --port=4567
cd ..
```
Now the link for 4567 works without any error
 

![step10](https://user-images.githubusercontent.com/102387885/221339652-7dcaf2ab-cd35-4124-abc8-a7e489af0d63.png)

#### Docker Image
To build the docker image execute the command 
```
docker build -t  backend-flask ./backend-flask
```

The docker files for both backend-flask and python(3.10-slim-buster) has been saved on my docker under images tab
#### Run Container
To run the container executed the command
```
docker run --rm -p 4567:4567 -it backend-flask
```
It failed to run the docker since the env vars has not been set so checked it using the command 
```
Docker exec -it backend-flask bash 
(It’s same as selecting the “Attach shell” of the container)

$ env
```

After stopping the running container, executed the run command with the environment variables
```
docker run --rm -p 4567:4567 -it -e FRONTEND_URL='*' -e BACKEND_URL='*' backend-flask
```
Now go to URL for port 4567 and it works. Add  ```/api/activities/home``` at the end of the URL


![step19 result](https://user-images.githubusercontent.com/102387885/221339720-90d953b8-5d5d-47ab-b44a-9697410ec36f.png)

To get the docker ids and images, run the commands
```
Docker ps
Docker images
```
To run the container in the background
```
docker container run --rm -p 4567:4567 -d backend-flask
```

### Dockerizing the Frontend
#### NPM install
Install the npm before building the Frontend container to copy the contents of node_modules
```
to copy the contents of node_modules
```
#### Creating a dockerfile
Create a dockerfile in the backend folder ``` frontend-react-js/Dockerfile ``` and it contains the following code
```
FROM node:16.18

ENV PORT=3000

COPY . /frontend-react-js
WORKDIR /frontend-react-js
RUN npm install
EXPOSE ${PORT}
CMD ["npm", "start"]
```
To build the frontend container image
```
docker build -t frontend-react-js ./frontend-react-js
```
To run the container
```
docker run -p 3000:3000 -d frontend-react-js
```

### Create a docker-compose file
Create a new file ```docker-compose.yml``` in project’s root folder to run everything at once. The docker compose tells docker which services to start and also sets the env vars.
```
version: "3.8"
services:
  backend-flask:
    environment:
      FRONTEND_URL: "https://3000-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
      BACKEND_URL: "https://4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
    build: ./backend-flask
    ports:
      - "4567:4567"
    volumes:
      - ./backend-flask:/backend-flask
  frontend-react-js:
    environment:
      REACT_APP_BACKEND_URL: "https://4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
    build: ./frontend-react-js
    ports:
      - "3000:3000"
    volumes:
      - ./frontend-react-js:/frontend-react-js

# the name flag is a hack to change the default prepend folder
# name when outputting the image names
networks: 
  internal-network:
    driver: bridge
    name: cruddur
```
To build and run the app
```
docker compose up
```
Check the link for port 3000


![cruddur](https://user-images.githubusercontent.com/102387885/221341609-36224669-871a-4e55-926e-b248454ec52c.png)

Commit the changes and then push the codes to Github

### Create the Notification feature (Frontend & Backend)
Open the file ```backend-flask/openapi-3.0.yml```
Go to the ```api``` and select the ``` openAPI: add new path``` on the PATH tab
Change the name to ```/api/activities/notification``` on the file and entered the contents
```
/api/activities/notifications:
    get:
      description: 'Return a feed of activity for all of those that I follow'
      tags:
        - activities
      parameters: []
      responses:
        '200':
          description: Returns an array of activities
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/Activity'
```
Commit the changes to the Git repo

To define the new notifications endpoint add the codes to the ``` backend-flask/app.py```
```
from services.notifications_activities import *

@app.route("/api/activities/notifications", methods=['GET'])
def data_home():
  data = NotificationsActivities.run()
  return data, 200
```
Open a new file ```backend-flasks/services/ notifications_activities.py’ ``` enter the contents
```
from datetime import datetime, timedelta, timezone
class NotificationsActivities:
  def run():
    now = datetime.now(timezone.utc).astimezone()
    results = [{
      'uuid': '68f126b0-1ceb-4a33-88be-d90fa7109eee',
      'handle':  'KimTae',
      'message': 'Borahae!',
      'created_at': (now - timedelta(days=2)).isoformat(),
      'expires_at': (now + timedelta(days=5)).isoformat(),
      'likes_count': 5,
      'replies_count': 1,
      'reposts_count': 0,
      'replies': [{
        'uuid': '26e12864-1c26-5c3a-9658-97a10f8fea67',
        'reply_to_activity_uuid': '68f126b0-1ceb-4a33-88be-d90fa7109eee',
        'handle':  'Worf',
        'message': 'This post has no honor!',
        'likes_count': 0,
        'replies_count': 0,
        'reposts_count': 0,
        'created_at': (now - timedelta(days=2)).isoformat()
      }],
    }
    ]
    return results
```
Open the port 3000 and see the changes

![week1Notification](https://user-images.githubusercontent.com/102387885/222880854-0d781168-4d8d-4b00-98d5-dcd60592b196.png)


### DynamoDB and Postgresql
Open the ```docker-compose.yml``` file and enter the contents for DynamoDB and Postgresql
```
services:
dynamodb-local:
    # https://stackoverflow.com/questions/67533058/persist-local-dynamodb-data-in-volumes-lack-permission-unable-to-open-databa
    # We needed to add user:root to get this working.
    user: root
    command: "-jar DynamoDBLocal.jar -sharedDb -dbPath ./data"
    image: "amazon/dynamodb-local:latest"
    container_name: dynamodb-local
    ports:
      - "8000:8000"
    volumes:
      - "./docker/dynamodb:/home/dynamodblocal/data"
    working_dir: /home/dynamodblocal
        db:
         image: postgres:13-alpine
         restart: always
         environment:
           - POSTGRES_USER=postgres
           - POSTGRES_PASSWORD=password
         ports:
           - '5432:5432'
         volumes: 
           - db:/var/lib/postgresql/data
volumes:
  db:
    driver: local
```
#### Create Table
Run the commands to create a table
```
aws dynamodb create-table \
    --endpoint-url http://localhost:8000 \
    --table-name Music \
    --attribute-definitions \
        AttributeName=Artist,AttributeType=S \
        AttributeName=SongTitle,AttributeType=S \
    --key-schema AttributeName=Artist,KeyType=HASH AttributeName=SongTitle,KeyType=RANGE \
    --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
    --table-class STANDARD
```
#### Create an Item
```
 aws dynamodb put-item \
    --endpoint-url http://localhost:8000 \
    --table-name Music \
    --item \
        '{"Artist": {"S": "No One You Know"}, "SongTitle": {"S": "Call Me Today"}, "AlbumTitle": {"S": "Somewhat Famous"}}' \
    --return-consumed-capacity TOTAL  
```

#### List Tables
```
aws dynamodb list-tables --endpoint-url http://localhost:8000
```

#### Get Records
```
aws dynamodb scan --table-name Music --query "Items" --endpoint-url http://localhost:8000
```

Open the ```gitpod.yml``` file and enter the codes 
```
- name: postgres
  init: |
      curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc|sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
      echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" |sudo tee  /etc/apt/sources.list.d/pgdg.list
      sudo apt update
      sudo apt install -y postgresql-client-13 libpq-dev
```
   
#### Run Postgresql server in docker
```
psql -h localhost -U postgres
```

### Files in the codebase

[backend-flask/Dockerfile](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/backend-flask/Dockerfile)


[]()
[frontend-react-js/Dockerfile]( https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/frontend-react-js/Dockerfile)

[docker-compose.yml]( https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/docker-compose.yml)

[openapi-3.0.yml]( https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/backend-flask/openapi-3.0.yml)

[app.py](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/backend-flask/app.py)

[notifications_activities.py](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/backend-flask/services/notifications_activities.py)



## Homework Challenges
### Docker on local machine
Install the docker

![DDinstall](https://user-images.githubusercontent.com/102387885/221345224-38c38f6c-000d-45fc-8cea-f8fda0cfb1ca.png)


#### Hello-World
**Failed** to run 
```
docker run hello-world
```
It returned the error
```
docker: Got permission denied while trying to connect to the Docker daemon socket
```

Fixed it by changing the permissions with the command
```
Sudo chmod 666 /var/run/docker.sock
```

![dockerPermissionDenied fixed](https://user-images.githubusercontent.com/102387885/221345254-819b538c-4908-4326-948e-35d1c9d771fd.png)

#### nginx:latest

![nginxPortBinding](https://user-images.githubusercontent.com/102387885/221346349-f57e1574-357a-412d-854e-bea564bc7ba2.png)

### Dockerfile CMD as an external script

![cmdOSthegitpod](https://user-images.githubusercontent.com/102387885/221345373-a3ffae9b-aa8d-4e6c-a552-31c722124b91.png)


