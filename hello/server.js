'use strict';

const express = require('express');

// Constants
const PORT = 8080;
const HOST = '0.0.0.0';

var os = require("os");
var hostname = os.hostname();

// App
const app = express();
app.get('/', (req, res) => {
  res.send(`Hello world *PROD* v3.6 from server: ${hostname}`);
});

app.listen(PORT, HOST);
console.log(`Running on http://${HOST}:${PORT}`);
