Connect = require '../src/dnt-connect.coffee'
assert = require 'assert'
gs = require 'querystring'

iv = pt = ct = hs = ivct = c = null

beforeEach ->
  iv = new Buffer('FDVC0Adh8UEFaeVXwUNHEw==', 'base64')
  pt = JSON.stringify
    "order_id": 104,
    "total_price": 103.45,
    "products" : [
      {
        "id": "123",
        "name": "Product #1",
        "price": 12.95
      },
      {
        "id": "137",
        "name": "Product #2",
        "price": 82.95
      }
    ]
  hs = [
    'd72bOEwOpR0bJ6I1aq8KbfDMh0/ZO6RCaG669QjuXXzs2Gef/tzc+IqcsFBBWSzNmujiBQc8H'
    'JG8+pZj4DaJ0A=='
  ].join('')
  ct = [
    '2akbLLpz4+x/g3ZOLnCh8i8TU3ZBeqU1xHdIOIh6tNxyha8DF9LBl2j3QcwQ3bhG2Ms6D1scB'
    'x84uBgDjCdEZJmzkfNTsZQLMFC1akX4ja+p7UJcjgIAoVRO61evPjfRtUMFK89ZNjcglUiITs'
    'ZGfXBd0cz5P1aC8qIZ86XFE1ec5RyKPmCYPW8qrmwlRPivTIfyYFPcx6ZvZf8KFJMgKg=='
  ].join('')
  ivct = Buffer.concat([iv, new Buffer(ct, 'base64')]).toString('base64')

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

describe '#hmacPlaintext()', ->
  it 'should return HMAC for plaintext and iv', ->
    assert.equal c.hmacPlaintext(pt, iv), hs

describe '#verifyPlaintext()', ->
  it 'should return true for correct hmac', ->
    assert.equal c.verifyPlaintext(pt, iv, hs), true

  it 'should return false for incorrect hmac', ->
    hs = [
      'AKMvNyM6MKg8BFfWtLWSDrPRHmIZzfU8DOo/np3SQC9RXVj4JqpfpYz6nXzoUEa5Hp//a12'
      'sOmsAzdc+3S/Lug=='
    ].join('')
    assert.equal c.verifyPlaintext(pt, iv, hs), false

  it 'should return false for incorrect iv', ->
    iv = new Buffer('ADVC0Adh8UEFaeVXwUNHEw==', 'base64')
    assert.equal c.verifyPlaintext(pt, iv, hs), false

  it 'should return false for incorrect plaintext', ->
    pt = JSON.stringify foo: 'baz'
    assert.equal c.verifyPlaintext(pt, iv, hs), false

describe '#encryptPlaintext()', ->
  it 'ciphertext length should be multiple of 16', ->
    assert.equal new Buffer(c.encryptPlaintext(pt, iv), 'base64').length % 16, 0

  it 'should return ciphertext, prepended iv, for plaintext and iv input', ->
    assert.equal c.encryptPlaintext(pt, iv), ivct

describe '#decryptCiphertext()', ->
  it 'should return plaintext for ciphertext and iv input', ->
    assert.equal c.decryptCiphertext(new Buffer(ct, 'base64'), iv), pt

describe '#encryptAndHash()', ->
  it 'should return ciphertext, prepended iv, and hmac for plaintext and iv', ->
    [ciphertext, hmac] = c.encryptAndHash pt, iv

    assert.equal hmac, hs
    assert.equal ciphertext, ivct

describe '#decryptAndVerify()', ->
  it 'should return plaintext and validation for ciphertext and hmac', ->
    [plaintext, valid] = c.decryptAndVerify ivct, hs

    assert.equal valid, true
    assert.equal plaintext, pt

describe '#encryptJSON()', ->
  it 'should return encrypted JSON data and verification hmac', ->
    [ciphertext, hmac] = c.encryptJSON JSON.parse(pt), iv

    assert.equal ciphertext, encodeURIComponent ivct
    assert.equal hmac, encodeURIComponent hs

describe '#decryptJSON()', ->
  it 'should return decrypted JSON data and verify hmac', ->
    data = encodeURIComponent ivct
    hmac = encodeURIComponent hs

    [json, valid] = c.decryptJSON data, hmac

    assert.equal valid, true
    assert.deepEqual json, JSON.parse(pt)

describe '#getUrl()', ->
  url = null
  beforeEach -> url = 'http://myapp.com/login'

  it 'should return valid url with encrypted data and hmac', ->
    [url, params] = c.getUrl('bounce', url).split '?', 2

    params = gs.parse params

    assert.equal url, 'https://www.dnt.no/connect/bounce/'
    assert.equal params.client, 'myApp'
    assert.equal typeof params.data, 'string'
    assert.equal typeof params.hmac, 'string'

    [json, valid] = c.decryptJSON params.data, params.hmac

    assert.equal valid, true
    assert.equal json.redirect_url, 'http://myapp.com/login'
    assert.equal typeof json.timestamp, 'number'

describe '#bounce()', ->
  it 'should return valid bounce url', ->
    [url, params] = c.bounce(url).split '?', 2

    params = gs.parse params

    assert.equal url, 'https://www.dnt.no/connect/bounce/'
    assert.equal params.client, 'myApp'
    assert.equal typeof params.data, 'string'
    assert.equal typeof params.hmac, 'string'

describe '#signon()', ->
  it 'should return valid signon url', ->
    [url, params] = c.signon(url).split '?', 2

    params = gs.parse params

    assert.equal url, 'https://www.dnt.no/connect/signon/'
    assert.equal params.client, 'myApp'
    assert.equal typeof params.data, 'string'
    assert.equal typeof params.hmac, 'string'

describe '#decrypt()', ->
  it 'should handle missing query parameter', ->
    assert.throws ->
      c.decrypt()
    , /Param query.data is not defined/

  it 'should handle missing data property', ->
    assert.throws ->
      c.decrypt {}
    , /Param query.data is not defined/

  it 'should handle missing hmac property', ->
    assert.throws ->
      c.decrypt data: ivct
    , /Param query.hmac is not defiend/

  it 'should decrypt valid ciphertext and hmac', ->
    [json, valid] = c.decrypt
      data: encodeURIComponent(ivct)
      hmac: encodeURIComponent(hs)

    assert.equal valid, true
    assert.deepEqual json, JSON.parse(pt)
