# Week 3 — Decentralized Authentication
## Required Homework
### Create Amazon Cognito User Pool
User pools for sign-up and sign-in services
 ![setup CognitoUserpool](https://user-images.githubusercontent.com/102387885/224463427-eadc54c7-f83f-415f-b55e-e0d77ff98497.png)

### Frontend implementation for Cognito
#### Install AWS Amplify
Install AWS amplify and save it in the frontend directory
```
npm i aws-amplify –save
```
### Configure Amplify
Import the config file to ‘’’frontend-react-js/src/
app.js``` file

```
import { Amplify } from 'aws-amplify';


Amplify.configure({
  "AWS_PROJECT_REGION": process.env.REACT_APP_AWS_PROJECT_REGION,
  "aws_cognito_region": process.env.REACT_APP_AWS_COGNITO_REGION,
  "aws_user_pools_id": process.env.REACT_APP_AWS_USER_POOLS_ID,
  "aws_user_pools_web_client_id": process.env.REACT_APP_CLIENT_ID,
  "oauth": {},
  Auth: {
    // We are not using an Identity Pool
    region: process.env.REACT_APP_AWS_PROJECT_REGION,           // REQUIRED - Amazon Cognito Region
    userPoolId: process.env.REACT_APP_AWS_USER_POOLS_ID,         // OPTIONAL - Amazon Cognito User Pool ID
    userPoolWebClientId: process.env.REACT_APP__CLIENT_ID,   // OPTIONAL - Amazon Cognito Web Client ID (26-char alphanumeric string)
  }
});
```

Add the environment variables to the ```docker-compose.yml``` file for the frontend application
```
REACT_APP_AWS_PROJECT_REGION: "${AWS_DEFAULT_REGION}"
 REACT_APP_AWS_COGNITO_REGION: "${AWS_DEFAULT_REGION}"
 REACT_APP_AWS_USER_POOLS_ID: " us-east-1_*********"
 REACT_APP_CLIENT_ID: " ***************************"
```

In the ```frontend-react.js/src/pages/HomeFeedPage.js``` file add
```
import { Auth } from 'aws-amplify';
```

```
const checkAuth = async () => {
  Auth.currentAuthenticatedUser({
    // Optional, By default is false. 
    // If set to true, this call will send a 
    // request to Cognito to get the latest user data
    bypassCache: false 
  })
  .then((user) => {
    console.log('user',user);
    return Auth.currentAuthenticatedUser()
  }).then((cognito_user) => {
      setUser({
        display_name: cognito_user.attributes.name,
        handle: cognito_user.attributes.preferred_username
      })
  })
  .catch((err) => console.log(err));
};
```

In the ```frontend-react.js/src/pages/ProfileInfo.js``` file add
```
import { Auth } from 'aws-amplify';
```
And update the signOut function
```
const signOut = async () => {
  try {
      await Auth.signOut({ global: true });
      window.location.href = "/"
  } catch (error) {
      console.log('error signing out: ', error);
  }
}
```

#### Implement Custom Signin Page
Go to the ```frontend-react.js/src/pages/SigninPage.js ``` file add
```
import { Auth } from 'aws-amplify';
```
And update 
```
  const onsubmit = async (event) => {
    setErrors('')
    event.preventDefault();
    Auth.signIn(email, password)
      .then(user => {
        localStorage.setItem("access_token", user.signInUserSession.accessToken.jwtToken)
        window.location.href = "/"
      })
      .catch(error => { 
        if (error.code == 'UserNotConfirmedException') {
          window.location.href = "/confirm"
        }
        setErrors(error.message)

      });
    
    return false
  }
```

Docker compose up and check the 3000 port. The signin parameter was wrong so got the **username is not defined** error
![okwhatsthe errorUserNmaeisnot](https://user-images.githubusercontent.com/102387885/224463498-caaa390c-a233-46ea-b499-60cb36e92122.png)
 
In the Amazon Cognito console create user manually with the User name and Email address and run the command 
```
aws cognito-idp admin-set-user-password --username sksanth --password ******12345 --user-pool-id us-east-1_******** –permanent
```
![user confirmation](https://user-images.githubusercontent.com/102387885/224463539-1f129a7e-868f-455a-b25c-d83bda2cc84e.png)

![signedIn](https://user-images.githubusercontent.com/102387885/224463602-d581e24f-7a1c-4c94-a647-1d322e11489a.png)

#### Implement Custom Signup Page
Delete the manually created user and go to the ```frontend-react.js/src/pages/SignupPage.js ``` file add
```
import { Auth } from 'aws-amplify';
```
And update
``` 
const onsubmit = async (event) => {
  event.preventDefault();
  setErrors('')
  try {
      const { user } = await Auth.signUp({
        username: email,
        password: password,
        attributes: {
            name: name,
            email: email,
            preferred_username: username,
        },
        autoSignIn: { // optional - enables auto sign in after user is confirmed
            enabled: true,
        }
      });
      console.log(user);
      window.location.href = `/confirm?email=${email}`
  } catch (error) {
      console.log(error);
      setErrors(error.message)
  }
  return false
}
```

#### Implement Custom Confirmation Page
Go to ```frontend-react.js/src/pages/ConfirmationPage.js``` file and add
```
import { Auth } from 'aws-amplify';
```

```
const resend_code = async (event) => {
  setErrors('')
  try {
    await Auth.resendSignUp(email);
    console.log('code resent successfully');
    setCodeSent(true)
  } catch (err) {
    // does not return a code
    // does cognito always return english
    // for this to be an okay match?
    console.log(err)
    if (err.message == 'Username cannot be empty'){
      setErrors("You need to provide an email in order to send Resend Activiation Code")   
    } else if (err.message == "Username/client id combination not found."){
      setErrors("Email is invalid or cannot be found.")   
    }
  }
}


const onsubmit = async (event) => {
  event.preventDefault();
  setErrors('')
  try {
    await Auth.confirmSignUp(email, code);
    window.location.href = "/"
  } catch (error) {
    setErrors(error.message)
  }
  return false
}

```
Sign up to create a new Cruddur user account and enter the confirmation code sent from Cognito to the given email address to confirm the email
![confirmationpage](https://user-images.githubusercontent.com/102387885/224463656-0cd75926-f391-4ed6-ac6f-a3c129481bef.png)

Sign-in after the verification
 ![sigupSuccess](https://user-images.githubusercontent.com/102387885/224463701-450ca2b9-f19c-4826-b078-796ef2746c14.png)

#### Implement Custom Recovery Page
Go to the ```frontend-react.js/src/pages/RecoveryPage.js``` file and add
```
import { Auth } from 'aws-amplify';
```
```
const onsubmit_send_code = async (event) => {
  event.preventDefault();
  setErrors('')
  Auth.forgotPassword(username)
  .then((data) => setFormState('confirm_code') )
  .catch((err) => setErrors(err.message) );
  return false
}


const onsubmit_confirm_code = async (event) => {
  event.preventDefault();
  setErrors('')
  if (password == passwordAgain){
    Auth.forgotPasswordSubmit(username, code, password)
    .then((data) => setFormState('success'))
    .catch((err) => setErrors(err.message) );
  } else {
    setCognitoErrors('Passwords do not match')
  }
  return false
}
```
![password reset](https://user-images.githubusercontent.com/102387885/224463719-74b98d3c-1301-46cf-abdd-3b1dc992decb.png)


### Cognito JWT(JSON Web Token) 
### Backend implementation for Cognito
Go to the ```frontend-react-js/src/pages/Homefeedpage.js``` and add the headers 
```
  headers: {
    Authorization: `Bearer ${localStorage.getItem("access_token")}`
  },
```
To the ```frontend-react-js/src/components/profileinfo.js``` enter
```localStorage.removeItem("access_token")```

In the ```backend-flask/requirements.txt``` add 

```Flask-AWSCognito```

And run the command

```pip install -r requirements.txt```

In the ```docker-compose.yml``` file set the env vars
```
AWS_COGNITO_USER_POOL_ID: "*******"
AWS_COGNITO_USER_POOL_CLIENT_ID: "********"
```
Create a folder called ```lib``` and create a file ```cognito_jwt_token.py``` and enter the codes
```
import time
import requests
from jose import jwk, jwt
from jose.exceptions import JOSEError
from jose.utils import base64url_decode

class FlaskAWSCognitoError(Exception):
  pass

class TokenVerifyError(Exception):
  pass

def extract_access_token(request_headers):
    access_token = None
    auth_header = request_headers.get("Authorization")
    if auth_header and " " in auth_header:
        _, access_token = auth_header.split()
    return access_token

class CognitoJwtToken:
    def __init__(self, user_pool_id, user_pool_client_id, region, request_client=None):
        self.region = region
        if not self.region:
            raise FlaskAWSCognitoError("No AWS region provided")
        self.user_pool_id = user_pool_id
        self.user_pool_client_id = user_pool_client_id
        self.claims = None
        if not request_client:
            self.request_client = requests.get
        else:
            self.request_client = request_client
        self._load_jwk_keys()


    def _load_jwk_keys(self):
        keys_url = f"https://cognito-idp.{self.region}.amazonaws.com/{self.user_pool_id}/.well-known/jwks.json"
        try:
            response = self.request_client(keys_url)
            self.jwk_keys = response.json()["keys"]
        except requests.exceptions.RequestException as e:
            raise FlaskAWSCognitoError(str(e)) from e

    @staticmethod
    def _extract_headers(token):
        try:
            headers = jwt.get_unverified_headers(token)
            return headers
        except JOSEError as e:
            raise TokenVerifyError(str(e)) from e

    def _find_pkey(self, headers):
        kid = headers["kid"]
        # search for the kid in the downloaded public keys
        key_index = -1
        for i in range(len(self.jwk_keys)):
            if kid == self.jwk_keys[i]["kid"]:
                key_index = i
                break
        if key_index == -1:
            raise TokenVerifyError("Public key not found in jwks.json")
        return self.jwk_keys[key_index]

    @staticmethod
    def _verify_signature(token, pkey_data):
        try:
            # construct the public key
            public_key = jwk.construct(pkey_data)
        except JOSEError as e:
            raise TokenVerifyError(str(e)) from e
        # get the last two sections of the token,
        # message and signature (encoded in base64)
        message, encoded_signature = str(token).rsplit(".", 1)
        # decode the signature
        decoded_signature = base64url_decode(encoded_signature.encode("utf-8"))
        # verify the signature
        if not public_key.verify(message.encode("utf8"), decoded_signature):
            raise TokenVerifyError("Signature verification failed")

    @staticmethod
    def _extract_claims(token):
        try:
            claims = jwt.get_unverified_claims(token)
            return claims
        except JOSEError as e:
            raise TokenVerifyError(str(e)) from e

    @staticmethod
    def _check_expiration(claims, current_time):
        if not current_time:
            current_time = time.time()
        if current_time > claims["exp"]:
            raise TokenVerifyError("Token is expired")  # probably another exception

    def _check_audience(self, claims):
        # and the Audience  (use claims['client_id'] if verifying an access token)
        audience = claims["aud"] if "aud" in claims else claims["client_id"]
        if audience != self.user_pool_client_id:
            raise TokenVerifyError("Token was not issued for this audience")

    def verify(self, token, current_time=None):
        """ https://github.com/awslabs/aws-support-tools/blob/master/Cognito/decode-verify-jwt/decode-verify-jwt.py """
        if not token:
            raise TokenVerifyError("No token provided")

        headers = self._extract_headers(token)
        pkey_data = self._find_pkey(headers)
        self._verify_signature(token, pkey_data)

        claims = self._extract_claims(token)
        self._check_expiration(claims, current_time)
        self._check_audience(claims)

        self.claims = claims 
        return claims
```

In the ```backend-flask/app.py``` file
Update CORS
```
cors = CORS(
  app, 
  resources={r"/api/*": {"origins": origins}},
  headers=['Content-Type', 'Authorization'], 
  expose_headers='Authorization',
  methods="OPTIONS,GET,HEAD,POST"
)
```
Import
```
# Coginto JWT ------
import sys
from lib.cognito_jwt_token import CognitoJwtToken, extract_access_token, TokenVerifyError
```

```
# Coginto JWT ------
cognito_jwt_token = CognitoJwtToken(
  user_pool_id=os.getenv("AWS_COGNITO_USER_POOL_ID"), 
  user_pool_client_id=os.getenv("AWS_COGNITO_USER_POOL_CLIENT_ID"),
  region=os.getenv("AWS_DEFAULT_REGION")
)
```

In the home page add
```
     access_token = extract_access_token(request.headers)
  try:
    claims = cognito_jwt_token.verify(access_token)
    # authenicatied request
    app.logger.debug("authenicated")
    app.logger.debug(claims)
    app.logger.debug(claims['username'])
    data = HomeActivities.run(cognito_user_id=claims['username'])
  except TokenVerifyError as e:
    # unauthenicatied request
    app.logger.debug(e)
    app.logger.debug("unauthenicated")
    data = HomeActivities.run()
```
To the ```backend-flask.services/home_activities.py``` enter
```
def run(cognito_user_id=None):
```
```
      if cognito_user_id != None:
        extra_crud = {
          'uuid': '302f6979-983e-451c-9a6e-5de4edecf971',
          'handle':  'mom',
          'message': 'I hate cooking, lol',
          'created_at': (now - timedelta(hours=1)).isoformat(),
          'expires_at': (now + timedelta(hours=12)).isoformat(),
          'likes': 1042,
          'replies': []
        }
        results.insert(0,extra_crud)
```

![jwt](https://user-images.githubusercontent.com/102387885/224462576-463e9ec2-917c-44d6-ae38-dbddc3defa1f.png)

### Cloud Career Homework
![CareerHW](https://user-images.githubusercontent.com/102387885/224465613-c5a13b5f-0e20-40a0-bb56-9000e70a2aed.png)

### Files in the codebase
[Integrate Cognito](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/commit/ec825e265917b33759cef5c7d28767dac849ce22)

[Signinpage commit](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/commit/00e577a2e597347dc5ca3ff2ac2eb655a1def4f5)

[Signup and Confirmation page commit](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/commit/f46167c8b85e5e8f6a953785fa9719da966d8d64)

[Recover and Signup page commit](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/commit/7b70a7d3802e37aa5e8ab0c20ae80d4b223992b3)

[cognito_jwt_token.py](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/blob/week3/backend-flask/lib/cognito_jwt_token.py)

[JWT Commit](https://github.com/Sksanth/aws-bootcamp-cruddur-2023-/commit/965d917dc7d9e8961ae588d86a8ba8a9c7157839)

