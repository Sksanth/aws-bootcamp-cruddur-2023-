# Week 2 — Distributed Tracing

## Required Homework

### Distributed Tracing – Honeycomb
Create environment called Bootcamp. Copy the API key from the Honeycomb account
```
export HONEYCOMB_API_KEY =”key_value”
gp env HONEYCOMB_API_KEY =”key_value”
```
Add the environment variables to the ```docker-compose.yml``` file for the ```backend-flask```
```
OTEL_EXPORTER_OTLP_ENDPOINT: "https://api.honeycomb.io"
OTEL_EXPORTER_OTLP_HEADERS: "x-honeycomb-team=${HONEYCOMB_API_KEY}"
OTEL_SERVICE_NAME: ‘backend-flask’ 
```
Add the files to the ```backend-flask/requirments.txt``` file to instrument the backend-flask with OpenTelementry
```
opentelemetry-api 
opentelemetry-sdk 
opentelemetry-exporter-otlp-proto-http 
opentelemetry-instrumentation-flask 
opentelemetry-instrumentation-requests
```
Run the command to install the dependencies
```
pip install -r requirements.txt
```
Enter the contents to the ```backend-flask/app.py``` file
```
# Honeycomb----------
# app.py updates    
from opentelemetry import trace
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.sdk.trace.export import SimpleSpanProcessor, ConsoleSpanExporter
```
```
# Honeycomb---------
# Initialize tracing and an exporter that can send data to Honeycomb
provider = TracerProvider()
processor = BatchSpanProcessor(OTLPSpanExporter())
provider.add_span_processor(processor)

#show this in the logs within the backend-flask app  (STDOUT)
simple_processor = SimpleSpanProcessor(ConsoleSpanExporter())
provider.add_span_processor(simple_processor)

trace.set_tracer_provider(provider)
tracer = trace.get_tracer(__name__)
```

```
# HoneyComb --------
# Initialize automatic instrumentation with Flask
FlaskInstrumentor().instrument_app(app)
RequestsInstrumentor().instrument()
```
Do the docker compose up and open the ports 3000 and 4567/api/activities/home. Check everything works fine and commit the changes.   
Go to the Honeycomb and check the datasets 
 
 ![honeycombData](https://user-images.githubusercontent.com/102387885/222878718-74e06ad1-d467-4736-a389-671cb70e7fb9.png)


To the ```backend-flask /services /home_activities.py``` file add

```from opentelemetry import trace```

```tracer = trace.get_tracer("home.activities")```


![homeActivitiesTrace](https://user-images.githubusercontent.com/102387885/222879043-2e6932bc-2678-49d8-9584-63742de3b5cd.png)


#### Create Spans 
```with tracer.start_as_current_span("home-activities-mock-data"):```

![recentTraceshomeActivities](https://user-images.githubusercontent.com/102387885/222879065-015d753f-ecf9-4bf2-8710-42bf40536cad.png)



#### Add attributes to span
```span = trace.get_current_span()

span.set_attribute("app.now", now.isoformat())
```

```
span.set_attribute("app.result_length", len(results))
```



![applengthQuery](https://user-images.githubusercontent.com/102387885/222879074-a70f4ba4-438d-427a-8126-f142d850a8fa.png)


 
### Instrument AWS X-Ray and Subsegment for Flask
Create ```aws/xray.json``` file and add 
```
{
    "SamplingRule": {
        "RuleName": "Cruddur",
        "ResourceARN": "*",
        "Priority": 9000,
        "FixedRate": 0.1,
        "ReservoirSize": 5,
        "ServiceName": "backend-flask",
        "ServiceType": "*",
        "Host": "*",
        "HTTPMethod": "*",
        "URLPath": "*",
        "Version": 1
    }
  }
```
#### Create Sampling rule
```
aws xray create-sampling-rule --cli-input-json file://aws/json/xray.json
```

![samplingrule](https://user-images.githubusercontent.com/102387885/222879368-bf0ed5ff-d6fb-4273-8116-e2986a58ab70.png)

 
In the  ```backend-flask/app.py``` file add
```
# X-RAY -------------
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.ext.flask.middleware import XRayMiddleware

# X-RAY -------------
xray_url = os.getenv("AWS_XRAY_URL")
xray_recorder.configure(service='backend-flask', dynamic_naming=xray_url)
XRayMiddleware(app, xray_recorder)
```
```
aws xray create-group \
   --group-name "Cruddur" \
   --filter-expression "service(\"backend-flask\")"
```
![CloudWatchXRaytraces](https://user-images.githubusercontent.com/102387885/222879392-f080fd72-aa90-48c3-941e-e94a6f396e09.png)


#### AWS X-Ray Subsegment

``` backend-flask/services/user_activities.py``` 
Add the package
```
from aws_xray_sdk.core import xray_recorder

```
#### Set annotations and metadata
Add annotations and metadata to an active segment/subsegment
```
try:
  segment = xray_recorder.begin_segment('user_activities')
#XRay -----
       subsegment = xray_recorder.begin_subsegment('mock-data')
       dict = {
      "now": now.isoformat(),
      "results-size": len(model['data'])
    }
    subsegment.put_metadata('key', dict, 'namespace')
    #close the segment
    xray_recorder.end_subsegment()
  finally:
    #close the segment 
    xray_recorder.end_subsegment()
```


Add decorator for function auto capture to the  ```backend-flask/app.py``` file for home and user activities
```@xray_recorder.capture('activities_home')```
```@xray_recorder.capture('activities_user')```

Do docker compose up, open the ports and the the X-Ray traces in the console
 
![XRay subsegment](https://user-images.githubusercontent.com/102387885/222879460-4683f64e-51da-48d3-896f-ee578dba16ab.png)

![XRay subsegmentUseractivity](https://user-images.githubusercontent.com/102387885/222879472-46894158-d35a-4583-8785-17d74002da8c.png)

![subsegmentMockData](https://user-images.githubusercontent.com/102387885/222879476-74bf2337-9757-44ec-8657-8547dd88ef12.png)

### Configure custom logger to send to CloudWatch Logs
Add the file to the ```backend-flask/requirments.txt``` 

```watchtower```

Install 

```pip install -r requirements.txt```

To the ```backend-flask/app.py``` add 

```
import watchtower
import logging
from time import strftime
```
```
# Configuring Logger to Use CloudWatch
LOGGER = logging.getLogger(__name__)
LOGGER.setLevel(logging.DEBUG)
console_handler = logging.StreamHandler()
cw_handler = watchtower.CloudWatchLogHandler(log_group='cruddur')
LOGGER.addHandler(console_handler)
LOGGER.addHandler(cw_handler)
LOGGER.info("test log")
```
```
@app.after_request
def after_request(response):
    timestamp = strftime('[%Y-%b-%d %H:%M]')
    LOGGER.error('%s %s %s %s %s %s', timestamp, request.remote_addr, request.method, request.scheme, request.full_path, response.status)
    return response
```

To ```backend-flask/services/home_activities.py``` add 
```import logging```
```
LOGGER.info("home activities")
```
Set the environment variables in the ```docker-compose.yml``` file
```
      AWS_DEFAULT_REGION: "${AWS_DEFAULT_REGION}"
      AWS_ACCESS_KEY_ID: "${AWS_ACCESS_KEY_ID}"
      AWS_SECRET_ACCESS_KEY: "${AWS_SECRET_ACCESS_KEY}"
```
Do the docker compose up and open the ports to send the data’s to the CloudWatch logs

Check the CloudWatch logs in the console

![cloudwatchlogs](https://user-images.githubusercontent.com/102387885/222879532-d2c6724f-9a6c-4308-adaf-60c91e57d022.png)
 
![logstream](https://user-images.githubusercontent.com/102387885/222879570-b1322556-e896-42d6-8d76-2e879025959f.png)

### Rollbar for Error Logging and Tracing
Add the files to the ```blackend-flask/requirements.txt``` file 

```
blinker
rollbar
```

Run the command to install the packages 

``` pip install -r requirements.txt```

Copy the access token from the Rollbar account and set the environment variables 

```
export ROLLBAR_ACCESS_TOKEN="21a0fb439b67431aac56e2884f5f52df"
gp env ROLLBAR_ACCESS_TOKEN="21a0fb439b67431aac56e2884f5f52df"
```

Add to the ```backend-flask/app.py``` file

```
import rollbar
import rollbar.contrib.flask
from flask import got_request_exception
```

```
rollbar_access_token = os.getenv('ROLLBAR_ACCESS_TOKEN')
@app.before_first_request
def init_rollbar():
    """init rollbar module"""
    rollbar.init(
        # access token
        rollbar_access_token,
        # environment name
        'production',
        # server root directory, makes tracebacks prettier
        root=os.path.dirname(os.path.realpath(__file__)),
        # flask already sets up logging
        allow_logging_basic_config=False)

    # send exceptions from `app` to rollbar, using flask's signal system.
    got_request_exception.connect(rollbar.contrib.flask.report_exception, app)
```
```
@app.route('/rollbar/test')
def rollbar_test():
    rollbar.report_message('Hello World!', 'warning')
    return "Hello World!"
```

To access the environment variables add the below code to the ```docker-compose.yml``` file 

```
ROLLBAR_ACCESS_TOKEN: "${ROLLBAR_ACCESS_TOKEN}"
```

Do docker compose up
Open the port 4567 /api/activities/home or new endpoint rollbar/test
Go to the Rollbar to check the events
 
![rollbarTraces](https://user-images.githubusercontent.com/102387885/222879648-471dc74e-9773-41de-aa10-f61f30afcfd0.png)


### To Unlock the ports by default
```gitpod.yml```
```
ports:
  - name: frontend
    port: 3000
    onOpen: open-browser
    visibility: public
  - name: backend
    port: 4567
    visibility: public
  - name: xray-daemon
    port: 2000
    visibility: public
```

### Files in the codebase

[Instrument Flask app - requirements.txt]( https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/backend-flask/requirements.txt)

[Honeycomb, X-Ray, - app.py]( https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/backend-flask/app.py)

[aws/json/xray.json](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/aws/json/xray.json)

[Add Rollbar to docker-compose.yml]( https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/docker-compose.yml)

[home_activities.py](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/backend-flask/services/home_activities.py)

[user_activities.py]( https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/backend-flask/services/user_activities.py)

[Add additional ports to gitpod.yml](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/main/.gitpod.yml)
