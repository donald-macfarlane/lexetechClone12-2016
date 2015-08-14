process.env.BASEURL = 'https://localhost:12346/';

var app = require('../../server/app');
var https = require('https');
var fs = require('fs');
var httpism = require('httpism');
var expect = require('chai').expect;
var urlUtils = require('url');

describe('redirect', function () {
  var http = httpism.api(
    {
      headers: {'X-Forwarded-Proto': 'http'},
      https: {rejectUnauthorized: false, agent: false}
    },
    [proxyHeaders]
  )

  var httpServer, httpsServer;

  beforeEach(function () {
    var options = {
      key: fs.readFileSync(__dirname + '/lexenotes.com.key'),
      cert: fs.readFileSync(__dirname + '/lexenotes.com.cert')
    };

    httpsServer = https.createServer(options, app).listen(12346);
    httpServer = app.listen(12345);
  });

  afterEach(function () {
    httpServer.close();
    httpsServer.close();
  });

  function proxyHeaders(request, next) {
    var url = urlUtils.parse(request.url);
    request.headers['X-Forwarded-Proto'] = url.protocol.replace(':', '');
    return next();
  }

  it('redirects onto HTTPS', function () {
    return http.get('http://localhost:12345').then(function (response) {
      expect(response.url).to.equal('https://localhost:12346/');
    });
  });

  it('redirects onto HTTPS with path intact', function () {
    return http.get('http://localhost:12345/login?blah=haha').then(function (response) {
      expect(response.url).to.equal('https://localhost:12346/login?blah=haha');
    });
  });

  it('redirects onto correct domain from anything else', function () {
    return http.get('https://127.0.0.1:12346/login?blah=haha').then(function (response) {
      expect(response.url).to.equal('https://localhost:12346/login?blah=haha');
    });
  });
});
