'use strict';

const Connect = require('./index');
const assert = require('assert');
const gs = require('querystring');

let c;
let ct;
let hs;
let iv;
let ivct;
let pt;

beforeEach(function beforeEach() {
  iv = new Buffer('FDVC0Adh8UEFaeVXwUNHEw==', 'base64');
  pt = JSON.stringify({
    order_id: 104,
    total_price: 103.45,
    products: [
      {
        id: '123',
        name: 'Product #1',
        price: 12.95,
      }, {
        id: '137',
        name: 'Product #2',
        price: 82.95,
      },
    ],
  });

  hs = [
    'd72bOEwOpR0bJ6I1aq8KbfDMh0/ZO6RCaG669QjuXXzs2Gef/tzc+',
    'IqcsFBBWSzNmujiBQc8HJG8+pZj4DaJ0A==',
  ].join('');

  ct = [
    '2akbLLpz4+x/g3ZOLnCh8i8TU3ZBeqU1xHdIOIh6tNxyha8DF9LBl',
    '2j3QcwQ3bhG2Ms6D1scBx84uBgDjCdEZJmzkfNTsZQLMFC1akX4ja',
    '+p7UJcjgIAoVRO61evPjfRtUMFK89ZNjcglUiITsZGfXBd0cz5P1a',
    'C8qIZ86XFE1ec5RyKPmCYPW8qrmwlRPivTIfyYFPcx6ZvZf8KFJMgKg==',
  ].join('');

  ivct = Buffer.concat([iv, new Buffer(ct, 'base64')]).toString('base64');
});

describe('new Connect()', function describe() {
  it('should throw error for missing client string', function it() {
    assert.throws(function throws() {
      c = new Connect();
    }, /DNT Connect client not defined/);
  });

  it('should throw error for missing key string', function it() {
    assert.throws(function throws() {
      c = new Connect('myApp');
    }, /DNT Connect key not defined/);
  });

  it('should make new client instance', function it() {
    c = new Connect('myApp', 'dfadfe1242fdsffdg33q43sdfgdasfadsfsfdasdfwd');
    assert(c instanceof Connect);
    assert(c.key instanceof Buffer);
    assert.equal(c.client, 'myApp');
  });
});

describe('#hmacPlaintext()', function describe() {
  it('should return HMAC for plaintext and iv', function it() {
    assert.equal(c.hmacPlaintext(pt, iv), hs);
  });
});

describe('#verifyPlaintext()', function describe() {
  it('should return true for correct hmac', function it() {
    assert.equal(c.verifyPlaintext(pt, iv, hs), true);
  });

  it('should return false for incorrect hmac', function it() {
    hs = ['AKMvNyM6MKg8BFfWtLWSDrPRHmIZzfU8DOo/np3SQC9RXVj4JqpfpYz6nXzoUEa5Hp//a12', 'sOmsAzdc+3S/Lug=='].join('');
    assert.equal(c.verifyPlaintext(pt, iv, hs), false);
  });
  it('should return false for incorrect iv', function it() {
    iv = new Buffer('ADVC0Adh8UEFaeVXwUNHEw==', 'base64');
    assert.equal(c.verifyPlaintext(pt, iv, hs), false);
  });

  it('should return false for incorrect plaintext', function it() {
    pt = JSON.stringify({
      foo: 'baz',
    });
    assert.equal(c.verifyPlaintext(pt, iv, hs), false);
  });
});

describe('#encryptPlaintext()', function describe() {
  it('ciphertext length should be multiple of 16', function it() {
    assert.equal(new Buffer(c.encryptPlaintext(pt, iv), 'base64').length % 16, 0);
  });
  it('should return ciphertext, prepended iv, for plaintext and iv input', function it() {
    assert.equal(c.encryptPlaintext(pt, iv), ivct);
  });
});

describe('#decryptCiphertext()', function describe() {
  it('should return plaintext for ciphertext and iv input', function it() {
    assert.equal(c.decryptCiphertext(new Buffer(ct, 'base64'), iv), pt);
  });
});

describe('#encryptAndHash()', function describe() {
  it('should return ciphertext, prepended iv, and hmac for plaintext and iv', function it() {
    const ref = c.encryptAndHash(pt, iv);
    const ciphertext = ref[0];
    const hmac = ref[1];

    assert.equal(hmac, hs);
    assert.equal(ciphertext, ivct);
  });
});

describe('#decryptAndVerify()', function describe() {
  it('should return plaintext and validation for ciphertext and hmac', function it() {
    const ref = c.decryptAndVerify(ivct, hs);
    const plaintext = ref[0];
    const valid = ref[1];

    assert.equal(valid, true);
    assert.equal(plaintext, pt);
  });
});

describe('#encryptJSON()', function describe() {
  it('should return encrypted JSON data and verification hmac', function it() {
    const ref = c.encryptJSON(JSON.parse(pt), iv);
    const ciphertext = ref[0];
    const hmac = ref[1];

    assert.equal(ciphertext, encodeURIComponent(ivct));
    assert.equal(hmac, encodeURIComponent(hs));
  });
});

describe('#decryptJSON()', function describe() {
  it('should return decrypted JSON data and verify hmac', function it() {
    const data = encodeURIComponent(ivct);
    const hmac = encodeURIComponent(hs);

    const ref = c.decryptJSON(data, hmac);
    const json = ref[0];
    const valid = ref[1];

    assert.equal(valid, true);
    assert.deepEqual(json, JSON.parse(pt));
  });
});

describe('#getUrl()', function describe() {
  const _url = 'http://myapp.com/login';

  it('should return valid url with encrypted data and hmac', function it() {
    const ref = c.getUrl('bounce', _url).split('?', 2);
    const url = ref[0];
    const params = gs.parse(ref[1]);

    assert.equal(url, 'https://www.dnt.no/connect/bounce/');
    assert.equal(params.client, 'myApp');
    assert.equal(typeof params.data, 'string');
    assert.equal(typeof params.hmac, 'string');

    const ref1 = c.decryptJSON(params.data, params.hmac);
    const json = ref1[0];
    const valid = ref1[1];

    assert.equal(valid, true);
    assert.equal(json.redirect_url, 'http://myapp.com/login');
    assert.equal(typeof json.timestamp, 'number');
  });
});

describe('#bounce()', function describe() {
  const _url = 'http://myapp.com/login';

  it('should return valid bounce url', function it() {
    const ref = c.bounce(_url).split('?', 2);
    const url = ref[0];
    const params = gs.parse(ref[1]);

    assert.equal(url, 'https://www.dnt.no/connect/bounce/');
    assert.equal(params.client, 'myApp');
    assert.equal(typeof params.data, 'string');
    assert.equal(typeof params.hmac, 'string');
  });
});

describe('#signon()', function describe() {
  const _url = 'http://myapp.com/login';

  it('should return valid signon url', function it() {
    const ref = c.signon(_url).split('?', 2);
    const url = ref[0];
    const params = gs.parse(ref[1]);

    assert.equal(url, 'https://www.dnt.no/connect/signon/');
    assert.equal(params.client, 'myApp');
    assert.equal(typeof params.data, 'string');
    assert.equal(typeof params.hmac, 'string');
  });
});

describe('#decrypt()', function describe() {
  it('should handle missing query parameter', function it() {
    assert.throws(function throws() {
      c.decrypt();
    }, /Param query.data is not defined/);
  });

  it('should handle missing data property', function it() {
    assert.throws(function throws() {
      c.decrypt({});
    }, /Param query.data is not defined/);
  });

  it('should handle missing hmac property', function it() {
    assert.throws(function throws() {
      c.decrypt({
        data: ivct,
      });
    }, /Param query.hmac is not defiend/);
  });

  it('should decrypt valid ciphertext and hmac', function it() {
    const ref = c.decrypt({
      data: encodeURIComponent(ivct),
      hmac: encodeURIComponent(hs),
    });
    const json = ref[0];
    const valid = ref[1];

    assert.equal(valid, true);
    assert.deepEqual(json, JSON.parse(pt));
  });
});
