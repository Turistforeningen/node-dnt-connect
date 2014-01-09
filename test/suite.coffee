Connect = require '../src/dnt-connect.coffee'
assert = require 'assert'

c = null

describe 'new Connect()', ->
  it 'should throw error for missing client string', ->
    assert.throws(
      -> new Connect()
    , /DNT Connect client not defined/)

  it 'should throw error for missing key string', ->
    assert.throws(
      -> new Connect('myApp')
    , /DNT Connect key not defined/)

  it 'should make new client instance', ->
    c = new Connect('myApp', 'dfadfe1242fdsffdg33q43sdfgdasfadsfsfdasdfwd')
    assert c instanceof Connect
    assert c.key instanceof Buffer
    assert.equal c.client, 'myApp'

describe '#encrypt()', ->
  it 'should encrypt string plaintext', ->
    assert.equal c.encrypt('this is a test'), 'IjA1ChOTDZjWxRwU/DBZTw=='

describe '#decrypt()', ->
  it 'should decrypt ciphertext', ->
    assert.equal c.decrypt('IjA1ChOTDZjWxRwU/DBZTw=='), 'this is a test'

describe '#decryptJSON()', ->
  it 'should return decrypt JSON data', ->
    json =
      foo: 'bar'
      bar: 'foo'

    encrypted = encodeURIComponent c.encrypt JSON.stringify json
    assert.deepEqual c.decryptJSON(encrypted), json

describe '#encryptJSON()', ->
  it 'should return encrypted JSON data', ->
    json =
      foo: 'bar'
      bar: 'foo'

    assert.deepEqual c.decryptJSON(c.encryptJSON(json)), json

describe '#getPayload()', ->
  it 'should return JSON payload', ->
    url = 'http://myapp.com/login'
    data = c.getPayload url

    assert.equal Object.keys(data).length, 2
    assert.equal data.redirect_url, url
    assert.equal typeof data.timestamp, 'number'

describe '#getUrl()', ->
  url = 'http://myapp.com/login'

  it 'should return valid bounce url', ->
    assert /http:\/\/www.turistforeningen.no\/connect\/bounce\/\?client=myApp&data=/.test c.getUrl('bounce', url)

  it 'should return valid signon url', ->
    assert /http:\/\/www.turistforeningen.no\/connect\/signon\/\?client=myApp&data=/.test c.getUrl('signon', url)

describe '#bounce()', ->
  it 'should return valid bounce url', ->
    url = c.bounce('http://myapp.com/login')
    assert /http:\/\/www.turistforeningen.no\/connect\/bounce\/\?client=myApp&data=/.test url

describe '#signon()', ->
  it 'should return valid signon url', ->
    url = c.signon('http://myapp.com/login')
    assert /http:\/\/www.turistforeningen.no\/connect\/signon\/\?client=myApp&data=/.test url

