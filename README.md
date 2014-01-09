DNT Connect ![Build Status](https://drone.io/github.com/Turistforeningen/node-dnt-connect/status.png)
===========

Node.JS library for DNT's single sign on service DNT Connect

## Install

```
npm install dnt-connect --save
```

## Usage

### New Client

```javascript
var Connect = require('dnt-connect');

var client = new Connect('myClientName', 'mySecretKey');
```

### Bounce

Bounce is used to check if a user is currently authenticated with DNT Connect.
The bounce url will bounce the user automaticly back to the provided
`redirect_url` with user data if the user is authenticated.

```javascript
var url = client.bounce('http://mysite.com/auth')
```

### Signon

Signon is used to require a user to sign in with their DNT Connect user or
register a new user. The user credentials will be sent to the `redirect_url`
when the users is sucessfully authenticated.

```javascript
var url = client.signon('http://mysite.com/auth')
```

### Decrypt Response Data

All data sent and recieved is encrypted. In order to read the data you need to
call `#decrypt()` wich will use your key to decrypt the data.

```javascript
var data = client.decryptJSON(encryptedData);
```

