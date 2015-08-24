/* eslint no-console: 0 */
'use strict';

const express = require('express');
const bodyParser = require('body-parser');

const Connect = require('../index');
const connect = new Connect(
  process.env.DNT_CONNECT_CLIENT,
  process.env.DNT_CONNECT_KEY
);

const app = module.exports = express();

app.use(bodyParser.json());

app.get('/connect', connect.middleware('signon'), function getAuth(req, res) {
  if (req.dntConnect.err) {
    res.status(500).json({error: err.message});
  } else {
    res.status(200).json({data: req.dntConnect.data});
  }
});

if (!module.parent) {
  app.listen(4000);
  console.log('Server is listening on port 4000');
}
