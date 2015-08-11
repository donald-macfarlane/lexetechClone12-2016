var inactivityTimeout = require('../../server/inactivityTimeout');
inactivityTimeout.timeout = 15000;

var app = require('../../server/app');
var httpism = require('httpism');
var toughCookie = require('tough-cookie');
var users = require('../../server/users');
var expect = require('chai').expect;

describe('inactivity', function () {
  var server;
  var port = 12345;
  var cookies;

  var client;

  beforeEach(function () {
    server = app.listen(port);
    client = httpism.api('http://localhost:' + port, {cookies: new toughCookie.CookieJar()});
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
          return wait(1000).then(function () {
            return repeatedlyGetDocuments(n - 1);
          });
        }
      });
    }

    return client.post('/signup', {email: 'author@example.com', password: 'password1'}, {form: true}).then(function (response) {
      return repeatedlyGetDocuments(30).then(function () {
        return wait(20000).then(function() {
          return client.get('/api/user/documents', {exceptions: false}).then(function (documents) {
            expect(documents.statusCode).to.equal(401);
          });
        });
      });
    });
  });
});

function wait(n) {
  return new Promise(function (fulfil) {
    setTimeout(fulfil, n);
  });
}
