var cache = require('../common/cache');
var nodemailer = require('nodemailer');
var urlUtils = require('url');
var promisify = require('./promisify');
var debug = require('debug')('lexenotes:sendemail');
var nodemailerDebug = require('debug')('nodemailer:smtp');
var emailTemplates = require('./emailTemplates');

var connectionCache = cache();
var connections = [];

function parseSmtpUrl(url) {
  var parsedUrl = urlUtils.parse(url);

  var connection = {
    port: parseInt(parsedUrl.port) || 25,
    host: parsedUrl.hostname,
    debug: nodemailerDebug.enabled
  }

  if (parsedUrl.auth) {
    var auth = parsedUrl.auth.split(':');
    connection.auth = {
      user: auth[0],
      pass: auth[1]
    };
  }

  return connection;
}

function connection(url) {
  return connectionCache.cacheBy(url, function () {
    var c = nodemailer.createTransport(parseSmtpUrl(url));
    c.on('log', nodemailerDebug);
    connections.push(c);
    return c;
  });
}

function sendEmail(url, email) {
  return promisify(function (cb) {
    debug('sending email', url, email);
    connection(url).sendMail(email, cb);
  });
}

module.exports = function (url, email) {
  if (typeof url == 'object') {
    var options = url;

    return emailTemplates.buildEmail(options.template, options.email, options.data).then(function (email) {
      return sendEmail(options.smtp, email);
    });
  } else {
    return sendEmail(url, email);
  }
};

module.exports.closeAll = function () {
  return Promise.all(connections.map(function (c) {
    return promisify(function (cb) {
      c.close(cb);
    });
  }));
};
