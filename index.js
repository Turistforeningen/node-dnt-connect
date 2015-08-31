'use strict';

const crypto = require('crypto');
const CONNECT_URL = 'https://www.dnt.no/connect';

/*
 *
 * Create DNT Connect client
 *
 * @param <string-utf8> client - DNT Connect client name
 * @param <string-base64> key - DNT Connect API key
 * @param <object> opts - options
 *
 * @return <Connect> class instance
 *
 */

const C = function Connect(client, key) {
  if (!client) {
    throw new Error('DNT Connect client not defined');
  }

  if (!key) {
    throw new Error('DNT Connect key not defined');
  }

  this.client = client;
  this.key = new Buffer(key, 'base64');

  return this;
};


/*
 *
 * Generate hmac of plaintext and iv
 *
 * @param <string-utf8> plaintext - plaintext to encipher
 * @param <Buffer> iv - initialization vector
 *
 * @return <string-base64> of hmac
 *
 */

C.prototype.hmacPlaintext = function hmacPlaintext(plaintext, iv) {
  const hmac = crypto.createHmac('sha512', this.key);
  hmac.update(Buffer.concat([iv, new Buffer(plaintext, 'utf8')]));
  return hmac.digest('base64');
};


/*
 *
 * Verify hmac of plaintext is correct
 *
 * @param <string-utf8> plaintext - plaintext to encipher
 * @param <Buffer> iv - initialization vector
 * @param <string-base64> hmac - hmac of plaintext
 *
 * @return {@code true} if hmac is valid; otherwise {@code false}
 *
 */

C.prototype.verifyPlaintext = function verifyPlaintext(plaintext, iv, hmac) {
  return this.hmacPlaintext(plaintext, iv) === hmac;
};


/*
 *
 * Encipher plaintext and prepend iv
 *
 * @param <string-utf8> plaintext - plaintext to encipher
 * @param <Buffer> iv - initialization vector
 *
 * @return <string-base64> of the iv prepended to the ciphertext
 *
 */

C.prototype.encryptPlaintext = function encryptPlaintext(plaintext, iv) {
  const cipher = crypto.createCipheriv('aes-256-cbc', this.key, iv);
  const buffers = [iv, cipher.update(plaintext, 'utf8'), cipher.final()];
  return Buffer.concat(buffers).toString('base64');
};


/*
 *
 * Decipher ciphertext
 *
 * @param <Buffer> ciphertext - ciphertext to decipher
 * @param <Buffer> iv - initialization vector
 *
 * @return <string-utf8> with plaintext
 *
 */

C.prototype.decryptCiphertext = function decryptCiphertext(ciphertext, iv) {
  const cipher = crypto.createDecipheriv('aes-256-cbc', this.key, iv);
  return cipher.update(ciphertext, '', 'utf8') + cipher.final('utf8');
};


/*
 *
 * Encrypt plaintext and hmac it
 *
 * @param <string-utf8> plaintext - plaintext to encipher
 * @param <Buffer> iv - initialization vector
 *
 * @return <Array> with <string-base64> ciphertext and <string-base64> hmac
 *
 */

C.prototype.encryptAndHash = function encryptAndHash(plaintext, iv) {
  return [this.encryptPlaintext(plaintext, iv), this.hmacPlaintext(plaintext, iv)];
};


/*
 *
 * Decrypt ciphertext and verify hmac
 *
 * @param <string-base64> ciphertext - ciphertext to decipher
 * @param <string-base64> hmac - hmac of plaintext and iv
 *
 * @return <Array> with <string-utf8> plaintext and <boolean> verification
 *
 */

C.prototype.decryptAndVerify = function decryptAndVerify(ciphertext, hmac) {
  const buffer = new Buffer(ciphertext, 'base64');
  const iv = buffer.slice(0, 16);
  const pt = this.decryptCiphertext(buffer.slice(16), iv);
  return [pt, this.verifyPlaintext(pt, iv, hmac)];
};


/*
 *
 * Decrypt encrypted data from DNT Connect
 *
 * @param <string-base64> data - encrypted data
 * @param <string-base64> hmac - hmaced data verification
 *
 * @return <Array> with <object> decrypted data and <boolean> verification
 *
 */

C.prototype.decryptJSON = function decryptJSON(data, hmac) {
  const ref = this.decryptAndVerify(
      decodeURIComponent(data),
      decodeURIComponent(hmac)
  );
  const json = JSON.parse(ref[0]);
  const valid = ref[1];

  return [json, valid];
};


/*
 *
 * Encrypt JSON and return ciphertext and hmac
 *
 * @param <object> json - json data to encrypt
 * @param <Buffer> iv - initialization vector
 *
 * @return <Array> with <string-base64> ciphertext and <string-base64> hmac
 *
 */

C.prototype.encryptJSON = function encryptJSON(json, iv) {
  const ref = this.encryptAndHash(JSON.stringify(json), iv);
  const cipher = encodeURIComponent(ref[0]);
  const hmac = encodeURIComponent(ref[1]);

  return [cipher, hmac];
};


/*
 *
 * Get DNT Connect url for service type
 *
 * @param <string-utf8> type - authentication type
 * @param <string-utf8> redirectUrl - url to redirect user back to
 *
 * @return <string-utf8> url to DNT Connect
 *
 */

C.prototype.getUrl = function getUrl(type, redirectUrl) {
  const ref = this.encryptJSON({
    redirect_url: redirectUrl,
    timestamp: Math.floor(new Date().getTime() / 1000),
  }, crypto.randomBytes(16));

  const data = ref[0];
  const hmac = ref[1];

  return `${CONNECT_URL}/${type}/?client=${this.client}&data=${data}&hmac=${hmac}`;
};


/*
 *
 * Bounce user to DNT Connect to check authentication
 *
 * @param <string-utf8> redirectUrl - url to redirect user back to
 *
 * @return <string-utf8> url to DNT Connect
 *
 */

C.prototype.bounce = function bounce(redirectUrl) {
  return this.getUrl('bounce', redirectUrl);
};


/*
 *
 * Make user sign on using DNT Connect
 *
 * @param <string-utf8> redirectUrl - url to redirect user back to
 *
 * @return <string-utf8> url to DNT Connect
 *
 */

C.prototype.signon = function signon(redirectUrl) {
  return this.getUrl('signon', redirectUrl);
};


/*
 *
 * Decrypt DNT Connect data
 *
 * @param <object> query - query parameters from DNT Connect
 *
 * @return <Array> with <object> decrypted data and <boolean> verification
 *
 */

C.prototype.decrypt = function decrypt(query) {
  if ((query ? query.data : undefined) === undefined) {
    throw new Error('Param query.data is not defined');
  }

  if ((query ? query.hmac : undefined) === undefined) {
    throw new Error('Param query.hmac is not defiend');
  }

  return this.decryptJSON(query.data, query.hmac);
};

/*
 *
 * Express.js compatible middleare
 *
 * @param <string-utf8> type - "signon" or "bounce"
 *
 * @return <function> Express.js compatible middleare function
 *
 */

C.prototype.middleware = function middleare(type) {
  const that = this;

  return function dntConnectMiddleware(req, res, next) {
    if (req && req.query && req.query.data) {
      try {
        const data = that.decrypt(req.query);

        if (data[1] === false) {
          req.dntConnect = {
            err: new ('DNT Connect: HMAC verification failed'),
            data: null,
          };
        } else {
          req.dntConnect = {
            err: null,
            data: data[0],
          };
        }
      } catch (e) {
        req.dntConnect = {
          err: e,
          data: null,
        };
      }

      next();
    } else {
      const redirectUrl = `${req.protocol}://${req.get('host')}${req.originalUrl}`;
      res.redirect(that[type](redirectUrl));
    }
  };
};

module.exports = C;
