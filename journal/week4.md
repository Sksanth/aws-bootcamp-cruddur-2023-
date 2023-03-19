# Week 4 — Postgres and RDS
## Required Homework
### Provision RDS Instance
Execute the command
```
aws rds create-db-instance \
  --db-instance-identifier cruddur-db-instance \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version  14.6 \
  --master-username cruddurroot \
  --master-user-password ******** \
  --allocated-storage 20 \
  --availability-zone us-east-1a \
  --backup-retention-period 0 \
  --port 5432 \
  --no-multi-az \
  --db-name cruddur \
  --storage-type gp2 \
  --publicly-accessible \
  --storage-encrypted \
  --enable-performance-insights \
  --performance-insights-retention-period 7 \
  --no-deletion-protection
```
![rds1stimage](https://user-images.githubusercontent.com/102387885/226108729-ce4ff71d-ec38-4c22-bb8b-142e8fe4b91b.png)

Check the AWS RDS console for the database and stop 

To connect the psql client
```psql -Upostgres --host localhost```

### Create a database
Execute the command ```create database cruddur;``` to create database

### Create Schema
In the ```backend-flask``` app create a new folder ```db``` and a file ```schema.sql```
To add the UUID Extension
```
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```
```psql cruddur < db/schema.sql -h localhost -U postgres```
```psql postgresql://postgres:password@localhost:5432/cruddur```

```
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- forcefully drop our tables if they already exist
DROP TABLE IF EXISTS public.users;
DROP TABLE IF EXISTS public.activities;

CREATE TABLE public.users (
  uuid UUID default uuid_generate_v4() primary key,
  display_name text NOT NULL,
  handle text NOT NULL,
  email text NOT NULL,
  cognito_user_id text NOT NULL,
  created_at timestamp default current_timestamp NOT NULL
);

CREATE TABLE public.activities (
  uuid UUID default uuid_generate_v4() primary key,
  user_uuid UUID NOT NULL,
  message text NOT NULL,
  replies_count integer default 0,
  reposts_count integer default 0,
  likes_count integer default 0,
  reply_to_activity_uuid integer,
  expires_at timestamp,
  created_at timestamp default current_timestamp NOT NULL
);
```
And ```db/seed.sql```
```
-- this file was manually created
INSERT INTO public.users (display_name, email, handle, cognito_user_id)
VALUES
  ('Sasi', 'sasi@email.com', 'sasi' ,'MOCK'),
  ('sasi thv', 'thvsasi@gmail.com', 'thv' ,'MOCK');

INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'sasi' LIMIT 1),
    'This was imported as seed data!',
    current_timestamp + interval '10 day'
  )
  ```
  
  

### Bash Scripts for Database Operations

Export the connection_url variable
```
export CONNECTION_URL="postgresql://postgres:password@localhost:5432/cruddur"
gp env CONNECTION_URL="postgresql://postgres:password@localhost:5432/cruddur"
```

Create a folder called ```bin``` and create the files 
```db-create``` to create a database
```
#! /usr/bin/bash

#echo "== db-create"
CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-create"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

NO_DB_CONNECTION_URL=$(sed 's/\/cruddur//g' <<<"$CONNECTION_URL")
psql $NO_DB_CONNECTION_URL -c "CREATE database cruddur;"
```
```db-connect```
```
#! /usr/bin/bash

if [ "$1" = "prod" ]; then
  echo "Running in production mode"
  URL=$PROD_CONNECTION_URL
else
  URL=$CONNECTION_URL
fi

psql $URL
```

```db-drop```
```
#! /usr/bin/bash

#echo "== db-drop"
CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-drop"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

NO_DB_CONNECTION_URL=$(sed 's/\/cruddur//g' <<<"$CONNECTION_URL")
psql $NO_DB_CONNECTION_URL -c "drop database cruddur;"
# psql $CONNECTION_URL -c "drop database cruddur;"
```
```db-schema-load```
```
#! /usr/bin/bash

#echo "== db-schema-load"
CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-schema-load"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

schema_path="$(realpath .)/db/schema.sql"

echo $schema_path

if [ "$1" = "prod" ]; then
  echo "Running in production mode"
  URL=$PROD_CONNECTION_URL
else
  URL=$CONNECTION_URL
fi

psql $URL cruddur < $schema_path
```
```db-seed```
```
#! /usr/bin/bash

#echo "== db-seed"
CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-seed"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

seed_path="$(realpath .)/db/seed.sql"
echo $seed_path

if [ "$1" = "prod" ]; then
  echo "Running in production mode"
  URL=$PROD_CONNECTION_URL
else
  URL=$CONNECTION_URL
fi

psql $URL cruddur < $seed_path
```
```db-sessions```
```
#! /usr/bin/bash

#echo "== db-sessions"
CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-sessions"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

if [ "$1" = "prod" ]; then
  echo "Running in production mode"
  URL=$PROD_CONNECTION_URL
else
  URL=$CONNECTION_URL
fi

NO_DB_URL=$(sed 's/\/cruddur//g' <<<"$CONNECTION_URL")
psql $NO_DB_URL -c "select pid as process_id, \
       usename as user,  \
       datname as db, \
       client_addr, \
       application_name as app,\
       state \
from pg_stat_activity;"
```
```db-setup```
```
#! /usr/bin/bash
-e # stop if it fails at any point

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-setup"
printf "${CYAN}==== ${LABEL}${NO_COLOR}\n"

bin_path="$(realpath .)/bin"

source "$bin_path/db-drop"
source "$bin_path/db-create"
source "$bin_path/db-schema-load"
source "$bin_path/db-seed"
```
```rds-update-sg-rule```
```
#! /usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="rds-update-sg-rule"
printf "${CYAN}==== ${LABEL}${NO_COLOR}\n"

aws ec2 modify-security-group-rules \
    --group-id $DB_SG_ID \
    --security-group-rules "SecurityGroupRuleId=$DB_SG_RULE_ID,SecurityGroupRule={Description=GITPOD,IpProtocol=tcp,FromPort=5432,ToPort=5432,CidrIpv4=$GITPOD_IP/32}"
```
### Install Postgres client    
In the ```docker-compose.yml``` file add the env vars for the ```backend-flask```
```
CONNECTION_URL: "postgresql://postgres:password@localhost:5432/cruddur"
```
In the ```requiremnts.txt``` add
```
psycopg[binary]
psycopg[pool]
```

```pip install -r requirements.txt```

Create ```db.py``` file under lib folder to create connection pool

```
from psycopg_pool import ConnectionPool
import os

def query_wrap_object(template):
  sql = f"""
  (SELECT COALESCE(row_to_json(object_row),'{{}}'::json) FROM (
  {template}
  ) object_row);
  """
  return sql

def query_wrap_array(template):
  sql = f"""
  (SELECT COALESCE(array_to_json(array_agg(row_to_json(array_row))),'[]'::json) FROM (
  {template}
  ) array_row);
  """
  return sql

connection_url = os.getenv("CONNECTION_URL")
pool = ConnectionPool(connection_url)

```

Update the ```home_activities.py ``` file with real api call
```
from lib.db import pool, query_wrap_array


    sql = query_wrap_array("""
      SELECT * FROM activities
    """)
    print("SQL--------------")
    print(sql)
    print("SQL--------------")
    with pool.connection() as conn:
      with conn.cursor() as cur:
        cur.execute(sql)
        # this will return a tuple
        # the first field being the data
        json = cur.fetchone()
    print("-1----")
    print(json[0])
    return json[0]
    return results
```
![query working commit47](https://user-images.githubusercontent.com/102387885/226112871-0c3116ed-a2bc-4d9e-855f-89f8c81ce670.png)

### To establish connection to the RDS database
Update the CONNECTION_URL for the production in the ```docker-compose.yml``` file
```
CONNECTION_URL: "${PROD_CONNECTION_URL}"
```
```
export PROD_CONNECTION_URL="postgresql://cruddurroot:*******@cruddur-db-instance.ca9jvkweb7dt.us-east-1.rds.amazonaws.com:5432/cruddur"
gp env PROD_CONNECTION_URL="postgresql://cruddurroot:*******@cruddur-db-instance.ca9jvkweb7dt.us-east-1.rds.amazonaws.com:5432/cruddur"
```
    
In the ```gitpod.yml``` file and enter the command to create an inbound rule for the postgres 
```
    command: |
      export GITPOD_IP=$(curl ifconfig.me)
      source  "$THEIA_WORKSPACE_ROOT/backend-flask/bin/rds-update-sg-rule"
```
Export the security group ID and rule ID
```
export DB_SG_ID="sg-099df6712a7d76476"
gp env DB_SG_ID="sg-099df6712a7d76476"

export DB_SG_RULE_ID="sgr-0d74d5cca57n815ba"
gp env DB_SG_RULE_ID="sgr-0d74d5cca57n815ba"
```
```
aws ec2 modify-security-group-rules \
    --group-id $DB_SG_ID \
    --security-group-rules "SecurityGroupRuleId=$DB_SG_RULE_ID,SecurityGroupRule={Description=GITPOD,IpProtocol=tcp,FromPort=5432,ToPort=5432,CidrIpv4=$GITPOD_IP/32}"
```
```
export GITPOD_IP=$(curl ifconfig.me)
```



### Setup Post Confirmation Lambda
create a ```aws/lambdas``` folder and ```cruddur-post-confirrmation.py ``` file
Create a Lambda function in the AWS console and add the function

```
import json
import psycopg2
import os

def lambda_handler(event, context):
    user = event['request']['userAttributes']
    print('userAttributes')
    print(user)

    user_display_name  = user['name']
    user_email         = user['email']
    user_handle        = user['preferred_username']
    user_cognito_id    = user['sub']
    try:
      print('entered-try')
      sql = f"""
         INSERT INTO public.users (
          display_name, 
          email,
          handle, 
          cognito_user_id
          ) 
        VALUES(
          '{user_display_name}', 
          '{user_email}', 
          '{user_handle}', 
          '{user_cognito_id}'
        )
      """
      print('SQL Statement ----')
      print(sql)
      conn = psycopg2.connect(os.getenv('CONNECTION_URL'))
      cur = conn.cursor()
      cur.execute(sql)
      conn.commit() 

    except (Exception, psycopg2.DatabaseError) as error:
      print(error)
    finally:
      if conn is not None:
          cur.close()
          conn.close()
          print('Database connection closed.')
    return event
```

Create a custom policy ```AWSLamdaVPCAccessExecutionRole```  
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeNetworkInterfaces",
                "ec2:CreateNetworkInterface",
                "ec2:DeleteNetworkInterface",
                "ec2:AttachNetworkInterface",
                "ec2:DescribeInstances"
            ],
            "Resource": "*"
        }
    ]
}
```

### Implement Activities

Modify the ```create_activity.py``` file

``` from lib.db import db  ```

```
    expires_at = (now + ttl_offset)
      uuid = CreateActivity.create_activity(user_handle,message,expires_at)

      object_json = CreateActivity.query_object_activity(uuid)
      model['data'] = object_json
```

```
  def create_activity(handle, message, expires_at):
    sql = db.template('activities','create')
    uuid = db.query_commit(sql,{
      'handle': handle,
      'message': message,
      'expires_at': expires_at
    })
    return uuid
  def query_object_activity(uuid):
    sql = db.template('activities','object')
    return db.query_object_json(sql,{
      'uuid': uuid
    })
```

And ```db.py```
```
import re
import sys
from flask import current_app as app


  def template(self,*args):
    pathing = list((app.root_path,'db','sql',) + args)
    pathing[-1] = pathing[-1] + ".sql"

    template_path = os.path.join(*pathing)

    green = '\033[92m'
    no_color = '\033[0m'
    print("\n")
    print(f'{green} Load SQL Template: {template_path} {no_color}')

    with open(template_path, 'r') as f:
      template_content = f.read()
    return template_content


  # be sure to check for RETURNING in all uppercases
  def print_params(self,params):
    blue = '\033[94m'
    no_color = '\033[0m'
    print(f'{blue} SQL Params:{no_color}')
    for key, value in params.items():
      print(key, ":", value)

  def print_sql(self,title,sql):
    cyan = '\033[96m'
    no_color = '\033[0m'
    print(f'{cyan} SQL STATEMENT-[{title}]------{no_color}')
    print(sql)
  def query_commit(self,sql,params={}):
    self.print_sql('commit with returning',sql)

    pattern = r"\bRETURNING\b"
    is_returning_id = re.search(pattern, sql)


      with self.pool.connection() as conn:
        cur =  conn.cursor()
        cur.execute(sql,params)
        if is_returning_id:
          returning_id = cur.fetchone()[0]
        conn.commit() 
        if is_returning_id:
          return returning_id



  def query_array_json(self,sql,params={}):
    self.print_sql('array',sql)


        cur.execute(wrapped_sql,params)

  def query_object_json(self,sql,params={}):

    self.print_sql('json',sql)
    self.print_params(params)

       cur.execute(wrapped_sql,params)

        if json == None:
          "{}"
        else:
          return json[0]
```

Create a SQL activity folder ```db/sql/actvities``` and files
```create.sql```
```
INSERT INTO public.activities (
  user_uuid,
  message,
  expires_at
)
VALUES (
  (SELECT uuid 
    FROM public.users 
    WHERE users.handle = %(handle)s
    LIMIT 1
  ),
  %(message)s,
  %(expires_at)s
) RETURNING uuid;
```

```object.sql```
```
SELECT
  activities.uuid,
  users.display_name,
  users.handle,
  activities.message,
  activities.created_at,
  activities.expires_at
FROM public.activities
INNER JOIN public.users ON users.uuid = activities.user_uuid 
WHERE 
  activities.uuid = %(uuid)s
```

```home.sql```
```
SELECT
  activities.uuid,
  users.display_name,
  users.handle,
  activities.message,
  activities.replies_count,
  activities.reposts_count,
  activities.likes_count,
  activities.reply_to_activity_uuid,
  activities.expires_at,
  activities.created_at
FROM public.activities
LEFT JOIN public.users ON users.uuid = activities.user_uuid
ORDER BY activities.created_at DESC
```
![createUser activity success](https://user-images.githubusercontent.com/102387885/226194854-fc69c595-ee1b-491d-93bf-45038d72b9ac.png)

    
### File in the codebase
[seed.sql](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/backend-flask/db/seed.sql)

[schema.sql ](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/backend-flask/db/schema.sql)

[db-connect](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/backend-flask/bin/db-connect)

[db-create](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/backend-flask/bin/db-create)

[db-drop](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/backend-flask/bin/db-drop)

[db-schema-load](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/backend-flask/bin/db-schema-load)

[db-seed](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/backend-flask/bin/db-seed)

[db-sessions](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/backend-flask/bin/db-sessions)

[db-setup](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/backend-flask/bin/db-setup)

[rds-update-sg-rule](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/backend-flask/bin/rds-update-sg-rule)

[db.py](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/backend-flask/lib/db.py)

[cruddur-post-confirmation](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/aws/lambdas/cruddur-post-confirrmation.py)

[create.sql](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/backend-flask/db/sql/activities/create.sql)

[home.sql](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/backend-flask/db/sql/activities/home.sql)

[object.sql](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/backend-flask/db/sql/activities/object.sql)


