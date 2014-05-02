DNT Connect ![Build Status](https://drone.io/github.com/Turistforeningen/node-dnt-connect/status.png)
===========

Node.JS library for DNT's single sign on service DNT Connect

## Requirements

Require Node.JS version `>= 0.10`.

## Install

```
npm install dnt-connect --save
```

## Usage

```javascript
var Connect = require('dnt-connect');
```

### New Client

```javascript
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
call `#decryptJSON()` wich will use your key and the provided HMAC hash to
decrypt the data.

```javascript
var data = client.decryptJSON(encryptedData, hmac);
```

## The MIT License (MIT)

Copyright (c) 2014 Turistforeningen

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
