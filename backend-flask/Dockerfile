FROM 487893315666.dkr.ecr.us-east-1.amazonaws.com/cruddur-python:3.10-slim-buster

#Inside Container
#make a new folder inside container
WORKDIR /backend-flask

#Outside Container -> Inside Container
#this contains the libraries we want to install to run the app
COPY requirements.txt requirements.txt

#Inside Container
#this installs the python libraries used for the app
RUN pip3 install -r requirements.txt

#Outside Container -> Inside Container
# . means everything in the current dir
# 1st period . - /backend-flask (Outside container) & 2nd period . - /backend-flask(Inside Container)
COPY . .

EXPOSE ${PORT}
ENV PYTHONUNBUFFERED=1
# python3 -m flask run --host=0.0.0.0 --port=4567
CMD [ "python3", "-m" , "flask", "run", "--host=0.0.0.0", "--port=4567", "--debug"]