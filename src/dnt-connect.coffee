crypto = require 'crypto'
stringify = require('querystring').stringify

CONNECT_URL = 'https://www.turistforeningen.no/connect'

###
#
###
Connect = (client, key, opts) ->
  throw new Error('DNT Connect client not defined') if not client
  throw new Error('DNT Connect key not defined') if not key

  @client = client
  @key = new Buffer key, 'base64'

  @

###
#
###
Connect.prototype.hashPlaintext = (plaintext, iv) ->
  hmac = crypto.createHmac 'sha512', @key
  hmac.update Buffer.concat [iv, new Buffer(plaintext, 'utf8')]
  hmac.digest 'base64'

###
#
###
Connect.prototype.verifyPlaintext = (plaintext, iv, hash) ->
  @hashPlaintext(plaintext, iv) is hash

###
#
# Encipher plaintext and prepend iv
#
# @param <String> plaintext - plaintext to encipher
# @param <Buffer> iv - initialization vector
#
# @return base64 encoded <String> of the iv prepended to the ciphertext
#
###
Connect.prototype.encryptPlaintext = (plaintext, iv) ->
  cipher = crypto.createCipheriv 'aes-256-cbc', @key, iv
  buffers = [iv, cipher.update(plaintext, 'utf8'), cipher.final()]
  Buffer.concat(buffers).toString('base64')

###
#
# Decipher ciphertext
#
# @param <Buffer> ciphertext - ciphertext to decipher
# @param <Buffer> iv - initialization vector
#
# @return utf-8 encoded <String> with plaintext
#
###
Connect.prototype.decryptCiphertext = (ciphertext, iv) ->
  cipher = crypto.createDecipheriv 'aes-256-cbc', @key, iv
  cipher.update(ciphertext, '', 'utf8') + cipher.final('utf8')

###
#
# Encrypt plaintext and hash it
#
# @param <String> plaintext - plaintext to encipher
# @param <Buffer> iv - initialization vector
#
# @return <Array> with <String> ciphertext and <String> hash
#
###
Connect.prototype.encryptAndHash = (plaintext, iv) ->
  [@encryptPlaintext(plaintext, iv), @hashPlaintext(plaintext, iv)]

###
#
# Decrypt ciphertext and verify hash
#
# @param <String> ciphertext - ciphertext to decipher
# @param <String> hash - hash of plaintext and iv
#
# @return <Array> with <String> plaintext and <Boolean> verification
#
###
Connect.prototype.decryptAndVerify = (ciphertext, hash) ->
  ciphertext = new Buffer ciphertext, 'base64'
  iv = ciphertext.slice(0, 16)
  pt = @decryptCiphertext(ciphertext.slice(16), iv)
  [pt, @verifyPlaintext(pt, iv, hash)]

###
#
# Decrypt encrypted data from DNT Connect
#
# @param <String> data - encrypted data
# @param <String> hash - hashed data verification
#
# @return <Array> with <Object> decrypted data and <Boolean> verification
#
###
Connect.prototype.decryptJSON = (data, hash) ->
  data = decodeURIComponent data
  hash = decodeURIComponent hash

  [json, valid] = @decryptAndVerify data, hash

  # @TODO(starefossen) check json.timestamp to prevent reply attacks (60 sec)

  [JSON.parse(json), valid]

###
#
# Encrypt JSON and return ciphertext and hash
#
# @param <Object> json - json data to encrypt
# @param <Buffer> iv - initialization vector
#
# @return <Array> with <String> ciphertext and <String> hash
#
###
Connect.prototype.encryptJSON = (json, iv) ->
  [cipher, hash] = @encryptAndHash JSON.stringify(json), iv
  [encodeURIComponent(cipher), encodeURIComponent(hash)]

###
#
# Get DNT Connect url for service type
#
# @param <String> type - authentication type
# @param <String> redirectUrl - url to redirect user back to
#
# @return <String> url to DNT Connect
#
###
Connect.prototype.getUrl = (type, redirectUrl) ->
  [data, hash] = @encryptJSON
    redirect_url: redirectUrl
    timestamp: Math.floor(new Date().getTime() / 1000)
  , iv = crypto.randomBytes 16

  "#{CONNECT_URL}/#{type}/?" + stringify
    client: @client
    data: data
    hmac: hash

###
#
# Bounce user to DNT Connect to check authentication
#
# @param <String> redirectUrl - url to redirect user back to
#
# @return <String> url to DNT Connect
#
###
Connect.prototype.bounce = (redirectUrl) ->
  @getUrl 'bounce', redirectUrl

###
#
# Make user sign on using DNT Connect
#
# @param <String> redirectUrl - url to redirect user back to
#
# @return <String> url to DNT Connect
#
###
Connect.prototype.signon = (redirectUrl) ->
  @getUrl 'signon', redirectUrl

module.exports = Connect

