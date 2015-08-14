var inactivityTimeout = require('../../server/inactivityTimeout');
inactivityTimeout.timeout = 5000;

var app = require('../../server/app');
var httpism = require('httpism');
var toughCookie = require('tough-cookie');
var users = require('../../server/users');
var expect = require('chai').expect;
var wait = require('../../browser/wait');

describe('inactivity', function () {
  var server;
  var port = 12345;
  var cookies;

  var client;
  var cookies;

  beforeEach(function () {
    server = app.listen(port);
    cookies = new toughCookie.CookieJar();
    client = httpism.api('http://localhost:' + port, {cookies: cookies});
    return users.deleteAll()
  });

  afterEach(function () {
    server.close();
  });

  it('logs the user out after a short period of time', function () {
    this.timeout(100000);

    function repeatedlyGetDocuments(n) {
      return client.get('/api/user/documents').then(function (documents) {
        expect(documents.body).to.eql([]);
        if (n >= 0) {
          return wait(3000).then(function () {
            return repeatedlyGetDocuments(n - 1);
          });
        }
      });
    }

    return client.post('/signup', {email: 'author@example.com', password: 'password1'}, {form: true}).then(function (response) {
      return repeatedlyGetDocuments(4).then(function () {
        return wait(7000).then(function() {
          return client.get('/api/user/documents', {exceptions: false}).then(function (documents) {
            expect(documents.statusCode).to.equal(401);
          });
        });
      });
    });
  });
});
