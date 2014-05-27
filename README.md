DNT Connect [![Build Status](https://drone.io/github.com/Turistforeningen/node-dnt-connect/status.png)](https://drone.io/github.com/Turistforeningen/node-dnt-connect)
===========

Node.JS library for DNT's single sign on service – DNT Connect. This README
explains the technical implemetation of using DNT Connect in your Node
application. For detaials on data returned through the API and various response
codes see [this
document](https://turistforeningen.atlassian.net/wiki/display/dnt/DNT+connect).
Please contact opensource@turistforneingen.no if you are interested in using DNT
Connect for your application in order to get an API key.

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

### Decrypt Response

All data sent and recieved to and from DNT Connect is encrypted by 256 bit AES
cipher in CBC mode.  In order to read recieved data from DNT Connect your
application needs to call `#decrypt()` wich will use your privat DNT Connect API
key to decrypt and verify the data.

`NB` The return from the #decrypt() method is an `Array` with two elements in
it; `data` and `valid`.  The reason for this is because of [Destructing
assignments](https://developer.mozilla.org/en-US/docs/Web/JavaScript/New_in_JavaScript/1.7#Destructuring_assignment_(Merge_into_own_page.2Fsection)),
new in ECMAScript 6.

```javascript
try {
  var data = client.decrypt({data: queryData, hmac: queryHmac});
  if (data[1] === false) {
    console.log('Validation failed');
  } else {
    console.log('Decrypted data');
    console.log(data[0]);
  }
} catch (e) {
  // Decryption or serialization failed
}
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

