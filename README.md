node-dnt-connect
================

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

```javascript
var url = client.bounce('http://mysite.com/login')
```

### Signon

```javascript
var url = client.signon('http://mysite.com/login')
```

### Decrypt Response Data

```javascript
var data = client.decrypt(encryptedData);
```

