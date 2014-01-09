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

describe 'getUrlData', ->
  it 'should return stringified payload data', ->
    url = 'http://myapp.com/login'
    data = JSON.parse(c.getUrlData url)

    assert.equal Object.keys(data).length, 2
    assert.equal data.redirect_url, url
    assert.equal typeof data.timestamp, 'number'

describe.skip '#decrypt()', ->
  it 'not implemented'

describe '#encrypt()', ->
  it 'should encrypt string plaintext', ->
    assert.equal c.encrypt('this is a test'), 'IjA1ChOTDZjWxRwU/DBZTw=='

describe.skip '#getUrl()', ->
  it 'not implemented'

describe '#bounce()', ->
  it 'should generate bounce url', ->
    url = c.bounce('http://myapp.com/login')
    assert /http:\/\/www.turistforeningen.no\/connect\/bounce\/\?client=myApp&data=/.test url

describe '#signon()', ->
  it 'should generate signon url', ->
    url = c.signon('http://myapp.com/login')
    assert /http:\/\/www.turistforeningen.no\/connect\/signon\/\?client=myApp&data=/.test url

