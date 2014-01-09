crypto = require 'crypto'

Connect = (client, key, opts) ->
  throw new Error('DNT Connect client not defined') if not client
  throw new Error('DNT Connect key not defined') if not key

  @client = client
  @key = new Buffer key, 'base64'

  @

Connect.prototype.encrypt = (plaintext) ->
  cipher = crypto.createCipheriv 'aes-256-ecb', @key, ''
  cipher.update(plaintext, 'utf8', 'base64') + cipher.final('base64')

Connect.prototype.decrypt = (ciphertext) ->
  cipher = crypto.createDecipheriv 'aes-256-ecb', @key, ''
  cipher.update(ciphertext, 'base64', 'utf8') + cipher.final('utf8')

Connect.prototype.decryptJSON = (uriEncodedCiphertext) ->
  return JSON.parse @decrypt decodeURIComponent uriEncodedCiphertext

Connect.prototype.encryptJSON = (json) ->
  return encodeURIComponent @encrypt JSON.stringify json

Connect.prototype.getPayload = (redirectUrl) ->
    redirect_url: redirectUrl
    timestamp: Math.floor(new Date().getTime() / 1000)

Connect.prototype.getUrl = (type, redirectUrl) ->
  [
    'https://www.turistforeningen.no/connect/'
    type
    '/?client='
    @client
    '&data='
    @encryptJSON @getPayload redirectUrl
  ].join('')

Connect.prototype.bounce = (redirectUrl) ->
  @getUrl 'bounce', redirectUrl

Connect.prototype.signon = (redirectUrl) ->
  @getUrl 'signon', redirectUrl

module.exports = Connect

