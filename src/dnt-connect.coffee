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
Connect.prototype.hmacPlaintext = (plaintext, iv) ->
  hmac = crypto.createHmac 'sha512', @key
  hmac.update Buffer.concat [iv, new Buffer(plaintext, 'utf8')]
  hmac.digest 'base64'

###
#
###
Connect.prototype.verifyPlaintext = (plaintext, iv, hmac) ->
  @hmacPlaintext(plaintext, iv) is hmac

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
# Encrypt plaintext and hmac it
#
# @param <String> plaintext - plaintext to encipher
# @param <Buffer> iv - initialization vector
#
# @return <Array> with <String> ciphertext and <String> hmac
#
###
Connect.prototype.encryptAndHash = (plaintext, iv) ->
  [@encryptPlaintext(plaintext, iv), @hmacPlaintext(plaintext, iv)]

###
#
# Decrypt ciphertext and verify hmac
#
# @param <String> ciphertext - ciphertext to decipher
# @param <String> hmac - hmac of plaintext and iv
#
# @return <Array> with <String> plaintext and <Boolean> verification
#
###
Connect.prototype.decryptAndVerify = (ciphertext, hmac) ->
  ciphertext = new Buffer ciphertext, 'base64'
  iv = ciphertext.slice(0, 16)
  pt = @decryptCiphertext(ciphertext.slice(16), iv)
  [pt, @verifyPlaintext(pt, iv, hmac)]

###
#
# Decrypt encrypted data from DNT Connect
#
# @param <String> data - encrypted data
# @param <String> hmac - hmaced data verification
#
# @return <Array> with <Object> decrypted data and <Boolean> verification
#
###
Connect.prototype.decryptJSON = (data, hmac) ->
  data = decodeURIComponent data
  hmac = decodeURIComponent hmac

  [json, valid] = @decryptAndVerify data, hmac

  # @TODO(starefossen) check json.timestamp to prevent reply attacks (60 sec)

  [JSON.parse(json), valid]

###
#
# Encrypt JSON and return ciphertext and hmac
#
# @param <Object> json - json data to encrypt
# @param <Buffer> iv - initialization vector
#
# @return <Array> with <String> ciphertext and <String> hmac
#
###
Connect.prototype.encryptJSON = (json, iv) ->
  [cipher, hmac] = @encryptAndHash JSON.stringify(json), iv
  [encodeURIComponent(cipher), encodeURIComponent(hmac)]

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
  [data, hmac] = @encryptJSON
    redirect_url: redirectUrl
    timestamp: Math.floor(new Date().getTime() / 1000)
  , iv = crypto.randomBytes 16

  "#{CONNECT_URL}/#{type}/?" + stringify
    client: @client
    data: data
    hmac: hmac

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

