var http = require('../../http');
var qs = require('qs');

function nocache(req, next) {
  var now = Date.now();

  if (!req.options.querystring) {
    req.options.querystring = {};
  }
  req.options.querystring['no-cache'] = now;

  return next();
}

module.exports = http.api([nocache]);
