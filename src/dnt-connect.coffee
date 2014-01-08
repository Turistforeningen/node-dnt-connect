crypto = require 'crypto'

Connect = (client, key, opts) ->
  throw new Error('DNT Connect client not defined') if not client
  throw new Error('DNT Connect key not defined') if not key

  @client = client
  @key = new Buffer key, 'base64'
  @blockSize = opts?.blockSize or 16

  @

Connect.prototype.pkcs7pad = (string) ->
  l = string.length
  n = (@blockSize - (l % @blockSize))

  buff = new Buffer(l + n)
  buff.fill(0x0)
  buff.write(string, 0, l, 'utf8')
  buff.writeUInt8 '0x' + (n).toString(16), i for i in [l..l+n-1]
  buff

Connect.prototype.encrypt = (plaintext) ->
  cipher = crypto.createCipheriv 'aes-256-ecb', @key, ''
  cipher.setAutoPadding false
  cipher.update(@pkcs7pad(plaintext), undefined, 'base64') + cipher.final('base64')

Connect.prototype.decrypt = (ciphertext) ->
  throw new Error('DNT Connect #decrypt() not implemented')

Connect.prototype.bounce = (redirectUrl) ->
  @getUrl 'bounce', redirectUrl

Connect.prototype.signon = (redirectUrl) ->
  @getUrl 'signon', redirectUrl

Connect.prototype.getUrl = (type, redirectUrl) ->
  [
    'http://www.turistforeningen.no/connect/'
    type
    '/?client='
    @client
    '&data='
    encodeURIComponent @encrypt @getUrlData redirectUrl
  ].join('')

Connect.prototype.getUrlData = (redirectUrl) ->
  JSON.stringify
    redirect_url: redirectUrl
    timestamp: Math.floor(new Date().getTime() / 1000)

module.exports = Connect

